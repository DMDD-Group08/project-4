
SET SERVEROUTPUT ON;

-- Check returned requests that are accepted
EXEC BUSINESS_MANAGER.show_returns_request('charlie@gmail.com');

-- customer submits feedback
BEGIN
  BUSINESS_MANAGER.submit_feedback(
    p_store_phone => 8007425877,
    p_customer_email => 'charlie@gmail.com',
    p_customer_rating => 2,
    p_review => 'The store was bad, staff not helpful'
  );
END;
/