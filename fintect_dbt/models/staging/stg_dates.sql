SELECT 
    date_key,
    "date" AS transaction_date,
    "day" AS transaction_day,
    "month" AS transaction_month,
    "quarter" AS transaction_quarter,
    "year" AS transaction_year,
    is_weekend
FROM 
    {{ source('fintech', 'dim_date') }}