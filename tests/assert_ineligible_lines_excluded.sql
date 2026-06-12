select *
from {{ ref('int_subscription_arr_lines') }}
where not is_arr_eligible
    and line_arr <> 0

