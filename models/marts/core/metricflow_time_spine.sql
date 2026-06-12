{% if target.type == 'snowflake' %}
    {% set history_start_date = var('arr_prod_history_start_date') %}
    {% set reporting_start_date = var('arr_prod_reporting_start_date') %}
    {% set reporting_end_date = var('arr_prod_reporting_end_date', none) %}

    {% if reporting_end_date and history_start_date > reporting_end_date %}
        {{ exceptions.raise_compiler_error(
            "arr_prod_history_start_date must not be later than arr_prod_reporting_end_date."
        ) }}
    {% endif %}

    {% if reporting_end_date and reporting_start_date > reporting_end_date %}
        {{ exceptions.raise_compiler_error(
            "arr_prod_reporting_start_date must not be later than arr_prod_reporting_end_date."
        ) }}
    {% endif %}
{% else %}
    {% set history_start_date = var('arr_fixture_history_start_date') %}
    {% set reporting_end_date = var('arr_fixture_reporting_end_date') %}
{% endif %}

with recursive date_spine(date_day) as (
    select cast('{{ history_start_date }}' as date)

    union all

    select cast({{ dbt.dateadd('day', 1, 'date_day') }} as date)
    from date_spine
    where date_day < {% if reporting_end_date %}
        cast('{{ reporting_end_date }}' as date)
    {% else %}
        current_date
    {% endif %}
)

select date_day
from date_spine
