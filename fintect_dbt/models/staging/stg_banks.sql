SELECT 
    bank_key,
    bank_name,
    country,
    bank_type
FROM 
    {{ source('fintech','dim_bank')}}