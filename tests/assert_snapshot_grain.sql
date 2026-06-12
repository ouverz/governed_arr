select
    snapshot_date,
    account_id,
    subscription_id,
    product_family,
    count(*) as row_count
from {{ ref('fct_arr_snapshot') }}
group by 1, 2, 3, 4
having count(*) > 1

