select
    cast(subscription_id as varchar) as subscription_id,
    cast(account_id as varchar) as account_id,
    cast(contract_id as varchar) as contract_id,
    cast(original_subscription_id as varchar) as original_subscription_id,
    cast(renewed_from_subscription_id as varchar) as renewed_from_subscription_id,
    cast(subscription_status as varchar) as subscription_status,
    cast(start_date as date) as start_date,
    cast(end_date as date) as end_date,
    cast(currency as varchar) as currency
from {{ ref('raw_salesforce_subscriptions') }}
