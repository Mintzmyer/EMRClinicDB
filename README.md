# InactivateOldPatients
Deactivate patient accounts in EMR database absent for over 3 years

A nonprofit medical clinic policy stipulates patients who have not been seen in over 3 years are no longer active patients of the clinic. 

This script updates all patients to inactive if they have no Appointments in the last 3 years, or no Encounters in the last 3 years. It is scheduled to run monthly to prevent a backlog of old clients.
