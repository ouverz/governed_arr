select
    cast(order_line_id as varchar) as order_line_id,
    cast(order_id as varchar) as order_id,
    cast(product_id as varchar) as product_id,
    cast(subscription_line_id as varchar) as subscription_line_id,
    cast(order_action as varchar) as order_action
from {{ source('salesforce_raw', 'order_lines') }}
