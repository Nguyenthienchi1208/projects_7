{{ config(
    materialized='table'
) }}

WITH raw_events AS (
    SELECT 
        COALESCE(SAFE_CAST(user_id_db AS INT64), -1) AS customer_key,
        COALESCE(NULLIF(TRIM(email_address), ''), 'undefined') AS email_address,
        DATE(TIMESTAMP_SECONDS(SAFE_CAST(time_stamp AS INT64))) AS event_date
    FROM {{ source('glamira_raw', 'customer_behaviour') }}
),

email_lifecycle AS (
    SELECT 
        customer_key,
        email_address,
        MIN(event_date) AS email_valid_from,
        MAX(event_date) AS email_valid_to
    FROM raw_events
    GROUP BY 1, 2
),

ranked_lifecycle AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY customer_key 
            ORDER BY email_valid_to DESC
        ) AS latest_rank
    FROM email_lifecycle
)

SELECT 
    customer_key,
    email_address,
    email_valid_from,
    email_valid_to, 
    CASE WHEN latest_rank = 1 THEN TRUE ELSE FALSE END AS is_current
FROM ranked_lifecycle

UNION ALL

SELECT 
    -1 AS customer_key,
    'undefined' AS email_address,
    DATE('1900-01-01') AS email_valid_from,
    CAST(NULL AS DATE) AS email_valid_to,
    TRUE AS is_current