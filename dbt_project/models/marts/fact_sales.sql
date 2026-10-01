{{ config(materialized='table') }}

-- Grain: one row per order line (row_id).
-- The same product can appear on several lines of one order, so (order_id, product_id) is not unique.
-- Dimension keys are looked up from the dimensions on their natural keys.
-- Left joins: an order line with no matching dimension row keeps a null key and fails the not_null tests
-- instead of silently disappearing.

with order_lines as (

    select *
    from {{ ref('stg_superstore') }}

)

select
    s.row_id,
    s.order_id,

    c.customer_id,
    p.product_key,
    l.location_key,
    od.date_key                     as order_date_key,
    sd.date_key                     as ship_date_key,

    s.ship_mode,
    s.ship_date - s.order_date      as days_to_ship,

    s.sales,
    s.quantity,
    s.discount,
    s.profit

from order_lines s

left join {{ ref('dim_customer') }} c
    on  c.customer_id = s.customer_id

left join {{ ref('dim_product') }} p
    on  p.product_id   = s.product_id
    and p.product_name = s.product_name

left join {{ ref('dim_location') }} l
    on  l.postal_code = s.postal_code
    and l.city        = s.city
    and l.state       = s.state

left join {{ ref('dim_date') }} od
    on  od.full_date = s.order_date

left join {{ ref('dim_date') }} sd
    on  sd.full_date = s.ship_date
