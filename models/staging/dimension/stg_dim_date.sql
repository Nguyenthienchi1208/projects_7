{{ config(
    materialized='view'
) }}

WITH source_data AS (
    SELECT 
        time_stamp
    FROM {{ source('glamira_raw', 'customer_behaviour') }}
    WHERE 
        collection = 'checkout_success'
        AND time_stamp IS NOT NULL
),

date_conversion AS (
    SELECT DISTINCT
        DATE(TIMESTAMP_SECONDS(CAST(time_stamp AS INT64))) AS full_date
    FROM source_data
),

final AS (
    SELECT
        CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
        full_date,
        EXTRACT(YEAR FROM full_date) AS year,
        EXTRACT(MONTH FROM full_date) AS month,
        EXTRACT(DAY FROM full_date) AS day
    FROM date_conversion
)

SELECT * FROM final