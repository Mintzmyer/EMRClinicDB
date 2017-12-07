# EMR Clinic DB Administration
This repo hosts a number of small SQL snippets for various projects while maintaining an EMR database for a medical clinic.

# - InactivateOldPatients
The clinic has a policy that any patient who has not been seen in over three years is automatically an inactive patient. They can re-activate their patient account at any time if they choose to continue care with us.

This script implements that policy. It searches for patients who have not had contact in over three years and sets their status to Inactive. This script is now a scheduled job in our server that runs monthly


# - NewHeadPhysician
The clinic has a new Head Physician, but a lot of our patient panel still lists the former Head Physician as their primary care provider and default rendering provider. 

This script migrates patients assigned to the former provider -> into the new provider. It also places an alert in their profile that this patient has not seen their PCP before.

# - RxTracking340B
The clinic must comply with 340B, which tracks prescribed medication. We are in the process of implementing with a new vendor, and some information was needed about our prescribed medication.

This script creates a report by month of all:
    - Medication
    - The provider who assigned it
    - The insurance the paid for it
    - The pharmacy that dispensed it

# - InsuranceStatusAlert
The clinic hopes to better utilize a department for enrolling patients in ACA/OHP, because our low-income demographic often experience barriers to enrolling.
As the project progressed, it became apparent that flagging Medicare and Medicaid patients is similarly useful, to better route them to our payor-specific providers

This script is a scheduled job that regularly:
    - Updates a client-defined status within the patient profile if they:
        1) have insurance
        2) declined/cannot obtain insurance
        3) been referred to get insurance
        4) or haven't been offered.
    - Sets an alert when opening the patient profile if they:
        1) have no insurance on file
        2) have Medicare
        3) have Medicaid
    - Maintains the above status and alert based on filed insurance



