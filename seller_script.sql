SET SERVEROUTPUT ON;
 
-- Seller adds product
VARIABLE last_product_id NUMBER;
VARIABLE category_id_ VARCHAR2(10);
exec BUSINESS_MANAGER.add_product(:last_product_id, :category_id_, 'Scanner', 28.99, TO_DATE('21-02-23','DD-MM-YY'), NULL, 'Electronics', 'WHO');
 
-- Seller updates the status of the refund
exec BUSINESS_MANAGER.UPDATE_SELLER_REFUND('RET002', 0);