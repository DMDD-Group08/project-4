
-- Frequency of returned products 
-- This view displays how many times the product has been returned by all the customers

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
    


-- Customer Reliability Index 
-- 1. We first calculate the total number of orders for each customer and the total number of returned orders for each customer using subqueries.
-- 2. We then left join these subqueries with the customer table to get the Customer_Name, Customer_ID, total_orders, and returned_orders.
-- 3. We calculate the reliability index as a percentage by subtracting the percentage of returned orders from 100. If total_orders is zero (to handle division by zero), we assume 100% reliability.
-- 4. This query provides the customer's name, ID, and reliability index as a percentage.

CREATE OR REPLACE VIEW Customer_Reliability_Index AS
SELECT 
    c.name AS Customer_Name,
    c.id AS Customer_ID,
 ROUND(
        CASE 
            WHEN total_orders = 0 THEN 100  -- Handle division by zero
            ELSE (1 - (returned_orders / total_orders)) * 100  -- Calculate reliability index as a percentage
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

CREATE OR REPLACE VIEW Order_Delivery_Date AS
SELECT 
    o.id AS Order_ID,
    o.customer_id AS Customer_ID,  -- Include the customer ID
    op.product_id AS Product_ID,
    p.name AS Product_Name,
    CASE 
        WHEN c.name = 'Food/Beverages' THEN o.order_date + INTERVAL '2' DAY
        WHEN c.name = 'Electronics' THEN o.order_date + INTERVAL '5' DAY
        WHEN c.name = 'Clothing/Apparel' THEN o.order_date + INTERVAL '7' DAY
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

CREATE OR REPLACE VIEW NUMBER_OF_RETURNABLE_DAYS AS
SELECT 
    op.customer_order_id AS ORDER_ID,
    p.name AS PRODUCT_NAME,
    TO_DATE(o.delivery_date + c.return_by_days) AS RETURN_BY_DATE,
    CASE 
        WHEN (o.delivery_date + c.return_by_days - SYSDATE) < 0 THEN 0
        ELSE (o.delivery_date + c.return_by_days - SYSDATE)
    END AS DAYS_REMAINING_TO_RETURN
FROM 
    Order_Delivery_Date o
JOIN 
    "ORDER_PRODUCT" op ON o.Order_ID = op.customer_order_id
JOIN 
    "PRODUCT" p ON op.product_id = p.id
JOIN 
    "CATEGORY" c ON p.category_id = c.id;
    




-- Category list

CREATE OR REPLACE VIEW category_view AS
SELECT id, name
FROM category;



-- store list

CREATE OR REPLACE VIEW store_for_feedback AS
SELECT r.store_id, p.name AS product_name, op.customer_order_id
FROM return r
JOIN order_product op ON r.order_product_id = op.id
JOIN product p ON op.product_id = p.id;


-- Store Rating

CREATE OR REPLACE VIEW store_average_rating_view AS
SELECT store_id,
       AVG(customer_rating) AS avg_rating
FROM feedback
GROUP BY store_id;


-- Price Charged

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
CREATE OR REPLACE VIEW order_total_price_per_unit AS
SELECT customer_order_id,
       SUM(price_charged * quantity) AS total_price
FROM order_product_actual_price_per_unit
GROUP BY customer_order_id;

-- Refund Amount

CREATE OR REPLACE VIEW refund_amount_view AS
SELECT distinct op.customer_order_id,op.product_id,(op.price_charged * r1.quantity_returned) - NVL(r1.processing_fee, 0) as refund_amount
                                       FROM order_product_actual_price_per_unit op join return r1
                                       on op.order_product_id = r1.order_product_id where r1.seller_refund > 0 ;