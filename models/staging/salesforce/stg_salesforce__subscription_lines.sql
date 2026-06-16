select
    cast(subscription_line_id as varchar) as subscription_line_id,
    cast(subscription_id as varchar) as subscription_id,
    cast(product_id as varchar) as product_id,
    cast(prior_subscription_line_id as varchar) as prior_subscription_line_id,
    cast(amendment_action as varchar) as amendment_action,
    cast(line_start_date as date) as line_start_date,
    cast(line_end_date as date) as line_end_date,
    cast(billing_interval_months as integer) as billing_interval_months,
    cast(quantity as decimal(18, 2)) as quantity,
    cast(list_unit_price as decimal(18, 2)) as list_unit_price,
    cast(discount_percent as decimal(18, 2)) as discount_percent,
    cast(net_amount_per_period as decimal(18, 2)) as net_amount_per_period
from {{ source('salesforce_raw', 'subscription_lines') }}
