{{ config(materialized='table') }}

-- customer_id maps to exactly one name and segment in the source.
-- Location is NOT a customer attribute: most customers order to several addresses,
-- so it lives in dim_location and is linked through the fact table.

select distinct
    customer_id,
    customer_name,
    segment
from {{ ref('stg_superstore') }}
