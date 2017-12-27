/***
* This script creates a trigger in the appointments table of the database for cancelled/missed appointments that need to be rescheduled
* It then creates a task and sends it to the medical assistants, so they assess medical urgency and coordinate with scheduling staff
* Author: Samantha Feinstein
***/

-- Appointments are in table: dbo.appointments
    -- Cancelations in column: cancel_ind
    -- No-Shows are in column: appt_kept_ind
-- EPM Tasks are in table: dbo.task_mstr
-- EHR Tasks are in table: dbo.user_todo_list



/***
* Upon update of Appointments cancel_ind to 'Y' or appt_kept_ind to 'N'
* insert new clinical task with patient information
*
***/

-- 
