

SELECT
	dm.merchant_name,
	dm.business_category,
	sum(ft.interchange_fee) AS interchange_revenue
FROM
	fact_transactions ft
INNER JOIN dim_merchant dm 
ON
	ft.merchant_key = dm.merchant_key 
GROUP BY dm.merchant_key, dm.merchant_name, dm.business_category 
ORDER BY interchange_revenue DESC
LIMIT 10;

	
	
	
