SELECT
    *
FROM
    {{ source('fintech', 'fact_transactions') }}