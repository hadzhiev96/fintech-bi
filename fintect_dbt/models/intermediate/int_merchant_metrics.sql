WITH transactions_enriched AS(
    SELECT 
        merchant_key,
        merchant_name,
        business_category,
        interchange_fee,
        scheme_fee,
        is_chargeback,
        fraud_loss,
        transaction_id

    FROM
        {{ref('int_transactions_enriched')}}
)

SELECT
    merchant_key,
    merchant_name,
    business_category,
    SUM(interchange_fee) as total_interchange_fee,
    SUM(scheme_fee) as total_scheme_fee,
    SUM(fraud_loss) as total_fraud_loss,
    (SUM(interchange_fee) - SUM(scheme_fee) - SUM(fraud_loss)) AS net_revenue,
    COUNT(transaction_id) as total_transactions_count,
    ROUND(sum(CASE
		WHEN is_chargeback = TRUE THEN 1
		ELSE 0
	END)::decimal / count(transaction_id)::decimal * 100, 2) AS chargeback_pct
FROM 
   transactions_enriched
GROUP BY
    merchant_key,
    merchant_name,
    business_category