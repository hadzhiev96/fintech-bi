SELECT 
    merchant_key,
    merchant_name,
    CONCAT(merchant_name, ' (', merchant_key, ')') AS merchant_display_name,
    business_category,
    city,
    country,
    bank_key
FROM
    {{ ref('stg_merchants') }}