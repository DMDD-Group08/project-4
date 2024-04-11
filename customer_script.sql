SET SERVEROUTPUT ON;

-- Customer initiates return
VARIABLE last_return_id NUMBER;
exec BUSINESS_MANAGER.create_return('Not required', 2, 'ST001', 'OP0003', :last_return_id);

-- customer views returned products to the store to give feedback
exec BUSINESS_MANAGER.get_returned_products('alice@gmail.com');

-- customer submits feedback the the store
BEGIN
  BUSINESS_MANAGER.submit_feedback(
    p_store_phone => 8005551234,
    p_customer_email => 'bob@gmail.com',
    p_customer_rating => 2,
    p_review => 'The store was bad, staff not helpful'
  );
END;
/
