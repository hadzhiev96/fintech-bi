SELECT 
    card_key,
    card_type,
    card_network,
    currency,
    card_status,
    date_issued,
    expiry_date,
    customer_key
FROM 
    {{ source('fintech', 'dim_card')}}