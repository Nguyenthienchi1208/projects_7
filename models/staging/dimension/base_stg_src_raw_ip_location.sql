{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        ip,
        country_long,
        region,
        city
    FROM {{ source('glamira_raw', 'ip_location_k') }}
    WHERE 
        ip IS NOT NULL
),

final AS (
    SELECT 
        ip,
        FARM_FINGERPRINT(CONCAT(country_long, '_', region, '_', city)) AS location_key,
        country_long,
        region,
        city
    FROM source_data
    GROUP BY 
        ip, 
        country_long, 
        region, 
        city
)

SELECT * FROM final