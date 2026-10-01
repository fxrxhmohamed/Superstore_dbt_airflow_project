{{ config(materialized='view') }}

with source as (

    select *
    from {{ source('ods', 'raw_superstore') }}

)

select
    -- ids
    cast(row_id as integer)                     as row_id,
    trim(order_id)                              as order_id,
    trim(customer_id)                           as customer_id,
    trim(product_id)                            as product_id,

    -- dates
    cast(order_date as date)                    as order_date,
    cast(ship_date as date)                     as ship_date,

    -- order
    trim(ship_mode)                             as ship_mode,

    -- customer
    trim(customer_name)                         as customer_name,
    trim(segment)                               as segment,

    -- location (postal codes were read as numbers, restore leading zeros)
    trim(country)                               as country,
    trim(region)                                as region,
    trim(state)                                 as state,
    trim(city)                                  as city,
    lpad(cast(cast(postal_code as integer) as varchar), 5, '0') as postal_code,

    -- product
    trim(category)                              as category,
    trim(sub_category)                          as sub_category,
    trim(product_name)                          as product_name,

    -- measures
    cast(sales as decimal(18, 4))               as sales,
    cast(quantity as integer)                   as quantity,
    cast(discount as decimal(5, 2))             as discount,
    cast(profit as decimal(18, 4))              as profit

from source
