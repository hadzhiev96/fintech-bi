SELECT
	dm.merchant_key,
	dm.merchant_name,
	dm.business_category,
	SUM(ft.interchange_fee) AS interchange_fee,
	SUM(ft.scheme_fee) AS scheme_fee,
	SUM(ft.fraud_loss) AS fraud_loss,
	(SUM(ft.interchange_fee) - SUM(ft.scheme_fee) - SUM(ft.fraud_loss)) AS net_revenue,
	COUNT(ft.transaction_id) AS count_of_transactions
FROM
	fact_transactions ft
INNER JOIN dim_merchant dm 
ON
	ft.merchant_key = dm.merchant_key
GROUP BY dm.merchant_key, dm.merchant_name, dm.business_category
ORDER BY net_revenue DESC