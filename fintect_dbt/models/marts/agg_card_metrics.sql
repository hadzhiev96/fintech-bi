WITH transactions AS (
    SELECT
        card_key,
        transaction_amount,
        fraud_loss,
        transaction_id,
        net_revenue
    FROM
        {{ ref('fct_transactions') }}

),

card_info AS (
    SELECT
        card_key,
        card_type
    FROM
        {{ ref('dim_card') }}
),

aggregated AS (
    SELECT
        t.card_key,
        c.card_type,
        SUM(t.transaction_amount) AS total_transactions_amount,
        COUNT(t.transaction_id) AS total_transactions_count,
        SUM(t.fraud_loss) AS total_fraud_loss,
        SUM(CASE WHEN t.fraud_loss > 0 THEN 1 ELSE 0 END)
            AS count_of_fraudulent_transactions,
        SUM(t.net_revenue) AS net_revenue

    FROM
        transactions AS t
    INNER JOIN
        card_info AS c
        ON t.card_key = c.card_key
    GROUP BY
        t.card_key,
        c.card_type
)

SELECT *
FROM
    aggregated
