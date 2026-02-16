SELECT
  category,
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
  SAFE_DIVIDE(SUM(profit), SUM(sales)) AS profit_margin
FROM ecommerce_ds.sales_clean
GROUP BY category
ORDER BY profit_margin DESC;