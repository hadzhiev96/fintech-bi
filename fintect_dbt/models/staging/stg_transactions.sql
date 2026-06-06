SELECT
    transaction_id,
    customer_key,
    card_key,
    merchant_key,
    bank_key,
    scheme_key,
    date_key,
    transaction_amount,
    interchange_fee,
    scheme_fee,
    fx_rate,
    fraud_loss,
    is_chargeback
FROM
    {{ source('fintech', 'fact_transactions') }}