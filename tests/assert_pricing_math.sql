select *
from {{ ref('stg_salesforce__subscription_lines') }}
where abs(
    net_amount_per_period
    - (quantity * list_unit_price * (1 - discount_percent / 100.0))
) > 0.01
