with eligible_lines as (
    select *
    from {{ ref('int_subscription_arr_lines') }}
    where is_arr_eligible
),

month_ends as (
    select snapshot_date
    from {{ ref('dim_date') }}
),

active_lines as (
    select
        month_ends.snapshot_date,
        eligible_lines.account_id,
        eligible_lines.subscription_id,
        eligible_lines.product_family,
        eligible_lines.line_arr
    from eligible_lines
    inner join month_ends
        on eligible_lines.subscription_start_date <= month_ends.snapshot_date
        and eligible_lines.subscription_end_date >= month_ends.snapshot_date
        and eligible_lines.line_start_date <= month_ends.snapshot_date
        and eligible_lines.line_end_date >= month_ends.snapshot_date
)

select
    snapshot_date,
    account_id,
    subscription_id,
    product_family,
    cast(sum(line_arr) as decimal(18, 2)) as ending_arr
from active_lines
group by 1, 2, 3, 4
