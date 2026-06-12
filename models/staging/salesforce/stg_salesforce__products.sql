select
    cast(product_id as varchar) as product_id,
    cast(product_name as varchar) as product_name,
    cast(product_family as varchar) as product_family,
    cast(charge_type as varchar) as charge_type,
    cast(is_arr_eligible as boolean) as is_arr_eligible
from {{ ref('raw_salesforce_products') }}
