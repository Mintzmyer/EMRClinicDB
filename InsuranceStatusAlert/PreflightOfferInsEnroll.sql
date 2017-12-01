/**** Preflight script for setting Alerts on patient accounts without insurance ****/

/*  This script is run once to set up a new workflow

    Our non-profit has a program for enrolling folk in insurance, and this 
    program will prompt staff to encourage patients to utilize that resource
    
*/


-- patient_ table holds prim_insurance, sec_insurance columns
-- person_ud table holds client defined options
-- mstr_lists table holds list information: ud_demo1 is 'Insurance Enrollment Status'. For reference:
    -- Insured id = 6204564E...
    -- Not Done id = 19FE351A...
    -- Unins NI id = E4740E1F...
    -- Unins Ref id = 484D32A8...

--Set Reference Variables
DECLARE @Insured uniqueidentifier
DECLARE @NotDoneYet uniqueidentifier
DECLARE @Uninterested uniqueidentifier
DECLARE @Active uniqueidentifier

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

SET @Active = (SELECT [patient_status_mstr].[patient_status_id]
	      FROM [NGProd].[dbo].[patient_status_mstr]
	      WHERE [patient_status_mstr].[description] = 'Active'
	
-- Insert all patients with no Insurance Enrollment Status as 'Not Done Yet'
INSERT INTO [NGProd].[dbo].person_ud (
	

-- Set all insured patients to 'Insured' status
UPDATE person_ud
SET ud_demo1_id = @Insured
FROM [NGProd].[dbo].person
INNER JOIN person_ud
ON person.person_id = person_ud.person_id
INNER JOIN patient_
on person.person_id = patient_.person_id
WHERE ( patient_.prim_insurance is not NULL
     OR patient_.sec_insurance is not NULL )
     AND person_ud.ud_demo1_id != @Insured 

-- Set all uninsured patients to 'Not Done Yet' status
UPDATE person_ud
SET ud_demo1_id = @NotDoneYet
FROM [NGProd].[dbo].person
INNER JOIN person_ud
ON person.person_id = person_ud.person_id
INNER JOIN patient_
on person.person_id = patient_.person_id
WHERE ( patient_.prim_insurance is NULL
     AND patient_.sec_insurance is NULL )
     AND person_ud.ud_demo1_id != @NotDoneYet 

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
        ,'This patient does not have insurance'
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


