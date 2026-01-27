{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        location_key,
        country_long,
        region,
        city
    FROM {{ ref('base_stg_src_raw_ip_location') }}
),

final AS (
    SELECT DISTINCT 
        location_key,
        country_long,
        region,
        city
    FROM source_data
)

SELECT * FROM final