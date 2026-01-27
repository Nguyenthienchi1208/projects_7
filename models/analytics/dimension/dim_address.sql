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
        location_key,
        MAX(country_long) AS country,
        MAX(region) AS region,
        MAX(city) AS city
    FROM stg_address
    GROUP BY 1
)

SELECT * FROM final