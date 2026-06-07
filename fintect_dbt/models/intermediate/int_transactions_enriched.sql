WITH banks AS (
    SELECT
        bank_key,
        bank_name
    FROM 
        {{ref('stg_banks')}}
),

cards AS(
    SELECT
        card_key,
        card_type
    FROM
        {{ref('stg_cards')}}
),

customers AS(
    SELECT
        customer_key,
        first_name,
        last_name
    FROM
        {{ref('stg_customers')}}
),

dates AS(
    SELECT
        date_key,
        transaction_date,
        transaction_day,
        transaction_month,
        transaction_quarter,
        transaction_year,
        is_weekend
    FROM
        {{ref('stg_dates')}}
),

merchants AS(
    SELECT
        merchant_key,
        merchant_name,
        business_category
    FROM
        {{ref('stg_merchants')}}
),

schemes AS(
    SELECT
        scheme_key,
        scheme_name
    FROM 
        {{ref('stg_schemes')}}
),

transactions AS(
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
        {{ref('stg_transactions')}}
)

SELECT
    t.transaction_id,
    t.transaction_amount,
    t.interchange_fee,
    t.scheme_fee,
    t.fx_rate,
    t.fraud_loss,
    t.is_chargeback,
    t.customer_key,
    t.card_key,
    t.merchant_key,
    t.bank_key,
    t.scheme_key,
    t.date_key,
    cust.first_name,
    cust.last_name,
    CONCAT(cust.first_name, ' ', cust.last_name) AS customer_full_name,
    card.card_type,
    m.merchant_name,
    m.business_category,
    b.bank_name,
    s.scheme_name,
    d.transaction_date,
    d.transaction_day,
    d.transaction_month,
    d.transaction_quarter,
    d.transaction_year,
    d.is_weekend
FROM
    transactions AS t
LEFT JOIN
    customers AS cust ON t.customer_key = cust.customer_key
LEFT JOIN
    cards AS card ON t.card_key = card.card_key
LEFT JOIN
    merchants AS m ON t.merchant_key = m.merchant_key
LEFT JOIN
    banks AS b ON t.bank_key = b.bank_key
LEFT JOIN
    schemes AS s ON t.scheme_key = s.scheme_key
LEFT JOIN
    dates AS d ON t.date_key = d.date_key