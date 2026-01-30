{{ config(
    materialized='table'
) }}

WITH stg_address AS (
    SELECT 
        location_key,
        country_long,
        region,
        city
    FROM {{ ref('stg_dim_address') }}
),

final AS (
    SELECT 
        COALESCE(location_key, -1) AS location_key,
        COALESCE(MAX(country_long), 'undefined') AS country,
        COALESCE(MAX(region), 'undefined') AS region,
        COALESCE(MAX(city), 'undefined') AS city
    FROM stg_address
    GROUP BY 1
)

SELECT * FROM final