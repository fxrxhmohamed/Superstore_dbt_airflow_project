{{ config(materialized='table') }}

-- One row per calendar day, covering full years from the first order to the last shipment.
-- Used twice by fact_sales: as order date and as ship date.

with bounds as (

    select
        date_trunc('year', min(order_date))                            as start_date,
        date_trunc('year', max(ship_date)) + interval 1 year - interval 1 day as end_date
    from {{ ref('stg_superstore') }}

),

days as (

    select cast(unnest(generate_series(start_date, end_date, interval 1 day)) as date) as date_day
    from bounds

)

select
    cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
    date_day                                      as full_date,
    year(date_day)                                as year,
    quarter(date_day)                             as quarter,
    month(date_day)                               as month,
    monthname(date_day)                           as month_name,
    day(date_day)                                 as day_of_month,
    isodow(date_day)                              as day_of_week,
    dayname(date_day)                             as day_name,
    isodow(date_day) in (6, 7)                    as is_weekend
from days
