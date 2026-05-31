WITH net_revenue_per_year_month AS(SELECT
	dd."year",
	dd."month",
	(SUM(ft.interchange_fee) - SUM(ft.scheme_fee) - SUM(ft.fraud_loss)) AS net_revenue
FROM
	fact_transactions ft
INNER JOIN dim_date dd 
ON
	ft.date_key = dd.date_key 
GROUP BY dd."year", dd."month"),
prev_month_rev AS (
SELECT
	"year",
	"month",
	net_revenue,
	LAG(net_revenue) OVER(ORDER BY "year", "month") AS prev_month_revenue
FROM
	net_revenue_per_year_month)
SELECT
	*,
	net_revenue - prev_month_revenue AS mom_change,
	CASE
		WHEN prev_month_revenue IS NULL OR prev_month_revenue <= 0 THEN NULL
		ELSE ROUND((net_revenue - prev_month_revenue) / prev_month_revenue * 100, 2)
	END AS mom_change_pct
FROM
	prev_month_rev