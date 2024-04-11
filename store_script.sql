SET SERVEROUTPUT ON;

-- Store updates their availability for the returns
exec BUSINESS_MANAGER.UPDATE_STORE_AVAILABILITY('ST002', 0); 

EXEC BUSINESS_MANAGER.Get_Feedback_For_Store(8007425877);

