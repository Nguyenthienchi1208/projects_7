{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        SAFE_CAST(user_id_db AS INT64) AS customer_key,
        email_address,
        user_agent,
        resolution,
        device_id
    FROM {{ source('glamira_raw', 'customer_behaviour') }}
),

final AS (
    SELECT *
    FROM source_data
    QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_key ORDER BY customer_key) = 1
)

SELECT * FROM final