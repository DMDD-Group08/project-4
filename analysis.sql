-- view_product_performance IS 'A view summarizing the total number of product returns, grouped by year, month (with the month name), and product name. This view facilitates analysis of product return patterns over time.';
CREATE OR REPLACE VIEW view_product_performance AS
SELECT
    EXTRACT(YEAR FROM r.return_date) AS "Year",
    TO_CHAR(r.return_date, 'Month') AS "MonthName", -- Converts month number to month name
    p.name AS "ProductName",
    COUNT(r.id) AS "TotalReturns"
FROM
    return r
INNER JOIN
    order_product op ON r.order_product_id = op.id
INNER JOIN
    customer_order co ON op.customer_order_id = co.id
INNER JOIN
    product p ON op.product_id = p.id
GROUP BY
    EXTRACT(YEAR FROM r.return_date),
    TO_CHAR(r.return_date, 'Month'),
    p.name
ORDER BY
    "Year",
    "MonthName",
    "ProductName";



-- view_seller_returns IS A view summarizing the total number of returns for products from each seller, grouped by year and month (with the month name). This view helps in assessing seller performance and product quality by analyzing return trends associated with sellers.';


CREATE OR REPLACE VIEW view_seller_returns AS
SELECT
    EXTRACT(YEAR FROM r.return_date) AS "Year",
    TO_CHAR(r.return_date, 'Month') AS "MonthName", -- Converts month number to month name
    s.name AS "SellerName",
    COUNT(r.id) AS "TotalReturns"
FROM
    return r
INNER JOIN
    order_product op ON r.order_product_id = op.id
INNER JOIN
    customer_order co ON op.customer_order_id = co.id
INNER JOIN
    product p ON op.product_id = p.id
INNER JOIN
    seller s ON p.seller_id = s.id
GROUP BY
    EXTRACT(YEAR FROM r.return_date),
    TO_CHAR(r.return_date, 'Month'),
    s.name
ORDER BY
    "Year",
    "MonthName",
    "SellerName";


-- Creates or replaces a view named view_store_ratings_comparison
CREATE OR REPLACE VIEW view_store_ratings_comparison AS
SELECT
    -- Selects distinct store IDs to avoid duplicate rows
    Distinct f.store_id AS "Store_ID",
    -- Calculates the average customer rating for each store
    AVG(f.customer_rating) OVER (PARTITION BY f.store_id) AS "Store_Average_Rating",
    -- Calculates the overall average customer rating across all stores
    AVG(f.customer_rating) OVER () AS "Overall_Average_Rating"
FROM
    -- Specifies the feedback table as the source of the data
    feedback f
-- Orders the result by store ID for better readability
ORDER BY store_id;
