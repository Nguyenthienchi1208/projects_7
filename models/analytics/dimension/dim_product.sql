{{ config(
    materialized='table'
) }}

SELECT 
    product_key,
    product_name,
    max_price,
    min_price,
    sku,
    category
FROM {{ ref('stg_dim_product') }}