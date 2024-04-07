SET SERVEROUTPUT ON;

-- Customer initiates return
exec BUSINESS_MANAGER.create_return('Not required', 2, '2001', '5501');

-- customer submits feedback t the store
exec BUSINESS_MANAGER.submit_feedback('C003', 'ST003', 2.5, 'Bad staff');