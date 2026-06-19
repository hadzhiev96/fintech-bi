SELECT
    transaction_id,
    transaction_amount,
    interchange_fee,
    scheme_fee,
    fx_rate,
    fraud_loss,
    is_chargeback,
    interchange_fee - scheme_fee - fraud_loss AS net_revenue,
    CASE
      WHEN fraud_loss > 0 THEN TRUE
      ELSE FALSE
    END AS is_fraud,
    customer_key,
    card_key,
    merchant_key,
    bank_key,
    scheme_key,
    date_key
FROM
    {{ref('int_transactions_enriched')}}