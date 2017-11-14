/*** Script for generating monthly Rx report ***/

/* This report collects an approximation of the clinic's prescriptions:
    - Medication Name
    - Provider Name
    - Insurance Name
    - Pharmacy Name

    *** Insurance and Pharmacy may not be accurate:
    This script pulls the insurance and pharmacy the patient profile lists
    not the insurance or pharmacy used for that specific prescription, 
    so a particular past medication is not specifically filled at or paid by
    the current insurance and pharmacy  */

DECLARE @Month Integer = 20170800
SELECT patient_medication.medication_name
      ,provider_mstr.last_name
      ,provider_mstr.first_name
      ,person_payer.payer_name
      ,patient_.pharm_1
      ,start_date
    FROM [NGProd].[dbo].patient_medication
    INNER JOIN [NGProd].[dbo].provider_mstr
        ON patient_medication.provider_id = provider_mstr.provider_id
    INNER JOIN [NGProd].[dbo].person_payer
        ON patient_medication.person_id = person_payer.person_id
    INNER JOIN [NGProd].[dbo].patient_
        ON patient_medication.person_id = patient_.person_id
WHERE start_date < @Month+100
    AND start_date > @Month
    ORDER BY start_date


