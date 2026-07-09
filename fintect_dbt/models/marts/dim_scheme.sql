SELECT 
    scheme_key,
    scheme_name,
    region,
    CONCAT(scheme_name, ' (', region, ')') AS scheme_display_name
FROM 
    {{ ref('stg_schemes') }}