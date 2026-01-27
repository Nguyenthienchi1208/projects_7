{{ config(
    materialized='table'
) }}

WITH source_data AS (
    SELECT 
        CAST(product.product_id AS INT64) AS product_key,
        product.name AS product_name,
        CAST(product.max_price AS NUMERIC) AS max_price,
        CAST(product.min_price AS NUMERIC) AS min_price,
        product.sku AS sku,
        CAST(product.category AS INT64) AS category
    FROM {{ source('glamira_raw', 'product_detail_raw') }}
    WHERE 
        product.product_id IS NOT NULL 
        AND product.product_id <> ''
),

final AS (
    SELECT 
        product_key,
        ANY_VALUE(product_name) AS product_name,
        MAX(max_price) AS max_price,
        MIN(min_price) AS min_price,
        ANY_VALUE(sku) AS sku,
        ANY_VALUE(category) AS category
    FROM source_data
    GROUP BY 1
)

SELECT * FROM final