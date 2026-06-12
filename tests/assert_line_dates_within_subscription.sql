select *
from {{ ref('int_subscription_arr_lines') }}
where line_start_date < subscription_start_date
    or line_end_date > subscription_end_date
    or line_start_date > line_end_date
