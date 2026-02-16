SELECT
  DATE_TRUNC(order_date, MONTH) AS month,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
FROM ecommerce_ds.sales_clean WHERE order_date IS NOT NULL GROUP BY month ORDER BY month;