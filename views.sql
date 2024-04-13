


-- Customer Reliability Index 
-- 1. We first calculate the total number of orders for each customer and the total number of returned orders for each customer using subqueries.
-- 2. We then left join these subqueries with the customer table to get the Customer_Name, Customer_ID, total_orders, and returned_orders.
-- 3. We calculate the reliability index as a percentage by subtracting the percentage of returned orders from 100. If total_orders is zero (to handle division by zero), we assume 100% reliability.
-- 4. This query provides the customer's name, ID, and reliability index as a percentage.

-- Business Manager view
CREATE OR REPLACE VIEW Customer_Reliability_Index AS
SELECT 
    c.name AS Customer_Name,
    c.id AS Customer_ID,
 ROUND(
        CASE 
            WHEN total_orders = 0 THEN 100  -- Handle division by zero
            ELSE ROUND((1 - (returned_orders / total_orders)) * 5,0)  -- Calculate reliability index on a scale og 1-5
        END,
        2  -- Round to two decimal places
    ) AS Reliability_Index
FROM 
    customer c
LEFT JOIN 
    (
        SELECT 
            o.customer_id,
            COUNT(*) AS total_orders
        FROM 
            "CUSTOMER_ORDER" o
        JOIN 
            "ORDER_PRODUCT" op ON o.id = op.customer_order_id
        GROUP BY 
            o.customer_id
    ) total ON c.id = total.customer_id
LEFT JOIN 
    (
        SELECT 
            o.customer_id,
            COUNT(*) AS returned_orders
        FROM 
            "RETURN" r
        JOIN 
            "ORDER_PRODUCT" op ON r.order_product_id = op.id
        JOIN 
            "CUSTOMER_ORDER" o ON op.customer_order_id = o.id
        GROUP BY 
            o.customer_id
    ) returned ON c.id = returned.customer_id;    


-- Delivery Date of the order : 
-- Business Manager view

CREATE OR REPLACE VIEW Order_Delivery_Date AS
SELECT 
    o.id AS Order_ID,
    o.customer_id AS Customer_ID,  -- Include the customer ID
    op.product_id AS Product_ID,
    p.name AS Product_Name,
    CASE 
        WHEN c.name = 'Food/Beverages' THEN o.order_date + INTERVAL '2' DAY
        WHEN c.name = 'Electronics' THEN o.order_date + INTERVAL '2' DAY
        WHEN c.name = 'Clothing/Apparel' THEN o.order_date + INTERVAL '2' DAY
        ELSE NULL
    END AS Delivery_Date
FROM 
    CUSTOMER_ORDER o
JOIN 
    order_product op ON o.id = op.customer_order_id
JOIN 
    product p ON op.product_id = p.id
JOIN 
    category c ON p.category_id = c.id
JOIN 
    customer cu ON o.customer_id = cu.id; 

-- No of returnable days
-- It shows the customer how many days are remaining to return the product
-- If the product crosses the returnable date, then it shows as 0

-- Business Manager, Customer Specific View
CREATE OR REPLACE VIEW NUMBER_OF_RETURNABLE_DAYS AS
SELECT 
    UNIQUE op.customer_order_id AS ORDER_ID,
    TO_DATE(o.delivery_date + c.return_by_days) AS RETURN_BY_DATE,
    op.id AS ORDER_PRODUCT_ID_,
    CASE 
        WHEN (o.delivery_date + c.return_by_days - SYSDATE) < 0 THEN 0
        ELSE (o.delivery_date + c.return_by_days - SYSDATE)
    END AS DAYS_REMAINING_TO_RETURN
FROM 
    (SELECT ORDER_ID, DELIVERY_DATE FROM Order_Delivery_Date) o
JOIN 
    "ORDER_PRODUCT" op ON o.Order_ID = op.customer_order_id
JOIN 
    "PRODUCT" p ON op.product_id = p.id
JOIN 
    "CATEGORY" c ON p.category_id = c.id;

-- Category list
-- Business Manager, Seller specific view

CREATE OR REPLACE VIEW category_view AS
SELECT id, name
FROM category;


-- Frequency of returned products 
-- This view displays how many times the product has been returned by all the customers

-- Business Manager, Seller specific view
CREATE OR REPLACE VIEW RETURNED_PRODUCTS_DETAILS AS
SELECT 
    MAX(p.name) AS PRODUCT_NAME,
    op.product_id AS PRODUCT_ID,
    COUNT(r.id) AS RETURN_FREQUENCY,
    MAX(r.reason) AS REASON
FROM 
    "RETURN" r
JOIN 
    "ORDER_PRODUCT" op ON r.order_product_id = op.id
JOIN 
    "PRODUCT" p ON op.product_id = p.id
GROUP BY 
    op.product_id;
    
-- To check all the returns which are approved by system (this will be used by seller)
-- Business manager, SELLER specific view

CREATE OR REPLACE VIEW CHECK_APPROVED_RETURNS_BY_SYSTEM AS
SELECT 
    R.ID AS RETURN_ID,
    S.CONTACT_NO AS SELLER_CONTACT,
    P.NAME AS PRODUCT_NAME, 
    R.REASON, 
    R.RETURN_DATE, 
    R.QUANTITY_RETURNED
FROM RETURN R
JOIN ORDER_PRODUCT OP ON R.ORDER_PRODUCT_ID = OP.ID
JOIN PRODUCT P ON P.ID = OP.PRODUCT_ID
JOIN SELLER S ON P.SELLER_ID = S.ID 
WHERE REQUEST_ACCEPTED=1 AND REFUND_STATUS='PROCESSING'
ORDER BY 3;


-- Price Charged
-- Business manager view

CREATE OR REPLACE VIEW product_discount_association AS
SELECT distinct p.id AS product_id,
       p.category_id,
       p.price,
       NVL(d.discount_rate, 0) AS discount_rate
FROM product p
 JOIN discount d ON p.category_id = d.category_id
 JOIN order_product op ON p.id = op.product_id
                       JOIN customer_order o ON op.customer_order_id = o.id where o.order_date BETWEEN d.start_date AND d.end_date;

 -- view for per unit product
 -- Customer specific view

CREATE OR REPLACE VIEW order_product_actual_price_per_unit AS
SELECT op.id AS order_product_id,
       op.customer_order_id,
       op.product_id,
       op.quantity,
       CASE
           WHEN pda.discount_rate > 0 THEN (pda.price - (pda.price * pda.discount_rate / 100))
           ELSE pda.price
       END AS price_charged
FROM order_product op
JOIN customer_order o ON op.customer_order_id = o.id
JOIN product_discount_association pda ON op.product_id = pda.product_id;


-- total price for all units
-- Customer specific view

CREATE OR REPLACE VIEW order_total_price_per_unit AS
SELECT customer_order_id,
       SUM(price_charged * quantity) AS total_price
FROM order_product_actual_price_per_unit
GROUP BY customer_order_id;

-- Refund Amount
-- Business manager view
CREATE OR REPLACE VIEW REFUND_AMOUNT_VIEW AS
SELECT 
    OP.ID,
    OP.PRODUCT_ID,
    P.PRICE,
    OP.CUSTOMER_ORDER_ID,
    O.ORDER_DATE,
    P.CATEGORY_ID,
    NVL(D.DISCOUNT_RATE, 0) AS DISCOUNT_RATE,
    CASE 
        WHEN R.processing_fee IS NOT NULL THEN NVL(P.PRICE - (P.PRICE * NVL(D.DISCOUNT_RATE, 0) / 100) - R.processing_fee, P.PRICE)
        ELSE NVL(P.PRICE - (P.PRICE * NVL(D.DISCOUNT_RATE, 0) / 100), P.PRICE)
    END AS ACTUAL_PRICE 
FROM 
    CUSTOMER_ORDER O 
JOIN 
    ORDER_PRODUCT OP ON OP.CUSTOMER_ORDER_ID = O.ID 
JOIN 
    PRODUCT P ON OP.PRODUCT_ID = P.ID 
LEFT JOIN 
    DISCOUNT D ON P.CATEGORY_ID = D.CATEGORY_ID AND O.ORDER_DATE BETWEEN D.START_DATE AND D.END_DATE 
JOIN 
    RETURN R ON OP.ID = R.ORDER_PRODUCT_ID;



-- Business manager, Customer specific view

CREATE OR REPLACE VIEW accepted_returns_view AS
SELECT
    s.name AS seller_name,
    p.name AS product_name,
    p.id AS product_id,
    r.reason AS return_reason,
    r.return_date,
    r.order_product_id,
    r.quantity_returned,
    r.store_id
FROM
    return r
    INNER JOIN order_product op ON r.order_product_id = op.id
    INNER JOIN product p ON op.product_id = p.id
    INNER JOIN seller s ON p.seller_id = s.id
WHERE
    r.request_accepted = 1;
    
-- Quantity available for return
-- Business manager, Customer specific view

 
CREATE OR REPLACE VIEW QTY_AVAILABLE_FOR_RETURN AS
SELECT op.id AS Order_product_id_,
       op.quantity - NVL(r.quantity_returned, 0) AS Available_Qty
FROM order_product op
LEFT JOIN "RETURN" r ON op.id = r.order_product_id
WHERE r.refund_status IS NULL OR r.refund_status <> 'REJECTED';


--Report for viewing processing fee collected
-- Business Manager

CREATE OR REPLACE VIEW processing_fees_by_year_month AS
SELECT
    TO_CHAR(return_date, 'YYYY') AS year,
    TO_CHAR(return_date, 'MM') AS month,
    SUM(processing_fee) AS total_processing_fee
FROM
    return
GROUP BY
    TO_CHAR(return_date, 'YYYY'),
    TO_CHAR(return_date, 'MM');



CREATE OR REPLACE VIEW seller_returned_products AS
SELECT
    s.id AS seller_id,
    s.name AS seller_name,
    p.id AS product_id,
    p.name AS product_name,
    r.return_date,
    r.reason,
    r.refund_status,
    r.quantity_returned,
    r.processing_fee
FROM
    seller s
JOIN
    product p ON s.id = p.seller_id
JOIN
    order_product op ON p.id = op.product_id
JOIN
    return r ON op.id = r.order_product_id;
    
-- store list
-- Business manager, Customer specific view

CREATE OR REPLACE VIEW store_for_feedback AS
SELECT r.store_id, p.name AS product_name, op.customer_order_id
FROM return r
JOIN order_product op ON r.order_product_id = op.id
JOIN product p ON op.product_id = p.id;


-- Store Rating
-- Business manager, Customer specific, Store specific view

CREATE OR REPLACE VIEW store_average_rating_view AS
SELECT store_id,
       AVG(customer_rating) AS avg_rating
FROM feedback
GROUP BY store_id;

-- GRANTS

-- CUSTOMER_USER
GRANT SELECT ON  store_for_feedback TO CUSTOMER_USER;
GRANT SELECT ON store_average_rating_view TO CUSTOMER_USER;
GRANT SELECT ON accepted_returns_view TO CUSTOMER_USER;
GRANT SELECT ON order_product_actual_price_per_unit TO CUSTOMER_USER;
GRANT SELECT ON order_total_price_per_unit TO CUSTOMER_USER;

-- STORE_USER
GRANT SELECT ON store_average_rating_view TO STORE_USER;

-- SELLER_USER
GRANT SELECT ON RETURNED_PRODUCTS_DETAILS TO SELLER_USER;
GRANT SELECT ON  category_view TO SELLER_USER;
GRANT SELECT ON  CHECK_APPROVED_RETURNS_BY_SYSTEM TO SELLER_USER;
