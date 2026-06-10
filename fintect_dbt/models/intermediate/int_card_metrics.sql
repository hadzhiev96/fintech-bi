WITH transactions_enriched AS(
    SELECT
        card_key,
        card_type,
        transaction_amount,
        fraud_loss,
        transaction_id
    FROM
        {{ref('int_transactions_enriched')}}
    
)

SELECT
    card_key,
    card_type,
    SUM(transaction_amount) as total_transactions_amount,
    COUNT(transaction_id) as total_transactions_count,
    SUM(fraud_loss) as total_fraud_loss,
    SUM(CASE WHEN fraud_loss > 0 THEN 1 ELSE 0 END) as count_of_fraudulent_transactions
FROM
    transactions_enriched
GROUP BY
    card_key,
    card_type