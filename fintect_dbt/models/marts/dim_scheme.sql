SELECT 
    scheme_key,
    scheme_name,
    region
FROM 
    {{ ref('stg_schemes') }}