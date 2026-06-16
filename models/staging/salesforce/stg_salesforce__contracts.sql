select
    cast(contract_id as varchar) as contract_id,
    cast(account_id as varchar) as account_id,
    cast(contract_status as varchar) as contract_status,
    cast(start_date as date) as start_date,
    cast(end_date as date) as end_date
from {{ ref('raw_salesforce_contracts') }}
