select
    cast(opportunity_id as varchar) as opportunity_id,
    cast(account_id as varchar) as account_id,
    cast(opportunity_type as varchar) as opportunity_type,
    cast(stage_name as varchar) as stage_name,
    cast(close_date as date) as close_date,
    cast(contract_id as varchar) as contract_id
from {{ ref('raw_salesforce_opportunities') }}
