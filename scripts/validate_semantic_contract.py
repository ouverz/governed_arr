import json
from decimal import Decimal
from pathlib import Path

import duckdb


MANIFEST_PATH = Path("target/manifest.json")
DATABASE_PATH = Path("data/arr_lab.duckdb")
SEMANTIC_MODEL_PREFIX = "semantic_model.arr_semantic_layer_lab"
ACCOUNT_MODEL_ID = f"{SEMANTIC_MODEL_PREFIX}.account"
ARR_SNAPSHOT_MODEL_ID = f"{SEMANTIC_MODEL_PREFIX}.arr_snapshot"
ARR_MOVEMENT_MODEL_ID = f"{SEMANTIC_MODEL_PREFIX}.arr_movement"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


with MANIFEST_PATH.open() as manifest_file:
    manifest = json.load(manifest_file)

semantic_models = manifest["semantic_models"]
account_semantic_model = semantic_models[ACCOUNT_MODEL_ID]
arr_snapshot_semantic_model = semantic_models[ARR_SNAPSHOT_MODEL_ID]
arr_movement_semantic_model = semantic_models[ARR_MOVEMENT_MODEL_ID]

account_entity = next(
    entity for entity in account_semantic_model["entities"] if entity["name"] == "account"
)
require(account_entity["type"] == "primary", "Account must be a primary semantic entity.")

account_dimensions = {
    dimension["name"]: dimension for dimension in account_semantic_model["dimensions"]
}
for dimension_name in ("account_name", "segment", "region"):
    require(
        dimension_name in account_dimensions,
        f"Account semantic model must expose {dimension_name}.",
    )
    require(
        account_dimensions[dimension_name]["type"] == "categorical",
        f"Account dimension {dimension_name} must be categorical.",
    )

for semantic_model in (arr_snapshot_semantic_model, arr_movement_semantic_model):
    account_foreign_entity = next(
        entity for entity in semantic_model["entities"] if entity["name"] == "account"
    )
    require(
        account_foreign_entity["type"] == "foreign",
        f"{semantic_model['name']} must join to account through a foreign entity.",
    )

ending_arr_measure = next(
    measure
    for measure in arr_snapshot_semantic_model["measures"]
    if measure["name"] == "ending_arr"
)
non_additive_dimension = ending_arr_measure["non_additive_dimension"]

require(ending_arr_measure["agg"] == "sum", "Ending ARR must sum rows within one snapshot.")
require(
    non_additive_dimension["name"] == "snapshot_date",
    "Ending ARR must be non-additive across snapshot_date.",
)
require(
    non_additive_dimension["window_choice"] == "max",
    "Ending ARR must select the latest snapshot in the queried time range.",
)

with duckdb.connect(str(DATABASE_PATH), read_only=True) as connection:
    mismatches = connection.execute(
        """
        with actual as (
            select snapshot_date, sum(ending_arr) as ending_arr
            from main_marts.fct_arr_snapshot
            group by snapshot_date
        )
        select
            coalesce(actual.snapshot_date, expected.snapshot_date) as snapshot_date,
            actual.ending_arr as actual_ending_arr,
            expected.expected_ending_arr
        from actual
        full outer join main_raw.expected_ending_arr as expected
            on actual.snapshot_date = expected.snapshot_date
        where actual.ending_arr is distinct from expected.expected_ending_arr
        order by snapshot_date
        """
    ).fetchall()
    require(not mismatches, f"Monthly Ending ARR differs from the fixture: {mismatches}")

    dimension_join_mismatches = connection.execute(
        """
        with certified_totals as (
            select snapshot_date, sum(ending_arr) as ending_arr
            from main_marts.fct_arr_snapshot
            group by snapshot_date
        ),
        totals_after_account_join as (
            select snapshot.snapshot_date, sum(snapshot.ending_arr) as ending_arr
            from main_marts.fct_arr_snapshot as snapshot
            inner join main_marts.dim_account as account
                on snapshot.account_id = account.account_id
            group by snapshot.snapshot_date
        )
        select
            coalesce(certified.snapshot_date, joined.snapshot_date) as snapshot_date,
            certified.ending_arr as certified_ending_arr,
            joined.ending_arr as joined_ending_arr
        from certified_totals as certified
        full outer join totals_after_account_join as joined
            on certified.snapshot_date = joined.snapshot_date
        where certified.ending_arr is distinct from joined.ending_arr
        order by snapshot_date
        """
    ).fetchall()
    require(
        not dimension_join_mismatches,
        f"Account dimension join changes certified totals: {dimension_join_mismatches}",
    )

    movement_join_mismatches = connection.execute(
        """
        with certified_totals as (
            select snapshot_date, sum(movement_amount) as movement_amount
            from main_marts.fct_arr_movement
            group by snapshot_date
        ),
        totals_after_account_join as (
            select movement.snapshot_date, sum(movement.movement_amount) as movement_amount
            from main_marts.fct_arr_movement as movement
            inner join main_marts.dim_account as account
                on movement.account_id = account.account_id
            group by movement.snapshot_date
        )
        select
            coalesce(certified.snapshot_date, joined.snapshot_date) as snapshot_date,
            certified.movement_amount as certified_movement_amount,
            joined.movement_amount as joined_movement_amount
        from certified_totals as certified
        full outer join totals_after_account_join as joined
            on certified.snapshot_date = joined.snapshot_date
        where certified.movement_amount is distinct from joined.movement_amount
        order by snapshot_date
        """
    ).fetchall()
    require(
        not movement_join_mismatches,
        f"Account dimension join changes movement totals: {movement_join_mismatches}",
    )

    account_dimension_rows = connection.execute(
        """
        select
            snapshot.snapshot_date,
            account.segment,
            account.region,
            sum(snapshot.ending_arr) as ending_arr
        from main_marts.fct_arr_snapshot as snapshot
        inner join main_marts.dim_account as account
            on snapshot.account_id = account.account_id
        group by snapshot.snapshot_date, account.segment, account.region
        """
    ).fetchall()
    require(account_dimension_rows, "Account dimensions produced no grouped Ending ARR rows.")

    latest_snapshot_date, latest_ending_arr = connection.execute(
        """
        select snapshot_date, sum(ending_arr) as ending_arr
        from main_marts.fct_arr_snapshot
        where snapshot_date = (select max(snapshot_date) from main_marts.fct_arr_snapshot)
        group by snapshot_date
        """
    ).fetchone()
    expected_latest_date, expected_latest_ending_arr = connection.execute(
        """
        select snapshot_date, expected_ending_arr
        from main_raw.expected_ending_arr
        where snapshot_date = (select max(snapshot_date) from main_raw.expected_ending_arr)
        """
    ).fetchone()
    all_snapshot_sum = connection.execute(
        "select sum(ending_arr) from main_marts.fct_arr_snapshot"
    ).fetchone()[0]

require(latest_snapshot_date == expected_latest_date, "Latest fixture and mart dates differ.")
require(
    Decimal(str(latest_ending_arr)) == Decimal(str(expected_latest_ending_arr)),
    "Latest Ending ARR differs from the expected fixture.",
)
require(
    Decimal(str(latest_ending_arr)) != Decimal(str(all_snapshot_sum)),
    "Latest Ending ARR unexpectedly equals the invalid sum across all snapshots.",
)

print("Semantic contract validation passed.")
print(f"Validated account dimension groups: {len(account_dimension_rows)}")
print(f"Latest snapshot: {latest_snapshot_date} | {latest_ending_arr:.2f}")
print(f"Rejected all-snapshot sum: {all_snapshot_sum:.2f}")
