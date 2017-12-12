/**** Script for setting Alerts on patient accounts without insurance, with Medicaid and with Medicare ****/

/*  This script is scheduled as a job on the server to run regularly

    Our non-profit has a program for enrolling folk in insurance, and this 
    program will prompt staff to encourage patients to utilize that resource

    We also have payor-specific providers, so flagging Medicare and Medicaid
    patients will help us funnel them to the right place
    
*/

        /***    SET REFERENCE VARIABLES     ***/

DECLARE @AlertUninsuredSubj varchar(50)
DECLARE @AlertUninsuredDesc varchar(50)

DECLARE @AlertMedicaidSubj varchar(50)
DECLARE @AlertMedicaidDesc varchar(50)

DECLARE @AlertMedicareSubj varchar(50)
DECLARE @AlertMedicareDesc varchar(50)

SET @AlertUninsuredSubj = 'SHOP - Enroll in Insurance'
SET @AlertUninsuredDesc = 'This patient does not have insurance.'

SET @AlertMedicaidSubj = 'Medicaid - Insurance Alert'
SET @AlertMedicaidDesc = 'This patient has Medicaid insurance.'

SET @AlertMedicareSubj = 'Medicare - Insurance Alert'
SET @AlertMedicareDesc = 'This patient has Medicare insurance.'


DECLARE @Insured uniqueidentifier
DECLARE @NotDoneYet uniqueidentifier
DECLARE @Uninterested uniqueidentifier
DECLARE @Referred uniqueidentifier

SET @Insured = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Insured' ) )

SET @NotDoneYet = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Not Done Yet' ) )

SET @Uninterested = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Uninsured - Not Interested' ) )

SET @Referred = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Uninsured - Referred To SHOP' ) )


-- Add Medicare/Medicaid payors to the list as needed:
DECLARE @TrilliumMedicare     uniqueidentifier
DECLARE @MedicareB            uniqueidentifier
DECLARE @TrilliumMedicaid     uniqueidentifier
DECLARE @DMAP                 uniqueidentifier

DECLARE @Medicare TABLE (payor varchar(200))
DECLARE @Medicaid TABLE (payor varchar(200))

SET @TrilliumMedicare = ( SELECT payer_id
	                  FROM [NGProd].[dbo].payer_mstr
			  WHERE payer_name = 'Trillium Medicare' )

SET @MedicareB = ( SELECT payer_id
	                  FROM [NGProd].[dbo].payer_mstr
			  WHERE payer_name = 'Medicare B' )

SET @TrilliumMedicaid = ( SELECT payer_id
	                  FROM [NGProd].[dbo].payer_mstr
			  WHERE payer_name = 'Trillium Medicaid' )

SET @DMAP = ( SELECT payer_id
	                  FROM [NGProd].[dbo].payer_mstr
			  WHERE payer_name = 'DMAP' )

INSERT INTO @Medicare (payor) VALUES (@TrilliumMedicare), (@MedicareB)
INSERT INTO @Medicaid (payor) VALUES (@TrilliumMedicaid), (@DMAP)


        /****    STATUS UPDATES    ****/

-- Set all insured patients to 'Insured' status
UPDATE person_ud
SET ud_demo1_id = @Insured
FROM [NGProd].[dbo].person_ud
INNER JOIN ( SELECT patient_.person_id FROM patient_
	     INTERSECT
	     SELECT person_payer.person_id FROM person_payer )
AS insured ON person_ud.person_id = insured.person_id
WHERE person_ud.ud_demo1_id != @Insured


-- Set all uninsured patients to 'Not Done Yet' status 
-- Only if they are Insured or NULL
    -- Not if they are already Not Done Yet, Uninterested or already referred to shop
UPDATE person_ud
SET ud_demo1_id = @NotDoneYet
FROM [NGProd].[dbo].person_ud
INNER JOIN ( SELECT patient_.person_id FROM patient_
             EXCEPT
             SELECT person_payer.person_id FROM person_payer ) 
AS uninsured ON person_ud.person_id = uninsured.person_id
WHERE (    person_ud.ud_demo1_id != @NotDoneYet
	OR person_ud.ud_demo1_id != @Uninterested
	OR person_ud.ud_demo1_id != @Referred )


        /****    ALERT UPDATES    ****/

	/**    REMOVE EXPIRED ALERT    **/

-- Remove Uninsured EPM alert if patient has insurance and (undeleted) alert
-- Update 'delete_ind' to Y
UPDATE patient_alerts
SET delete_ind = 'Y'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN ( SELECT patient_.person_id FROM patient_
	     INTERSECT
	     SELECT person_payer.person_id FROM person_payer )
AS insured ON patient_alerts.source_id = insured.person_id
WHERE (patient_alerts.subject = @AlertUninsuredSubj
     AND patient_alerts.delete_ind = 'N')

-- Remove Medicaid EPM alert if patient has lost Medicaid insurance and (undeleted) alert
UPDATE patient_alerts
SET delete_ind = 'Y'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN person on patient_alerts.source_id = person.person_id
INNER JOIN ( SELECT patient_.person_id FROM patient_
	     INTERSECT
	     SELECT person_payer.person_id FROM person_payer )
AS insured ON patient_alerts.source_id = insured.person_id
INNER JOIN ( SELECT person_payer.person_id FROM person_payer
             EXCEPT
             SELECT person_payer.person_id FROM person_payer
             WHERE person_payer.payer_id IN (SELECT payor FROM @Medicaid) )
AS noMedicaid ON patient_alerts.source_id = noMedicaid.person_id
WHERE ( patient_alerts.subject = @AlertMedicaidSubj
       AND patient_alerts.delete_ind = 'N')

-- Remove Medicare EPM alert if patient has no Medicare insurance and (undeleted) alert
UPDATE patient_alerts
SET delete_ind = 'Y'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN patient_
ON patient_.person_id = patient_alerts.source_id
WHERE ( ( patient_.prim_insurance NOT IN (SELECT payor FROM @Medicare)
       AND patient_.sec_insurance NOT IN (SELECT payor FROM @Medicare) )
     AND ( patient_alerts.subject = @AlertMedicareSubj
       AND patient_alerts.delete_ind = 'N') )

        /**    REACTIVATE OLD ALERTS    **/

-- Reactivate Uninsured EPM alert if patient has lost insurance and has deleted alert
-- Update 'delete_ind' to N
UPDATE patient_alerts
SET delete_ind = 'N'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN patient_
ON patient_.person_id = patient_alerts.source_id
WHERE ( patient_.prim_insurance is NULL
     AND patient_.sec_insurance is NULL )
     AND (patient_alerts.subject = @AlertUninsuredSubj
     AND patient_alerts.delete_ind = 'Y')

-- Reactivate Medicaid EPM alert if patient regains Medicaid and has deleted alert
UPDATE patient_alerts
SET delete_ind = 'N'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN patient_
ON patient_.person_id = patient_alerts.source_id
WHERE ( ( patient_.prim_insurance IN (SELECT payor FROM @Medicaid)
       OR patient_.sec_insurance IN (SELECT payor FROM @Medicaid) )
     AND ( patient_alerts.subject = @AlertMedicaidSubj
       AND patient_alerts.delete_ind = 'Y') )

-- Reactivate Medicare EPM alert if patient regains Medicare and has deleted alert
UPDATE patient_alerts
SET delete_ind = 'N'
FROM [NGProd].[dbo].patient_alerts
INNER JOIN patient_
ON patient_.person_id = patient_alerts.source_id
WHERE ( ( patient_.prim_insurance IN (SELECT payor FROM @Medicare)
       OR patient_.sec_insurance IN (SELECT payor FROM @Medicare) )
     AND ( patient_alerts.subject = @AlertMedicareSubj
       AND patient_alerts.delete_ind = 'Y') )
        /**    INSERT NEW ALERTS    **/

-- Insert Uninsured EPM Alert 
-- Only if they don't already have one
INSERT INTO [NGProd].[dbo].patient_alerts (
    practice_id
    ,alert_id
    ,source_id
    ,source_type
    ,subject
    ,description
    ,delete_ind
    ,create_timestamp
    ,created_by
    ,modify_timestamp
    ,modified_by
    ,link_id
    )
    SELECT [NGProd].[dbo].person.practice_id
        ,NEWID()
        ,[NGProd].[dbo].person.person_id
        ,'C'
        ,@AlertUninsuredSubj
        ,@AlertUninsuredDesc
        ,'N'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,NULL
    FROM [NGProd].[dbo].person
        INNER JOIN [NGProd].[dbo].patient_
	ON person.person_id = patient_.person_id
	INNER JOIN (
	    SELECT patient_.person_id
	    FROM patient_
	    EXCEPT
	    SELECT patient_.person_id
	    FROM patient_ INNER JOIN patient_alerts 
	    ON patient_.person_id = patient_alerts.source_id
	    WHERE patient_alerts.subject = @AlertUninsuredSubj)
	    AS results
	ON person.person_id = results.person_id
    WHERE  ( [NGProd].[dbo].patient_.prim_insurance is NULL
        AND [NGProd].[dbo].patient_.sec_insurance is NULL )
        ORDER BY person.last_name


-- Insert Medicaid EPM Alert only if they don't already have one
INSERT INTO [NGProd].[dbo].patient_alerts (
    practice_id
    ,alert_id
    ,source_id
    ,source_type
    ,subject
    ,description
    ,delete_ind
    ,create_timestamp
    ,created_by
    ,modify_timestamp
    ,modified_by
    ,link_id
    )
    SELECT [NGProd].[dbo].person.practice_id
        ,NEWID()
        ,[NGProd].[dbo].person.person_id
        ,'C'
        ,@AlertMedicaidSubj
        ,@AlertMedicaidDesc
        ,'N'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,NULL
    FROM [NGProd].[dbo].person
        INNER JOIN [NGProd].[dbo].patient_
	ON person.person_id = patient_.person_id
	INNER JOIN (
	    SELECT patient_.person_id
	    FROM patient_
	    EXCEPT
	    SELECT patient_.person_id
	    FROM patient_ INNER JOIN patient_alerts 
	    ON patient_.person_id = patient_alerts.source_id
	    WHERE patient_alerts.subject = @AlertMedicaidSubj)
	    AS results
	ON person.person_id = results.person_id
    WHERE 
    ( [NGProd].[dbo].patient_.prim_insurance IN (SELECT payor FROM @Medicaid)
	OR [NGProd].[dbo].patient_.sec_insurance IN (SELECT payor FROM @Medicaid) )

-- Insert Medicare EPM Alert only if they don't already have one
INSERT INTO [NGProd].[dbo].patient_alerts (
    practice_id
    ,alert_id
    ,source_id
    ,source_type
    ,subject
    ,description
    ,delete_ind
    ,create_timestamp
    ,created_by
    ,modify_timestamp
    ,modified_by
    ,link_id
    )
    SELECT [NGProd].[dbo].person.practice_id
        ,NEWID()
        ,[NGProd].[dbo].person.person_id
        ,'C'
        ,@AlertMedicareSubj
        ,@AlertMedicareDesc
        ,'N'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,NULL
    FROM [NGProd].[dbo].person
        INNER JOIN [NGProd].[dbo].patient_
	ON person.person_id = patient_.person_id
	INNER JOIN (
	    SELECT patient_.person_id
	    FROM patient_
	    EXCEPT
	    SELECT patient_.person_id
	    FROM patient_ INNER JOIN patient_alerts 
	    ON patient_.person_id = patient_alerts.source_id
	    WHERE patient_alerts.subject = @AlertMedicareSubj)
	    AS results
	ON person.person_id = results.person_id
    WHERE 
    ( [NGProd].[dbo].patient_.prim_insurance IN (SELECT payor FROM @Medicare)
	OR [NGProd].[dbo].patient_.sec_insurance IN (SELECT payor FROM @Medicare) )
