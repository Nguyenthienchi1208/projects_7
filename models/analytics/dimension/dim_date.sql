{{ config(
    materialized='table'
) }}

SELECT 
    date_key,
    full_date,
    year,
    month,
    day
FROM {{ ref('stg_dim_date') }}