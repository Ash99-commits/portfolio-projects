CREATE OR REPLACE TABLE ecommerce_ds.sales_clean AS
SELECT
  DATE(`Order Date`)          AS order_date,
  `Product Name`              AS product_name,
  IFNULL(Category, 'Unknown') AS category,
  IFNULL(Region, 'Unknown')   AS region,
  CAST(Quantity AS INT64)     AS quantity,
  CAST(Sales AS FLOAT64)      AS sales,
  CAST(Profit AS FLOAT64)     AS profit
FROM ecommerce_ds.sales_raw WHERE `Order Date` IS NOT NULL AND `Product Name` IS NOT NULL AND Sales IS NOT NULL AND Sales >= 0;