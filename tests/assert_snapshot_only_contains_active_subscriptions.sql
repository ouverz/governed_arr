select snapshots.*
from {{ ref('fct_arr_snapshot') }} as snapshots
inner join {{ ref('stg_salesforce__subscriptions') }} as subscriptions
    on snapshots.subscription_id = subscriptions.subscription_id
where snapshots.snapshot_date < subscriptions.start_date
    or snapshots.snapshot_date > subscriptions.end_date
