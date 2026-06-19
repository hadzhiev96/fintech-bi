WITH transactions AS (
    SELECT
        merchant_key,
        interchange_fee,
        scheme_fee,
        is_chargeback,
        fraud_loss,
        transaction_id,
        net_revenue

    FROM
        {{ ref('fct_transactions') }}
),

merchant_info AS (
    SELECT
        merchant_key,
        merchant_name,
        business_category
    FROM
        {{ ref('dim_merchant') }}
),

aggregated AS (
    SELECT
        t.merchant_key,
        m.merchant_name,
        m.business_category,
        SUM(t.interchange_fee) AS total_interchange_fee,
        SUM(t.scheme_fee) AS total_scheme_fee,
        SUM(t.fraud_loss) AS total_fraud_loss,
        SUM(t.net_revenue) AS net_revenue,
        COUNT(t.transaction_id) AS total_transactions_count,
        ROUND(
            SUM(
                CASE
                    WHEN t.is_chargeback = TRUE THEN 1
                    ELSE 0
                END
            )::decimal / COUNT(t.transaction_id)::decimal * 100,
            2
        ) AS chargeback_pct
    FROM
        transactions AS t
    INNER JOIN
        merchant_info AS m
        ON t.merchant_key = m.merchant_key
    GROUP BY
        t.merchant_key,
        m.merchant_name,
        m.business_category
)

SELECT *
FROM
    aggregated
