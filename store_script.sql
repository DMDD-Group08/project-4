SET SERVEROUTPUT ON;

-- Store updates their availability for the returns
-- params: store_contact_no, availability(0 for yes, 1 for no)
exec BUSINESS_MANAGER.UPDATE_STORE_AVAILABILITY(8007425877, 0); 

-- params: store_contact_no
EXEC BUSINESS_MANAGER.Get_Feedback_For_Store(8007425877);
