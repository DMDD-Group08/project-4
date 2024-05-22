SET SERVEROUTPUT ON;

-------- customer views the products that can be returned based on his/her orders
EXEC BUSINESS_MANAGER.show_returns_request('alice@gmail.com');

-- customer views the rating of all stores before making a return
SELECT * FROM BUSINESS_MANAGER.store_average_rating_view;

-- Customer initiates return
--create_return(reason, quantity_returned, store_id, order_product_id)
VARIABLE Available_Qty NUMBER;
-- Seller : Apple 
exec BUSINESS_MANAGER.create_return(:Available_Qty, 'Wrong Size', 1, '2001', '5511');

