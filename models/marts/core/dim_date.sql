select date_day as snapshot_date
from {{ ref('metricflow_time_spine') }}
where date_day = last_day(date_day)
