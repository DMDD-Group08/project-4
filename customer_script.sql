SET SERVEROUTPUT ON;

-- Customer initiates return
--create_return(reason, quantity_returned, store_id, order_product_id)
VARIABLE Available_Qty NUMBER;
exec BUSINESS_MANAGER.create_return(:Available_Qty, 'Damaged product', 1, '2001', '5508');

-- customer submits feedback to the store
exec BUSINESS_MANAGER.submit_feedback('C003', 'ST003', 2.5, 'Bad staff');