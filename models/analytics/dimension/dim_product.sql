{{ config(
    materialized='table'
) }}

SELECT 
    COALESCE(product_key, -1) AS product_key,
    COALESCE(product_name, 'undefined') AS product_name,
    COALESCE(max_price, -1) AS max_price,
    COALESCE(min_price, -1) AS min_price,
    COALESCE(sku, 'undefined') AS sku,
    COALESCE(category, -1) AS category
FROM {{ ref('stg_dim_product') }}