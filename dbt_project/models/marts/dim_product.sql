{{ config(materialized='table') }}

-- product_id is not unique in the source: some ids carry two different product names.
-- The grain is therefore (product_id, product_name), identified by a surrogate key.

with products as (

    select distinct
        product_id,
        product_name,
        category,
        sub_category
    from {{ ref('stg_superstore') }}

)

select
    md5(product_id || '|' || product_name) as product_key,
    product_id,
    product_name,
    category,
    sub_category
from products
