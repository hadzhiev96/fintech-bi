SELECT
	dm.business_category,
	ROUND(sum(CASE
		WHEN ft.is_chargeback = TRUE THEN 1
		ELSE 0
	END)::decimal / count(ft.transaction_id)::decimal * 100, 2) AS chargeback_pct
FROM
	fact_transactions ft
JOIN dim_merchant dm 
ON
	ft.merchant_key = dm.merchant_key
	GROUP BY dm.business_category