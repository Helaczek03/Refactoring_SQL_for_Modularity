--Import CTEs

with

orders as (
    select *
    from {{ source('jaffle_shop', 'orders') }}
),

customers as (
    select *
    from {{ source('jaffle_shop', 'customers') }}
),

payments as (
    select *
    from {{ source('stripe', 'payment') }}
),

-- Logical CTEs
completed_payments as (
    select 
        orderid as order_id,
        max(created) as payment_finalized_date,
        sum(amount) / 100.0 as total_amount_paid
    from
        payments
    where 
        status <> 'fail'
    group by 1
),

paid_orders as (
    select 
        orders.id as order_id,
        orders.user_id    as customer_id,
        orders.order_date as order_placed_at,
        orders.status as order_status,
        p.total_amount_paid,
        p.payment_finalized_date,
        c.first_name    as customer_first_name,
        c.last_name as customer_last_name
    from
        orders
    left join completed_payments p 
        on orders.id = p.order_id
    left join customers c 
        on orders.user_id = c.id ),

final as (
    select
        p.*,
        row_number() over (order by p.order_id) as transaction_seq,
        row_number() over (partition by customer_id order by p.order_id) as customer_sales_seq,
        
        --new vs returning customer
        case
            when (
                rank() over (
                    partition by customer_id
                    order by order_placed_at, order_id
                ) = 1
            ) then 'new'
            else 'return' 
        end as nvsr,
        x.clv_bad as customer_lifetime_value,

        --first day of sale
        first_value(paid_orders.order_placed_at) over(
            partition by paid_orders.customer_id
            order by paid_orders.order_placed_at
        ) as fdos
    from 
        paid_orders p
        left outer join(
            select
                p.order_id,
                sum(t2.total_amount_paid) as clv_bad
            from 
                paid_orders p
            left join paid_orders t2 
                on p.customer_id = t2.customer_id 
                and p.order_id >= t2.order_id
            group by 1
            order by p.order_id
        ) x 
    on x.order_id = p.order_id
    order by order_id)

select * from final

-- created import CTEs, Logical CTEs, final CTE
-- changed aliases to fullnames