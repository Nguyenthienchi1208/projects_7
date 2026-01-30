{{ config(
    materialized='table'
) }}

WITH source_processed AS (
    SELECT 
        *,
        CASE 
            WHEN quantity > 5 THEN 1 
            ELSE quantity 
        END AS clean_quantity
    FROM {{ ref('stg_fact_sales_order') }}
    WHERE sales_order_key IS NOT NULL 
)

SELECT 
    sales_order_key,
    COALESCE(NULLIF(SAFE_CAST(customer_key AS INT64), 0), -1) AS customer_key,
    COALESCE(NULLIF(SAFE_CAST(date_key AS INT64), 0), -1) AS date_key,
    COALESCE(NULLIF(SAFE_CAST(store_key AS INT64), 0), -1) AS store_key,
    COALESCE(NULLIF(SAFE_CAST(product_key AS INT64), 0), -1) AS product_key,
    COALESCE(NULLIF(SAFE_CAST(bill_to_address_key AS INT64), 0), -1) AS bill_to_address_key,
    
    clean_quantity AS quantity, 
    COALESCE(unit_price_usd, 0.0) AS unit_price_usd,

    ROUND(
        SUM(COALESCE(unit_price_usd, 0.0)) OVER(PARTITION BY sales_order_key), 
        2
    ) AS total_order_amount
FROM source_processed