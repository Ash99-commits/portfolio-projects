CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

CREATE TABLE raw_customers (
	customer_id VARCHAR(50) PRIMARY KEY,
    customer_zip_code VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(50)
);

CREATE TABLE raw_orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_timestamp DATETIME,
    order_estimated_delivery_date DATE
);

CREATE TABLE raw_order_items (
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    price DECIMAL(10,2),
    shipping_charges DECIMAL(10,2)
);

CREATE TABLE raw_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);

CREATE TABLE raw_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);


SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

TRUNCATE TABLE raw_payments;

-- File 1
LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/DATA SCIENCE & AIML Career/Portfolio Projects/Skill-showcase Projects/Project 2 - SQL Mastery Case/Dataset/raw_data/df_Customers.csv' 
INTO TABLE raw_customers FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- File 2
LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/DATA SCIENCE & AIML Career/Portfolio Projects/Skill-showcase Projects/Project 2 - SQL Mastery Case/Dataset/raw_data/df_Orders.csv' 
INTO TABLE raw_orders FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, @v_approved, @v_delivered, order_estimated_delivery_date)
SET 
  order_approved_at = NULLIF(@v_approved, ''),
  order_delivered_timestamp = NULLIF(@v_delivered, '');
-- File 3
LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/DATA SCIENCE & AIML Career/Portfolio Projects/Skill-showcase Projects/Project 2 - SQL Mastery Case/Dataset/raw_data/df_Products.csv'
REPLACE INTO TABLE raw_products
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(product_id, @v_cat, @v_w, @v_l, @v_h, @v_wi)
SET 
  product_category_name = NULLIF(@v_cat, ''),
  -- Chops .0 AND handles empty spaces for INT columns
  product_weight_g = NULLIF(SUBSTRING_INDEX(@v_w, '.', 1), ''),
  product_length_cm = NULLIF(SUBSTRING_INDEX(@v_l, '.', 1), ''),
  product_height_cm = NULLIF(SUBSTRING_INDEX(@v_h, '.', 1), ''),
  product_width_cm = NULLIF(SUBSTRING_INDEX(@v_wi, '.', 1), '');
-- File 4
LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/DATA SCIENCE & AIML Career/Portfolio Projects/Skill-showcase Projects/Project 2 - SQL Mastery Case/Dataset/raw_data/df_Orderitems.csv' 
INTO TABLE raw_order_items FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- File 5
LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/DATA SCIENCE & AIML Career/Portfolio Projects/Skill-showcase Projects/Project 2 - SQL Mastery Case/Dataset/raw_data/df_Payments.csv' 
INTO TABLE raw_payments FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' IGNORE 1 ROWS;


SELECT 'raw_customers'   AS table_name, COUNT(*) AS row_count FROM raw_customers
UNION ALL
SELECT 'raw_orders',     COUNT(*) FROM raw_orders
UNION ALL
SELECT 'raw_order_items',COUNT(*) FROM raw_order_items
UNION ALL
SELECT 'raw_payments',   COUNT(*) FROM raw_payments
UNION ALL
SELECT 'raw_products',   COUNT(*) FROM raw_products;

-- Distinct Key Reality Check
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT order_id)    AS distinct_orders
FROM raw_order_items;

SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT order_id)    AS distinct_orders
FROM raw_payments;

SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM raw_orders;

-- Mandatory Null Checks (Only What Can Break Logic)

-- Orders
SELECT
    SUM(order_id IS NULL)                   AS null_order_id,
    SUM(customer_id IS NULL)                AS null_customer_id,
    SUM(order_status IS NULL)               AS null_order_status,
    SUM(order_purchase_timestamp IS NULL)   AS null_purchase_ts
FROM raw_orders;

-- Payments
SELECT
    SUM(payment_value IS NULL) AS null_payment_value
FROM raw_payments;

-- Orderitems
SELECT
    SUM(price IS NULL)             AS null_price,
    SUM(shipping_charges IS NULL)  AS null_shipping
FROM raw_order_items;

-- Referential Integrity Signals

-- Orders -> Customers
SELECT COUNT(*) AS invalid_customer_reference
FROM raw_orders o
LEFT JOIN raw_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Orderitems -> Orders
SELECT COUNT(*) AS invalid_order_reference
FROM raw_order_items oi
LEFT JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Payments -> Orders
SELECT COUNT(*) AS invalid_payment_reference
FROM raw_payments p
LEFT JOIN raw_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order Lifecycle Timestamp Sanity

-- Purchase After Delivery (Impossible)
SELECT COUNT(*) AS invalid_purchase_delivery
FROM raw_orders
WHERE order_delivered_timestamp < order_purchase_timestamp;

-- Approval Before Purchase (Impossible)
SELECT COUNT(*) AS invalid_approval_purchase
FROM raw_orders
WHERE order_approved_at < order_purchase_timestamp;

-- Estimated Delivery Before Purchase (Impossible)
SELECT COUNT(*) AS invalid_estimated_delivery
FROM raw_orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- Duplicate Row Check

-- Customers Table
SELECT COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_rows
FROM raw_customers;

-- Orders Table
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM raw_orders;

-- Order Items Table
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM raw_order_items;

-- Payments Table
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM raw_payments;

-- Products Table
SELECT COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_rows
FROM raw_products;

-- Categorical Consistency Check

-- Order Status Values
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM raw_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Numeric Value Sanity Check

SELECT
    SUM(price < 0) AS negative_price,
    SUM(shipping_charges < 0) AS negative_shipping,
    SUM(payment_value < 0) AS negative_payment
FROM raw_order_items oi
JOIN raw_payments p
ON oi.order_id = p.order_id;

-- Business Question 1 : How much total revenue has the company generated?

SELECT
    SUM(payment_value) AS total_revenue
FROM raw_payments;

-- Business Question 2 : How many orders generated this revenue?

SELECT
    COUNT(order_id) AS total_orders
FROM raw_orders;

-- Business Question 3 : How many unique customers bought from us?

SELECT
    COUNT(DISTINCT customer_id) AS total_customers
FROM raw_customers;

-- Business Question 4 : On average, how much money does each order generate?

SELECT
    SUM(payment_value) / COUNT(order_id) AS avg_order_value
FROM raw_payments;

-- Business Question 5 : How much revenue came from shipping charges?

SELECT
    SUM(shipping_charges) AS total_shipping_revenue
FROM raw_order_items;

-- Business Question 6 : Which regions generate the most money for the business?

SELECT
    c.customer_state,
    SUM(p.payment_value) AS total_revenue
FROM raw_customers c
JOIN raw_orders o
    ON c.customer_id = o.customer_id
JOIN raw_payments p
    ON o.order_id = p.order_id
GROUP BY c.customer_state
ORDER BY total_revenue DESC LIMIT 10;

-- Business Question 7 : Which cities have the largest customer base?

SELECT
    customer_city,
    COUNT(customer_id) AS total_customers
FROM raw_customers
GROUP BY customer_city
ORDER BY total_customers DESC LIMIT 5;

-- Business Question 8 : In which states do most of our customers live?

SELECT
    customer_state,
    COUNT(customer_id) AS total_customers
FROM raw_customers
GROUP BY customer_state
ORDER BY total_customers DESC LIMIT 10;

-- Business Question 9 : How many orders are delivered, cancelled, or still processing?

SELECT
    order_status,
    COUNT(order_id) AS total_orders
FROM raw_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Business Question 10 : What is the percentage of orders that has been successfully delivered ?

SELECT
    ROUND(
        (SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0)
        / COUNT(*),
        2
    ) AS delivery_success_rate
FROM raw_orders;

-- Business Question 11 : How long does it typically take to deliver an order?

SELECT
    ROUND(AVG(DATEDIFF(order_delivered_timestamp, order_purchase_timestamp)), 2) 
    AS avg_delivery_days
FROM raw_orders
WHERE order_status = 'delivered';

-- Business Question 12 : How often do we miss our promised delivery date?

SELECT
    COUNT(*) AS late_deliveries
FROM raw_orders
WHERE order_status = 'delivered'
AND order_delivered_timestamp > order_estimated_delivery_date;

-- Business Question 13 : Which types of products bring the most money?

SELECT
    p.product_category_name,
    SUM(oi.price) AS total_revenue
FROM raw_order_items oi
JOIN raw_products p
    ON oi.product_id = p.product_id
JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC LIMIT 10;

-- Quick sanity check to know how many products exist in each category as we got an abnormally high value.

SELECT product_category_name, COUNT(*)
FROM raw_products
GROUP BY product_category_name
ORDER BY COUNT(*) DESC LIMIT 10;

-- Business Question 14 : What are the Top product categories by number of orders?

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM raw_order_items oi
JOIN raw_products p
    ON oi.product_id = p.product_id
JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_orders DESC
LIMIT 10;

-- Business Question 15 : Which categories sell expensive products vs cheaper products?

SELECT
    p.product_category_name,
    ROUND(AVG(oi.price),2) AS avg_product_price
FROM raw_order_items oi
JOIN raw_products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_product_price DESC
LIMIT 10;

-- Business Question 16 : What is the average shipping cost ?

SELECT
    ROUND(AVG(shipping_charges),2) AS avg_shipping_cost
FROM raw_order_items;

-- Business Question 17 : Is shipping cheap or expensive relative to the product price?

SELECT
    ROUND(AVG(shipping_charges / price) * 100, 2) 
    AS shipping_percentage_of_price
FROM raw_order_items
WHERE price > 0;

-- Business Question 18 : What are the Top 10 Highest Revenue Generating Products ?

SELECT
    oi.product_id,
    ROUND(SUM(oi.price),2) AS total_revenue
FROM raw_order_items oi
JOIN raw_orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- Business Question 19 : Is revenue growing or declining over time?

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(oi.price),2) AS monthly_revenue
FROM raw_orders o
JOIN raw_order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;

-- Business Question 20 : What is the Cumulative Revenue Growth Over Time?

SELECT
    order_month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY order_month)
        AS cumulative_revenue
FROM
(
    SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        ROUND(SUM(oi.price),2) AS monthly_revenue
    FROM raw_orders o
    JOIN raw_order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
) t
ORDER BY order_month;