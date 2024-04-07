SET SERVEROUTPUT ON;
 
-- Seller adds product
VARIABLE category_id_ VARCHAR2(10);
exec BUSINESS_MANAGER.add_product(:category_id_, 'Scanner', 28.99, TO_DATE('21-02-23','DD-MM-YY'), NULL, 'Electronics', 'WHO');
 
-- Seller updates the status of the refund
exec BUSINESS_MANAGER.UPDATE_SELLER_REFUND(9005, 'Yes');