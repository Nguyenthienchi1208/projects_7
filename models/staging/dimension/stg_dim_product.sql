{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        SAFE_CAST(product.product_id AS INT64) AS product_key,
        product.name AS product_name,
        CAST(product.max_price AS NUMERIC) AS max_price,
        CAST(product.min_price AS NUMERIC) AS min_price,
        product.sku AS sku,
        SAFE_CAST(product.category AS INT64) AS category
    FROM {{ source('glamira_raw', 'product_detail_raw') }}
),

final AS (
    SELECT 
        product_key,
        ANY_VALUE(product_name) AS product_name,
        MAX(max_price) AS max_price,
        MIN(min_price) AS min_price,
        ANY_VALUE(sku) AS sku,
        MAX(category) AS category
    FROM source_data
    GROUP BY 1
)

SELECT * FROM final