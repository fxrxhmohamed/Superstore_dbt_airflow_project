{{ config(materialized='table') }}

-- postal_code alone is not unique (e.g. 92024 covers Encinitas and San Diego),
-- so the grain is (postal_code, city, state), identified by a surrogate key.

with locations as (

    select distinct
        country,
        region,
        state,
        city,
        postal_code
    from {{ ref('stg_superstore') }}

)

select
    md5(postal_code || '|' || city || '|' || state) as location_key,
    country,
    region,
    state,
    city,
    postal_code
from locations
