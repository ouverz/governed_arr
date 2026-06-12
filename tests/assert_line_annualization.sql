with expected as (
    select 'L001' as subscription_line_id, cast(12000.00 as decimal(18, 2)) as expected_line_arr
    union all select 'L002', cast(18000.00 as decimal(18, 2))
    union all select 'L003', cast(14400.00 as decimal(18, 2))
    union all select 'L006', cast(2400.00 as decimal(18, 2))
    union all select 'L007', cast(2640.00 as decimal(18, 2))
    union all select 'L008', cast(2400.00 as decimal(18, 2))
    union all select 'L009', cast(960.00 as decimal(18, 2))
    union all select 'L010', cast(1080.00 as decimal(18, 2))
    union all select 'L011', cast(1200.00 as decimal(18, 2))
    union all select 'L012', cast(600.00 as decimal(18, 2))
    union all select 'L013', cast(2400.00 as decimal(18, 2))
    union all select 'L014', cast(3600.00 as decimal(18, 2))
),

actual as (
    select subscription_line_id, line_arr
    from {{ ref('int_subscription_arr_lines') }}
    where is_arr_eligible
)

select
    coalesce(actual.subscription_line_id, expected.subscription_line_id) as subscription_line_id,
    actual.line_arr,
    expected.expected_line_arr
from actual
full outer join expected
    on actual.subscription_line_id = expected.subscription_line_id
where actual.line_arr is null
    or expected.expected_line_arr is null
    or abs(actual.line_arr - expected.expected_line_arr) > 0.01
