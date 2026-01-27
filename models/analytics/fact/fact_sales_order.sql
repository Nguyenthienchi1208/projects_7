{{ config(
    materialized='table',
    schema='glamira_dwh'
) }}

WITH source_processed AS (
    SELECT 
        stg.*,
        CASE 
            WHEN stg.quantity > 5 THEN 1 
            ELSE stg.quantity 
        END AS clean_quantity
    FROM {{ ref('stg_fact_sales_order') }} AS stg
    INNER JOIN {{ ref('dim_product') }} AS dim 
        ON stg.product_key = dim.product_key
    WHERE 
        stg.unit_price_usd > 0 
        AND stg.customer_key IS NOT NULL
        AND stg.sales_order_key IS NOT NULL
        AND stg.quantity > 0 
)

SELECT 
    sales_order_key,
    customer_key,
    date_key,
    store_key,
    product_key,
    bill_to_address_key,
    clean_quantity AS quantity, 
    unit_price_usd,
    ROUND(
        SUM(unit_price_usd) OVER(PARTITION BY sales_order_key), 
        2
    ) AS total_order_amount
FROM source_processed