UPDATE [NGProd].[dbo].[patient_status]
SET [patient_status].[patient_status_id] = 
(
SELECT [patient_status_mstr].[patient_status_id]
  FROM [NGProd].[dbo].[patient_status_mstr]
  WHERE [patient_status_mstr].[description] = 'Inactive'
)
FROM [NGProd].[dbo].[patient_status]
INNER JOIN (
SELECT [patient].[person_id]
  FROM [NGProd].[dbo].[person]
  INNER JOIN [NGProd].[dbo].[patient_status]
  ON [person].[person_id] = [patient_status].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_status_mstr]
  ON [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id]
  INNER JOIN [NGProd].[dbo].[patient]
  ON [patient_status].[person_id] = [patient].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_encounter]
  ON [patient].[person_id] = [patient_encounter].[person_id]
  WHERE [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id] 
  AND [patient_status_mstr].[description] = 'Active'
  EXCEPT
  SELECT  [patient].[person_id]
  FROM [NGProd].[dbo].[person]
  INNER JOIN [NGProd].[dbo].[patient_status]
  ON [person].[person_id] = [patient_status].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_status_mstr]
  ON [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id]
  INNER JOIN [NGProd].[dbo].[patient]
  ON [patient_status].[person_id] = [patient].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_encounter]
  ON [patient].[person_id] = [patient_encounter].[person_id]
  WHERE [patient_encounter].[enc_timestamp] > DATEADD(YEAR, -3, GETDATE())
  UNION
  SELECT [patient].[person_id]
  FROM [NGProd].[dbo].[person]
  INNER JOIN [NGProd].[dbo].[patient_status]
  ON [person].[person_id] = [patient_status].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_status_mstr]
  ON [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id]
  INNER JOIN [NGProd].[dbo].[patient]
  ON [patient_status].[person_id] = [patient].[person_id]
  INNER JOIN [NGProd].[dbo].[appointments]
  ON [patient].[person_id] = [appointments].[person_id]
  WHERE [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id] 
  AND [patient_status_mstr].[description] = 'Active'
  EXCEPT
  SELECT [patient].[person_id]
  FROM [NGProd].[dbo].[person]
  INNER JOIN [NGProd].[dbo].[patient_status]
  ON [person].[person_id] = [patient_status].[person_id]
  INNER JOIN [NGProd].[dbo].[patient_status_mstr]
  ON [patient_status].[patient_status_id] = [patient_status_mstr].[patient_status_id]
  INNER JOIN [NGProd].[dbo].[patient]
  ON [patient_status].[person_id] = [patient].[person_id]
  INNER JOIN [NGProd].[dbo].[appointments]
  ON [patient].[person_id] = [appointments].[person_id]  
  WHERE [appt_date] > DATEADD(YEAR, -3, GETDATE())) 
  AS results
ON [patient_status].[person_id] = results.[person_id]



