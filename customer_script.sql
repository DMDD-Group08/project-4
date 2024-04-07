SET SERVEROUTPUT ON;

-- Customer initiates return
VARIABLE last_return_id NUMBER;
exec BUSINESS_MANAGER.create_return('Not required', 2, 'ST001', 'OP0003', :last_return_id);

-- customer submits feedback t the store
VARIABLE last_feedback_id NUMBER;
exec BUSINESS_MANAGER.submit_feedback(:last_feedback_id, 'C003', 'ST003', 2.5, 'Bad staff');
