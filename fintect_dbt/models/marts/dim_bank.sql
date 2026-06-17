SELECT 
    bank_key,
    bank_name,
    country,
    bank_type
FROM 
    {{ ref('stg_banks')}}