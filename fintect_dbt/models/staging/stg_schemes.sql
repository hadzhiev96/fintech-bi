SELECT 
    scheme_key,
    scheme_name,
    region,
    interchange_rate
FROM 
    {{ source('fintech','dim_scheme') }}