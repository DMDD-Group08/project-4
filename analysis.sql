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
