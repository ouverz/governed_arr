with subscription_lines as (
    select * from {{ ref('stg_salesforce__subscription_lines') }}
),

subscriptions as (
    select * from {{ ref('stg_salesforce__subscriptions') }}
),

products as (
    select * from {{ ref('stg_salesforce__products') }}
)

select
    lines.subscription_line_id,
    lines.subscription_id,
    subscriptions.account_id,
    subscriptions.contract_id,
    lines.product_id,
    products.product_name,
    products.product_family,
    products.charge_type,
    lines.prior_subscription_line_id,
    lines.amendment_action,
    lines.line_start_date,
    lines.line_end_date,
    lines.billing_interval_months,
    lines.quantity,
    lines.list_unit_price,
    lines.discount_percent,
    lines.net_amount_per_period,
    subscriptions.subscription_status,
    subscriptions.start_date as subscription_start_date,
    subscriptions.end_date as subscription_end_date,
    subscriptions.currency,
    products.is_arr_eligible and subscriptions.currency = 'EUR' as is_arr_eligible,
    case
        when products.is_arr_eligible and subscriptions.currency = 'EUR'
        then cast(
            lines.net_amount_per_period * 12.0 / lines.billing_interval_months
            as decimal(18, 2)
        )
        else cast(0 as decimal(18, 2))
    end as line_arr
from subscription_lines as lines
inner join subscriptions
    on lines.subscription_id = subscriptions.subscription_id
inner join products
    on lines.product_id = products.product_id
