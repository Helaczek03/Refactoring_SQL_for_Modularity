with 
payments as (
    select *
    from
        {{ ref('stg_stripe__payments') }}
),

total_amount_of_successful_payments as (
    select
        sum(payment_amount) as total_amount_of_successful_payments
    from
        payments
    where
        payment_status = 'success'
)

select * from total_amount_of_successful_payments