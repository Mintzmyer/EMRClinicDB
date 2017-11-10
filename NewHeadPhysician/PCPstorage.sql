/* SQLQuery to find PCP <-> Patient table
Oddly, PCP is not properly defined in the 'patient_' table with the rest of the patient data
Instead of using the provider_id, it has several VARCHAR() fields for the PCP name that must
be legacy because they are no longer updated by changing patient status */

SELECT COUNT(TABLE_NAME)
FROM [NGProd].[INFORMATION_SCHEMA].TABLES
--This returns 6754 tables in the database

SELECT COLUMN_NAME
      ,TABLE_NAME
FROM [NGProd].[INFORMATION_SCHEMA].COLUMNS
WHERE COLUMN_NAME LIKE 'provider_id'
ORDER BY TABLE_NAME, COLUMN_NAME
--This returns all tables with a provider_id that could be a PCP relational table for patients and providers
--It has 167 rows, much easier to look through

SELECT COLUMN_NAME
      ,TABLE_NAME
FROM [NGProd].[INFORMATION_SCHEMA].COLUMNS 
WHERE COLUMN_NAME LIKE '%prim%'
AND COLUMN_NAME LIKE '%c%'
AND COLUMN_NAME LIKE '%prov%'
ORDER BY TABLE_NAME, COLUMN_NAME
--This returns 56 rows, finally found its hiding place
