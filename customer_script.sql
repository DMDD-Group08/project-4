SET SERVEROUTPUT ON;

-- Customer initiates return
--create_return(reason, quantity_returned, store_id, order_product_id)
VARIABLE Available_Qty NUMBER;
exec BUSINESS_MANAGER.create_return(:Available_Qty, 'Damaged product', 1, '2001', '5508');

-- customer views returned products to the store to give feedback to the store

exec BUSINESS_MANAGER.get_returned_products('alice@gmail.com');

-- customer submits feedback
BEGIN
  BUSINESS_MANAGER.submit_feedback(
    p_store_phone => 8005551234,
    p_customer_email => 'bob@gmail.com',
    p_customer_rating => 2,
    p_review => 'The store was bad, staff not helpful'
  );
END;
/
