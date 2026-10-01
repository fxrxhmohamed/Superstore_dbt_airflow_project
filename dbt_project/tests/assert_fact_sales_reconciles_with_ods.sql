-- Fails (returns a row) if the fact table lost or duplicated rows or amounts compared to the ODS load.

with ods as (

    select
        count(*)    as row_count,
        sum(sales)  as total_sales,
        sum(profit) as total_profit
    from {{ source('ods', 'raw_superstore') }}

),

dwh as (

    select
        count(*)    as row_count,
        sum(sales)  as total_sales,
        sum(profit) as total_profit
    from {{ ref('fact_sales') }}

)

select *
from ods, dwh
where ods.row_count <> dwh.row_count
   or abs(ods.total_sales - dwh.total_sales) > 0.01
   or abs(ods.total_profit - dwh.total_profit) > 0.01
