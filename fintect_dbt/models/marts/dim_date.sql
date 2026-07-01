SELECT 
    date_key,
    transaction_date,
    transaction_day,
    transaction_month,
    transaction_quarter,
    transaction_year,
    CONCAT(transaction_year,'-',LPAD(transaction_month::text,2,'0')) AS transaction_year_month,
    is_weekend
FROM
    {{ref('stg_dates')}}