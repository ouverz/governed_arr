select *
from {{ ref('fct_arr_snapshot') }}
where ending_arr < 0

