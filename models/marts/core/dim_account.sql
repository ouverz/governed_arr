select
    account_id,
    account_name,
    segment,
    region
from {{ ref('stg_salesforce__accounts') }}

