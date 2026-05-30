SELECT
	ds.scheme_name,
	count(ft.transaction_id) AS total_transactions,
	sum(CASE
		WHEN ft.fraud_loss > 0 THEN 1
		ELSE 0
	END) AS total_fradulent_transactions,
	ROUND(sum(CASE
		WHEN ft.fraud_loss > 0 THEN 1
		ELSE 0
	END)::decimal / count(ft.transaction_id)::decimal * 100,2) AS fraud_rate_pct
FROM
		fact_transactions ft
INNER JOIN dim_scheme ds 
ON
		ft.scheme_key = ds.scheme_key
GROUP BY
		ds.scheme_name
ORDER BY
		fraud_rate_pct
	