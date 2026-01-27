{{ config(
    materialized='table'
) }}

WITH raw_base AS (
    SELECT
        SAFE_CAST(cb.order_id AS INT64) AS sales_order_key,
        SAFE_CAST(cb.user_id_db AS INT64) AS customer_key,
        cb.ip, 
        cb.store_id AS store_key,
        cb.current_url, 
        SAFE_CAST(FORMAT_DATE('%Y%m%d', DATE(TIMESTAMP_SECONDS(SAFE_CAST(cb.time_stamp AS INT64)))) AS INT64) AS date_key,
        SAFE_CAST(cart.product_id AS INT64) AS product_key,
        SAFE_CAST(cart.amount AS INT64) AS quantity,
        TRIM(cart.price) AS raw_price_str,
        TRIM(cart.currency) AS raw_currency_symbol
    FROM {{ source('glamira_raw', 'customer_behaviour') }} cb
    CROSS JOIN UNNEST(cb.cart_products) AS cart 
    WHERE cb.collection = 'checkout_success'
      AND cb.current_url NOT LIKE '%stage.glamira%'
      AND cb.current_url LIKE 'http%'
),

standardizing_chars AS (
    SELECT 
        *,
        REPLACE(REPLACE(REPLACE(raw_price_str, "٫", "."), "'", ""), " ", "") AS step1
    FROM raw_base
),

numeric_parsing AS (
    SELECT 
        *,
        CASE 
            WHEN REGEXP_CONTAINS(RIGHT(step1, 3), r'[.,]') THEN 
                REGEXP_REPLACE(LEFT(step1, LENGTH(step1) - 3), r'[^0-9]', '') || '.' || RIGHT(step1, 2)
            WHEN REGEXP_CONTAINS(RIGHT(step1, 4), r'^[.,]') THEN
                REGEXP_REPLACE(LEFT(step1, LENGTH(step1) - 4), r'[^0-9]', '') || '.' || RIGHT(step1, 3)
            ELSE REGEXP_REPLACE(step1, r'[^0-9]', '')
        END AS clean_numeric_str
    FROM standardizing_chars
),

currency_exchange_mapping AS (
    SELECT 
        *,
        SAFE_CAST(clean_numeric_str AS NUMERIC) AS local_unit_price,
        CASE 
            -- Nhóm Bắc Âu dùng chung 'kr' nhưng khác tỷ giá và mã ISO
            WHEN raw_currency_symbol = 'kr' THEN 
                CASE 
                    WHEN current_url LIKE '%glamira.se%' THEN STRUCT(0.095 AS rate, 'SEK' AS code)
                    WHEN current_url LIKE '%glamira.dk%' THEN STRUCT(0.15 AS rate, 'DKK' AS code)
                    WHEN current_url LIKE '%glamira.no%' THEN STRUCT(0.094 AS rate, 'NOK' AS code)
                    ELSE STRUCT(0.10 AS rate, 'SEK' AS code) 
                END
            
            WHEN raw_currency_symbol IN ('£') THEN STRUCT(1.27 AS rate, 'GBP' AS code)
            WHEN raw_currency_symbol IN ('€') THEN STRUCT(1.09 AS rate, 'EUR' AS code)
            WHEN raw_currency_symbol IN ('$', 'USD $', 'USD') THEN STRUCT(1.0 AS rate, 'USD' AS code)
            WHEN raw_currency_symbol IN ('CAD $') THEN STRUCT(0.74 AS rate, 'CAD' AS code)
            WHEN raw_currency_symbol IN ('MXN $') THEN STRUCT(0.059 AS rate, 'MXN' AS code)
            WHEN raw_currency_symbol IN ('Ft') THEN STRUCT(0.0028 AS rate, 'HUF' AS code)
            WHEN raw_currency_symbol IN ('PEN S/.') THEN STRUCT(0.27 AS rate, 'PEN' AS code)
            WHEN raw_currency_symbol IN ('kn') THEN STRUCT(0.14 AS rate, 'HRK' AS code)
            WHEN raw_currency_symbol IN ('лв.') THEN STRUCT(0.56 AS rate, 'BGN' AS code)
            WHEN raw_currency_symbol IN ('zł') THEN STRUCT(0.25 AS rate, 'PLN' AS code)
            WHEN raw_currency_symbol IN ('د.ك.‏') THEN STRUCT(3.25 AS rate, 'KWD' AS code)
            WHEN raw_currency_symbol IN ('₹') THEN STRUCT(0.012 AS rate, 'INR' AS code)
            WHEN raw_currency_symbol IN ('Lei') THEN STRUCT(0.22 AS rate, 'RON' AS code)
            WHEN raw_currency_symbol IN ('₫') THEN STRUCT(0.000041 AS rate, 'VND' AS code)
            WHEN raw_currency_symbol IN ('BOB Bs') THEN STRUCT(0.14 AS rate, 'BOB' AS code)
            WHEN raw_currency_symbol IN ('₱') THEN STRUCT(0.018 AS rate, 'PHP' AS code)
            WHEN raw_currency_symbol IN ('AU $') THEN STRUCT(0.66 AS rate, 'AUD' AS code)
            WHEN raw_currency_symbol IN ('GTQ Q') THEN STRUCT(0.13 AS rate, 'GTQ' AS code)
            WHEN raw_currency_symbol IN ('Kč') THEN STRUCT(0.043 AS rate, 'CZK' AS code)
            WHEN raw_currency_symbol IN ('NZD $') THEN STRUCT(0.61 AS rate, 'NZD' AS code)
            WHEN raw_currency_symbol IN ('UYU') THEN STRUCT(0.026 AS rate, 'UYU' AS code)
            WHEN raw_currency_symbol IN ('COP $') THEN STRUCT(0.00026 AS rate, 'COP' AS code)
            WHEN raw_currency_symbol IN ('R$') THEN STRUCT(0.20 AS rate, 'BRL' AS code)
            WHEN raw_currency_symbol IN ('SGD $') THEN STRUCT(0.74 AS rate, 'SGD' AS code)
            WHEN raw_currency_symbol IN ('₲') THEN STRUCT(0.00014 AS rate, 'PYG' AS code)
            WHEN raw_currency_symbol IN ('₺') THEN STRUCT(0.031 AS rate, 'TRY' AS code)
            WHEN raw_currency_symbol IN ('￥') THEN STRUCT(0.0067 AS rate, 'JPY' AS code)
            WHEN raw_currency_symbol IN ('DOP $') THEN STRUCT(0.017 AS rate, 'DOP' AS code)
            WHEN raw_currency_symbol IN (' din.') THEN STRUCT(0.0093 AS rate, 'RSD' AS code)
            WHEN raw_currency_symbol IN ('CHF') THEN STRUCT(1.13 AS rate, 'CHF' AS code)
            WHEN raw_currency_symbol IN ('HKD $') THEN STRUCT(0.13 AS rate, 'HKD' AS code)
            WHEN raw_currency_symbol IN ('CRC ₡') THEN STRUCT(0.0019 AS rate, 'CRC' AS code)
            WHEN raw_currency_symbol IN ('CLP') THEN STRUCT(0.0011 AS rate, 'CLP' AS code)
            
            WHEN (raw_currency_symbol = '' OR raw_currency_symbol IS NULL) THEN 
                CASE 
                    WHEN current_url LIKE '%glamira.ro%' THEN STRUCT(0.22 AS rate, 'RON' AS code)
                    WHEN current_url LIKE '%glamira.ae%' THEN STRUCT(0.27 AS rate, 'AED' AS code)
                    WHEN current_url LIKE '%glamira.co.za%' THEN STRUCT(0.053 AS rate, 'ZAR' AS code)
                    ELSE STRUCT(1.0 AS rate, 'UNDEFINED' AS code)
                END
            ELSE STRUCT(1.0 AS rate, 'OTHER' AS code)
        END AS conv
    FROM numeric_parsing
),

location_mapping AS (
    SELECT 
        c.*,
        map.location_key AS bill_to_address_key
    FROM currency_exchange_mapping c
    LEFT JOIN `adept-fountain-478902-b3.glamira_raw_ca.map_ip_to_location` map ON c.ip = map.ip
)

SELECT 
    sales_order_key,
    customer_key,
    date_key,
    store_key,
    product_key,
    bill_to_address_key,
    current_url,
    quantity,
    raw_price_str,
    raw_currency_symbol,
    conv.code AS currency_iso_code,
    local_unit_price,
    ROUND(local_unit_price * conv.rate, 2) AS unit_price_usd,
FROM location_mapping