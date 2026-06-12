{{ config(enabled=target.type != 'snowflake') }}

with actual as (
    select
        snapshot_date,
        account_id,
        sum(ending_arr) as actual_ending_arr
    from {{ ref('fct_arr_snapshot') }}
    group by 1, 2
),

expected as (
    select
        cast(snapshot_date as date) as snapshot_date,
        cast(account_id as varchar) as account_id,
        cast(expected_ending_arr as decimal(18, 2)) as expected_ending_arr
    from {{ ref('expected_ending_arr_by_account') }}
)

select
    coalesce(actual.snapshot_date, expected.snapshot_date) as snapshot_date,
    coalesce(actual.account_id, expected.account_id) as account_id,
    actual.actual_ending_arr,
    expected.expected_ending_arr
from actual
full outer join expected
    on actual.snapshot_date = expected.snapshot_date
    and actual.account_id = expected.account_id
where actual.actual_ending_arr is null
    or expected.expected_ending_arr is null
    or abs(actual.actual_ending_arr - expected.expected_ending_arr) > 0.01
