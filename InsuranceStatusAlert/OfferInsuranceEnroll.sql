/**** Script for setting Alerts on patient accounts without insurance ****/

/*  This script is scheduled as a job on the server to run regularly

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

--Set References
DECLARE @Insured
DECLARE @NotDoneYet

SET @Insured = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Insured' ) )

SET @NotDoneYet = ( SELECT mstr_list_item_id
	         FROM [NGProd].[dbo].mstr_lists
		 WHERE ( mstr_list_type = 'ud_demo1'
			AND mstr_list_item_desc = 'Not Done Yet' ) )



--Insert EPM Alert
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
	OUTER JOIN [NGProd].[dbo]
    WHERE ( ( [NGProd].[dbo].patient_.prim_insurance is NULL
        AND [NGProd].[dbo].patient_.sec_insurance is NULL )
        AND [NGProd].[dbo].person_ud.ud_demo1_id 



/*






*/




