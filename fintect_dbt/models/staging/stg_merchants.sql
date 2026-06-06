SELECT 
    merchant_key,
    merchant_name,
    business_category,
    city,
    country,
    bank_key
FROM 
    {{ source('fintech', 'dim_merchant') }}