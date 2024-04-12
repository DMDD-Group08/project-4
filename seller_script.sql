SET SERVEROUTPUT ON;

-- Seller adds product
-- params: name, price, mfg_date, exp_date, category_name, seller_id
exec BUSINESS_MANAGER.add_product('Scanner2', 28.99, TO_DATE('21-02-23','DD-MM-YY'), NULL, 'Electronics', '8008066453');
 
-- Seller updates the status of the refund
--params: return_id, accept_yes_no, seller_contact
exec BUSINESS_MANAGER.UPDATE_SELLER_REFUND('9011', 'NO', 8008066453);

-- view return requests to be approved/rejected
-- params: seller_contact_no
EXEC BUSINESS_MANAGER.GET_SYSTEM_APPROVED_RETURNS(8008066453);

-- view the analysis of returned products
-- params: seller_contact_no
EXEC BUSINESS_MANAGER.GET_RETURNED_PRODUCT_ANALYSIS(8008066453);

-- view the catgories available
-- params: seller_contact_no
EXEC BUSINESS_MANAGER.VIEW_CATEGORIES_AVAILABLE(8008066453);