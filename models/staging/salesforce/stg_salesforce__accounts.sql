select
    cast(account_id as varchar) as account_id,
    cast(account_name as varchar) as account_name,
    cast(segment as varchar) as segment,
    cast(region as varchar) as region
from {{ source('salesforce_raw', 'accounts') }}
