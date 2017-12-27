/***
* This script queries the database for cancelled/missed appointments that need to be rescheduled
*
* It then creates a task and sends it to the medical assistants, so they assess medical urgency and coordinate with scheduling staff
***/

-- Appointments are in table: dbo.appointments
-- EPM Tasks are in table: dbo.task_mstr
-- EHR Tasks are in table: dbo.user_todo_list



