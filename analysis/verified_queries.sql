-- Reference mart consumer queries. These compile during dbt build but do not
-- execute, and they do not prove dbt Semantic Layer metric behavior. Consumers
-- aggregate the certified fact and never recreate line eligibility or
-- annualization rules.

-- Ending ARR over time
select
    snapshot_date,
    sum(ending_arr) as ending_arr
from {{ ref('fct_arr_snapshot') }}
group by snapshot_date
order by snapshot_date;

-- Ending ARR by segment
select
    snapshots.snapshot_date,
    accounts.segment,
    sum(snapshots.ending_arr) as ending_arr
from {{ ref('fct_arr_snapshot') }} as snapshots
inner join {{ ref('dim_account') }} as accounts
    on snapshots.account_id = accounts.account_id
group by snapshots.snapshot_date, accounts.segment
order by snapshots.snapshot_date, accounts.segment;

-- Ending ARR by region and product family
select
    snapshots.snapshot_date,
    accounts.region,
    snapshots.product_family,
    sum(snapshots.ending_arr) as ending_arr
from {{ ref('fct_arr_snapshot') }} as snapshots
inner join {{ ref('dim_account') }} as accounts
    on snapshots.account_id = accounts.account_id
group by snapshots.snapshot_date, accounts.region, snapshots.product_family
order by snapshots.snapshot_date, accounts.region, snapshots.product_family;

-- Explainable ARR movements by month and movement type
select
    snapshot_date,
    movement_type,
    sum(movement_amount) as net_arr_movement
from {{ ref('fct_arr_movement') }}
group by snapshot_date, movement_type
order by snapshot_date, movement_type;
