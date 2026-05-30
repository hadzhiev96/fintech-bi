SELECT
	dd."year",
	dd."month" ,
	count(ft.transaction_id) AS total_transaction_count,
	sum(ft.interchange_fee) AS total_interchange_fee,
	sum(ft.scheme_fee) AS total_scheme_fee,
	sum(ft.fraud_loss) AS total_fraud_loss,
	(SUM(ft.interchange_fee) - SUM(ft.scheme_fee) - SUM(ft.fraud_loss)) AS net_revenue,
	ROUND(AVG(ft.transaction_amount), 2) AS average_transaction_amount
FROM
	fact_transactions ft
INNER JOIN dim_date dd 
ON
	ft.date_key = dd.date_key
GROUP BY
	dd."year" ,
	dd."month"
ORDER BY
	dd."year" DESC,
	dd."month" DESC