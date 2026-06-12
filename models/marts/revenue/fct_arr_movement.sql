{% if target.type == 'snowflake' %}
    {% set history_start_date = var('arr_prod_history_start_date') %}
    {% set reporting_start_date = var('arr_prod_reporting_start_date') %}

    {% if history_start_date >= reporting_start_date %}
        {{ exceptions.raise_compiler_error(
            "arr_prod_history_start_date must be earlier than arr_prod_reporting_start_date "
            ~ "so movement classification has a prior-period opening balance."
        ) }}
    {% endif %}
{% else %}
    {% set reporting_start_date = var('arr_fixture_reporting_start_date') %}
{% endif %}

with account_months as (
    select
        dates.snapshot_date,
        accounts.account_id
    from {{ ref('dim_date') }} as dates
    cross join {{ ref('dim_account') }} as accounts
),

arr_by_account as (
    select
        snapshot_date,
        account_id,
        sum(ending_arr) as ending_arr
    from {{ ref('fct_arr_snapshot') }}
    group by 1, 2
),

balances as (
    select
        account_months.snapshot_date,
        account_months.account_id,
        cast(coalesce(arr_by_account.ending_arr, 0) as decimal(18, 2)) as ending_arr
    from account_months
    left join arr_by_account
        on account_months.snapshot_date = arr_by_account.snapshot_date
        and account_months.account_id = arr_by_account.account_id
),

with_history as (
    select
        snapshot_date,
        account_id,
        cast(
            coalesce(
                lag(ending_arr) over (
                    partition by account_id order by snapshot_date
                ),
                0
            ) as decimal(18, 2)
        ) as beginning_arr,
        ending_arr,
        coalesce(
            max(ending_arr) over (
                partition by account_id
                order by snapshot_date
                rows between unbounded preceding and 1 preceding
            ),
            0
        ) as historical_max_arr
    from balances
),

classified as (
    select
        snapshot_date,
        account_id,
        beginning_arr,
        ending_arr,
        cast(ending_arr - beginning_arr as decimal(18, 2)) as movement_amount,
        case
            when beginning_arr = 0 and ending_arr > 0 and historical_max_arr > 0
                then 'reactivation'
            when beginning_arr = 0 and ending_arr > 0
                then 'new'
            when beginning_arr > 0 and ending_arr = 0
                then 'churn'
            when ending_arr > beginning_arr
                then 'expansion'
            when ending_arr < beginning_arr
                then 'contraction'
            else 'no_change'
        end as movement_type
    from with_history
)

select
    snapshot_date,
    account_id,
    beginning_arr,
    ending_arr,
    movement_amount,
    movement_type
from classified
where movement_type <> 'no_change'
    and snapshot_date >= cast('{{ reporting_start_date }}' as date)
