{{ config(enabled=target.type != 'snowflake') }}

with actual as (
    select * from {{ ref('fct_arr_movement') }}
),

expected as (
    select
        cast(snapshot_date as date) as snapshot_date,
        cast(account_id as varchar) as account_id,
        cast(beginning_arr as decimal(18, 2)) as beginning_arr,
        cast(ending_arr as decimal(18, 2)) as ending_arr,
        cast(movement_amount as decimal(18, 2)) as movement_amount,
        cast(movement_type as varchar) as movement_type
    from {{ ref('expected_arr_movements') }}
)

select
    coalesce(actual.snapshot_date, expected.snapshot_date) as snapshot_date,
    coalesce(actual.account_id, expected.account_id) as account_id,
    actual.movement_type as actual_movement_type,
    expected.movement_type as expected_movement_type
from actual
full outer join expected
    on actual.snapshot_date = expected.snapshot_date
    and actual.account_id = expected.account_id
where actual.account_id is null
    or expected.account_id is null
    or actual.movement_type <> expected.movement_type
    or abs(actual.beginning_arr - expected.beginning_arr) > 0.01
    or abs(actual.ending_arr - expected.ending_arr) > 0.01
    or abs(actual.movement_amount - expected.movement_amount) > 0.01
