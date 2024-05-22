SET SERVEROUTPUT ON;

-- Seller uses this view for most returned product
SELECT * FROM RETURNED_PRODUCTS_DETAILS;

-- view the catgories available
-- params: seller_contact_no
EXEC BUSINESS_MANAGER.VIEW_CATEGORIES_AVAILABLE(8008066453);

-- Seller adds product
-- params: name, price, mfg_date, exp_date, category_name, seller_id
exec BUSINESS_MANAGER.add_product('Scanner2', 28.99, TO_DATE('21-02-23','DD-MM-YY'), NULL, 'Electronics', '8008066453');
