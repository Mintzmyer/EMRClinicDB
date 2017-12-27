/***
* This script creates a trigger in the appointments table of the database for cancelled/missed appointments that need to be rescheduled
* It then creates a task and sends it to the medical assistants, so they assess medical urgency and coordinate with scheduling staff
* Author: Samantha Feinstein
***/

-- Appointments are in table: dbo.appointments
    -- Cancelations in column: cancel_ind
    -- No-Shows are in column: appt_kept_ind
-- The EPM Tasks are in table: dbo.task_mstr
-- The EHR Tasks are in table: dbo.user_todo_list

-- The workgroups are in table: dbo.task_workgroup_mstr
-- The user<->tasks xref table: dbo.todo_assign
-- The workgroups<->task table: dbo.group_assign


/***
* Upon update of Appointments cancel_ind to 'Y' or appt_kept_ind to 'N'
* insert new clinical task with patient information
*
***/
-- Identify update to Appointment: cancel_ind to 'Y' or appt_kept_ind to 'N'
-- Capture patient's person_id
-- Insert into user_todo_list
INSERT INTO [NGProd].[dbo].[user_todo_list] (
      [enterprise_id]
      ,[practice_id]
      ,[user_id]
      ,[task_id]
      ,[task_priority]
      ,[task_completed]
      ,[task_due_date]
      ,[task_subj]
      ,[task_desc]
      ,[task_assgn]
      ,[task_owner]
      ,[task_deleted]
      ,[pat_acct_id]
      ,[pat_enc_id]
      ,[pat_item_id]
      ,[pat_item_type]
      ,[pat_item_desc]
      ,[old_pat_item_id]
      ,[read_flag]
      ,[created_by]
      ,[create_timestamp]
      ,[modified_by]
      ,[modify_timestamp]
      ,[row_timestamp]
      ,[rejected_ind] 
      )
      SELECT [NGProd].[dbo].person.enterprise_id
            ,[NGProd].[dbo].person.practice_id
            ,'-99'
            ,NEWID()
            ,'2'
	    ,'0'
	    ,NULL
	    ,'MEANINGFUL SUBJECT'
	    ,'This description should be meaningful too'
	    ,NULL
	    ,NULL
	    ,'0'
	    ,NULL -- CONNECT PATIENT ACCOUNT
	    ,NULL
	    ,NULL
	    ,NULL
	    ,NULL
	    ,NULL
	    ,''
	    ,'-99'
	    ,CURRENT_TIMESTAMP
	    ,''
	    ,''
	    ,'0'
	    



