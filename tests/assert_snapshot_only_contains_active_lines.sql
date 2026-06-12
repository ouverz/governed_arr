select snapshots.*
from {{ ref('fct_arr_snapshot') }} as snapshots
left join {{ ref('int_subscription_arr_lines') }} as lines
    on snapshots.account_id = lines.account_id
    and snapshots.subscription_id = lines.subscription_id
    and snapshots.product_family = lines.product_family
    and snapshots.snapshot_date between lines.line_start_date and lines.line_end_date
    and lines.is_arr_eligible
where lines.subscription_line_id is null
