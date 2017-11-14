/****** Script for selecting Patients PCP and Default Rendering Provider, and alerts  ******/

/* This query finds all patients whose last name is 'Test' and shows their PCP, default rendering provider, EPM alerts, and EHR alerts */
SELECT person.last_name
      ,person.primarycare_prov_id
      ,PCP.last_name AS PCP
      ,DefProv.last_name AS DefaultRendProv
      ,patient_alerts.subject AS EPMalert
      ,ehr_alerts_mstr.description AS EHRalert
FROM [NGProd].[dbo].person
INNER JOIN [NGProd].[dbo].patient
ON [person].person_id = patient.person_id
INNER JOIN [NGProd].[dbo].provider_mstr as PCP
ON [person].primarycare_prov_id = PCP.provider_id
INNER JOIN [NGProd].[dbo].provider_mstr AS DefProv
ON [patient].rendering_prov_id = DefProv.provider_id
INNER JOIN [NGProd].[dbo].patient_alerts
ON [person].person_id = [patient_alerts].source_id
INNER JOIN [NGProd].[dbo].patient_alerts_ehr
ON [person].person_id = [patient_alerts_ehr].person_id
INNER JOIN [NGProd].[dbo].ehr_alerts_mstr
ON [patient_alerts_ehr].message_id = [ehr_alerts_mstr].message_id
WHERE person.last_name = 'Test'


/* This query finds the patient whose 
    PCP is a certain provider P1 and whose 
    default rendering provider is a certain provider P2
    and whose last name is a given Lname
    
    And updates the patient's PCP and default rendering provider to P3
    and assigns alerts to the patient's account to appear in EPM and EHR */
/****** Script for updating a given patient's PCP and Default Rendering Provider, and adding EPM/EHR alerts  ******/

--Declare old and new providers to migrate from/to
DECLARE @OldProvider varchar(30) = 'Leigh'
DECLARE @NewProvider varchar(30) = 'Wendy'
DECLARE @PatientName varchar(30) = 'Test'


--Insert EHR Alert
INSERT INTO [NGProd].[dbo].patient_alerts_ehr (
    practice_id
   ,person_id
   ,source_type
   ,comment
   ,delete_ind
   ,flag_ind
   ,create_timestamp
   ,created_by 
   ,message_id
   ,disruptive_ind
   ,acknowledge_by
   ,user_description
   ,subtype_id
   )
   SELECT [NGProd].[dbo].person.practice_id
       ,[NGProd].[dbo].person.person_id
       ,[NGProd].[dbo].ehr_alerttypes_mstr.alerttype_id
       ,'New PCP Migration'
       ,'N'
       ,'Y'
       ,CURRENT_TIMESTAMP
       ,'-99'
       ,[NGProd].[dbo].[ehr_alerts_mstr].message_id
       ,'N'
       ,'P'
       ,NULL
       ,NULL
   FROM [NGProd].[dbo].person
       INNER JOIN [NGProd].[dbo].ehr_alerts_mstr
       ON person.practice_id = ehr_alerts_mstr.practice_id
       INNER JOIN [NGProd].[dbo].ehr_alerttypes_mstr
       ON ehr_alerts_mstr.alerttype_id = ehr_alerttypes_mstr.alerttype_id
       INNER JOIN [NGProd].[dbo].provider_mstr
       ON person.primarycare_prov_id = provider_mstr.provider_id
   WHERE provider_mstr.first_name = @OldProvider
       AND ehr_alerts_mstr.message_id = '7B2CB038-F19E-4B21-A202-5D0ADC3BFA54'
       AND person.last_name = @PatientName
       
    
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
        ,'New PCP - First Visit'
        ,'Auto PCP Migration, Never Seen Current PCP'
        ,'N'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,CURRENT_TIMESTAMP
        ,'-99'
        ,NULL
    FROM [NGProd].[dbo].person
        INNER JOIN [NGProd].[dbo].provider_mstr
        ON person.primarycare_prov_id = provider_mstr.provider_id
    WHERE [NGProd].[dbo].provider_mstr.first_name = @OldProvider
        AND person.last_name = @PatientName 


--Update PCP
UPDATE [NGProd].[dbo].person
    SET primarycare_prov_id = (
        SELECT provider_id
        FROM [NGProd].[dbo].provider_mstr
        WHERE [NGProd].[dbo].[provider_mstr].first_name = @NewProvider
        )
    WHERE [NGProd].[dbo].person.primarycare_prov_id = (
        SELECT provider_id
        FROM [NGProd].[dbo].provider_mstr
        WHERE [NGProd].[dbo].[provider_mstr].first_name = @OldProvider
        )
        AND person.last_name = @PatientName
        
--Update Default Rendering Provider
UPDATE [NGProd].[dbo].patient
    SET rendering_prov_id = (
        SELECT provider_id
        FROM [NGProd].[dbo].provider_mstr
        WHERE [NGProd].[dbo].[provider_mstr].first_name = @NewProvider
        )
    WHERE [NGProd].[dbo].patient.rendering_prov_id = (
        SELECT provider_id
        FROM [NGProd].[dbo].provider_mstr
        WHERE [NGProd].[dbo].[provider_mstr].first_name = @OldProvider
        )
        AND person_id = (
            SELECT person_id
            FROM [NGProd].[dbo].person
            WHERE [NGProd].[dbo].[person].last_name = @PatientName
            )

/* This query finds all patients whose PCP is a certain provider A and reassigns
them to have a provider B as their PCP. It also sets an alert on their account
 that although their PCP is provider B, they have not yet seen their new PCP*/



