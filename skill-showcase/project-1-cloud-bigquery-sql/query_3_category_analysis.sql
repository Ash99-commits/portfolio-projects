SELECT
  category,
  SUM(sales)  AS total_sales,
  SUM(profit) AS total_profit
FROM ecommerce_ds.sales_clean
GROUP BY category
ORDER BY total_sales DESC;