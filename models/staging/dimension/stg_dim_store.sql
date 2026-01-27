{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        store_id
    FROM {{ source('glamira_raw', 'customer_behaviour') }}
    WHERE 
        collection = 'checkout_success'
        AND store_id IS NOT NULL 
        AND store_id <> ''
),

final AS (
    SELECT DISTINCT
        store_id AS store_key,
        CONCAT('store_', store_id) AS store_name
    FROM source_data
)

SELECT * FROM final