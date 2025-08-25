select
    {{ dbt_utils.generate_surrogate_key(['customer_id', 'order_placed_at']) }} as primary_key,
    customer_id,
    order_placed_at,
    count(*) as c
from
    {{ ref('stg_jaffle_shop__orders') }}
group by 2, 3