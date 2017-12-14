/**** Preflight script for setting Alerts on patient accounts without insurance ****/

/*  This script is run once to set up a new workflow

    Our non-profit has a program for enrolling folk in insurance, and this 
    program will prompt staff to encourage patients to utilize that resource
    
*/


-- person_payer table holds insurance
-- person_ud table holds client defined options
-- mstr_lists table holds list information: ud_demo1 is 'Insurance Enrollment Status'. For reference:
    -- Insured id = 6204564E...
    -- Not Done id = 19FE351A...
    -- Unins NI id = E4740E1F...
    -- Unins Ref id = 484D32A8...

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
INNER JOIN ( SELECT patient_.person_id FROM NGProd.dbo.patient_
	     INTERSECT
	     SELECT person_payer.person_id FROM NGProd.dbo.person_payer )
AS insured ON person_ud.person_id = insured.person_id
WHERE person_ud.ud_demo1_id != @Insured


-- Set all uninsured patients to 'Not Done Yet' status 
-- Only if they are Insured or NULL
    -- Not if they are already Not Done Yet, Uninterested or already referred to shop
UPDATE person_ud
SET ud_demo1_id = @NotDoneYet
FROM [NGProd].[dbo].person_ud
INNER JOIN ( SELECT patient_.person_id FROM NGProd.dbo.patient_
             EXCEPT
             SELECT person_payer.person_id FROM NGProd.dbo.person_payer ) 
AS uninsured ON person_ud.person_id = uninsured.person_id
WHERE (    person_ud.ud_demo1_id != @NotDoneYet
	OR person_ud.ud_demo1_id != @Uninterested
	OR person_ud.ud_demo1_id != @Referred )


--Insert Uninsured EPM Alert
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
        ,'SHOP - Enroll in Insurance'
        ,'This patient does not have insurance.'
        ,'N'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,NULL
    FROM [NGProd].[dbo].person
        INNER JOIN [NGProd].[dbo].patient_
	ON person.person_id = patient_.person_id
        INNER JOIN [NGProd].[dbo].person_ud
	ON person_ud.person_id = person.person_id
    WHERE ( ( [NGProd].[dbo].patient_.prim_insurance is NULL
        AND [NGProd].[dbo].patient_.sec_insurance is NULL )
        AND ( [NGProd].[dbo].person_ud.ud_demo1_id != @Uninterested ) )

