{{ config(
    materialized='table'
) }}

SELECT 
    COALESCE(customer_key, -1) AS customer_key,
    COALESCE(email_address, 'undefined') AS email_address,
    COALESCE(user_agent, 'undefined') AS user_agent,
    COALESCE(resolution, 'undefined') AS resolution,
    COALESCE(device_id, 'undefined') AS device_id
FROM {{ ref('stg_dim_customer') }}