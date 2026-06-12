select
    cast(order_id as varchar) as order_id,
    cast(account_id as varchar) as account_id,
    cast(contract_id as varchar) as contract_id,
    cast(opportunity_id as varchar) as opportunity_id,
    cast(subscription_id as varchar) as subscription_id,
    cast(order_type as varchar) as order_type,
    cast(order_status as varchar) as order_status,
    cast(effective_date as date) as effective_date
from {{ ref('raw_salesforce_orders') }}
