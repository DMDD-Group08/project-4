SET SERVEROUTPUT ON;

-- Seller adds product
VARIABLE category_id_ VARCHAR2(10);
VARIABLE category_if_exists NUMBER;
--add_product(category_id_, name, price, mfg_date, exp_date, category_name, seller_id)
exec BUSINESS_MANAGER.add_product(:category_id_, :category_if_exists, 'Scanner2', 28.99, TO_DATE('21-02-23','DD-MM-YY'), NULL, 'Electronics', '1001');
 
-- Seller updates the status of the refund
VARIABLE return_id_if_exists NUMBER;
VARIABLE seller_contact_if_exists NUMBER;
VARIABLE seller_return_combination_if_exists NUMBER;
--UPDATE_SELLER_REFUND(return_id_if_exists, seller_contact_if_exists, seller_return_combination_if_exists, return_id, accept_yes_no, seller_contact)
exec BUSINESS_MANAGER.UPDATE_SELLER_REFUND(:return_id_if_exists, :seller_contact_if_exists, :seller_return_combination_if_exists, '9011', 'NO', 8008066453);

