/****** Script for Migrating Patients PCP and Default Rendering Provider  ******/

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
WHERE person.last_name = 'Mintzmyer'

/* This query finds all patients whose PCP is a certain provider A and reassigns
them to have a provider B as their PCP. It also sets an alert on their account
 that although their PCP is provider B, they have not yet seen their new PCP*/



