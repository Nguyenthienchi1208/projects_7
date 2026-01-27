{{ config(
    materialized='table'
) }}

SELECT 
    customer_key,
    email_address,
    user_agent,
    resolution,
    device_id
FROM {{ ref('stg_dim_customer') }}