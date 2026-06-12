# MVP Demo Runbook

## Prerequisites

- Docker Desktop or another Docker daemon
- Docker Compose v2

No host Python, dbt installation, or Snowflake account is required for the
local MVP.

## Clean Build

```bash
docker compose build
docker compose run --rm dbt clean
docker compose run --rm dbt build
docker compose run --rm --entrypoint python dbt scripts/query_results.py
```

The build must complete without warnings or failures. The final query must
return:

```text
2025-01-31 | 19560.00
2025-02-28 | 21960.00
2025-03-31 | 30600.00
2025-04-30 | 30240.00
2025-05-31 | 25320.00
2025-06-30 | 25320.00
```

## Validate the dbt Semantic Contract

Run the local executable validation:

```bash
make semantic-validate
```

This checks that the parsed dbt semantic measure:

- is non-additive across `snapshot_date`;
- selects the latest snapshot in the queried time range;
- reconciles monthly mart totals to the expected-result fixture; and
- resolves the latest local snapshot to `25,320.00`, rather than the invalid
  all-snapshot sum of `153,000.00`.

This is an executable structural and data-contract gate, not a live dbt
Semantic Layer query. The pinned dbt Core image does not include a local
semantic query engine or `dbt sl`/MetricFlow CLI. Before claiming live dbt
Semantic Layer certification, execute the `ending_arr` metric through a
credentialed dbt Semantic Layer environment and reconcile its results to the
same expected totals.

## Generate dbt Documentation

Generate the static dbt documentation artifacts:

```bash
docker compose run --rm dbt docs generate
```

Serve them from the container:

```bash
docker compose run --rm --service-ports dbt docs serve --host 0.0.0.0 --port 8080
```

Open `http://localhost:8080`. Stop the server with `Ctrl-C`.

## Inspect the Local DuckDB Deployment

The local database is persisted at `data/arr_lab.duckdb`. Run the prepared
inspection report:

```bash
docker compose run --rm --entrypoint python dbt scripts/inspect_duckdb.py
```

It displays deployed objects, certified fact rows, monthly totals, and excluded
lines retained in the auditable intermediate model.

For a focused query, use Python and DuckDB inside the container:

```bash
docker compose run --rm --entrypoint python dbt -c \
  "import duckdb; print(duckdb.connect('data/arr_lab.duckdb', read_only=True).sql('select * from main_marts.fct_arr_snapshot order by snapshot_date').fetchall())"
```

## Snowflake Deployment

For GitHub Actions setup, isolated development deployment, and the
approval-gated production workflow, see `docs/ci_cd.md`.

The Docker image contains both `dbt-duckdb` and `dbt-snowflake`. The ignored
local `profiles.yml` and committed `profiles.example.yml` define:

- `dev`: local DuckDB, used by default;
- `snowflake_dev`: isolated Snowflake development or CI, selected with
  `--target snowflake_dev`;
- `prod`: Snowflake, selected with `--target prod`.

Create a local environment file:

```bash
cp .env.example .env
```

Populate `.env` with the Snowflake connection values. `.env` is git-ignored,
but plaintext passwords are only appropriate for local development. Use a
secret manager or key-pair authentication for production automation.
Set `SNOWFLAKE_SCHEMA` to a unique development or CI schema prefix, such as
`DBT_JDOE` or `DBT_PR_123`.

Validate and build in an isolated Snowflake development namespace:

```bash
make debug-snowflake-dev
make build-snowflake-dev
```

For `snowflake_dev`, dbt preserves the target schema prefix. With
`SNOWFLAKE_SCHEMA=DBT_JDOE`, the schemas are `DBT_JDOE_RAW`,
`DBT_JDOE_STAGING`, `DBT_JDOE_INTERMEDIATE`, and `DBT_JDOE_MARTS`.

Validate the explicitly designated production connection:

```bash
docker compose run --rm dbt debug --target prod
```

Deploy seeds, models, tests, and the dbt semantic model:

```bash
docker compose run --rm dbt seed --full-refresh --target prod
docker compose run --rm dbt build --target prod
```

The production calendar uses these project variables:

- `arr_prod_history_start_date`: earliest month included when calculating
  opening balances; defaults to `2020-01-01`;
- `arr_prod_reporting_start_date`: earliest month published by
  `fct_arr_movement`; defaults to `2021-01-01`;
- `arr_prod_reporting_end_date`: optional deterministic calendar end; when
  omitted, the time spine advances through `current_date`, producing snapshots
  through the latest completed month-end.

The history start must be earlier than the reporting start. Choose it far
enough back to include every account's prior ARR state. If reliable history
does not exist, load an explicit opening-balance source before certifying ARR
movements.

Override the production range when needed:

```bash
docker compose run --rm dbt build --target prod --vars \
  '{"arr_prod_history_start_date":"2023-01-01","arr_prod_reporting_start_date":"2024-01-01","arr_prod_reporting_end_date":"2026-12-31"}'
```

The local DuckDB fixture deliberately remains fixed from January through June
2025. Its first month assumes a zero opening balance so the expected `new`
movements remain deterministic. The three exact fixture-reconciliation tests
run locally but are disabled for the advancing production calendar. General
grain, relationship, eligibility, active-period, and validity tests continue
to run in production.

Run only the focused dbt unit tests during local model development:

```bash
make unit-test
```

These unit tests inject small branch-specific inputs directly into individual
models. The expected-result seeds remain the broader golden acceptance
datasets that validate the complete local pipeline.

Use `seed --full-refresh` whenever seed columns change; a normal build does not
migrate an existing seed table's schema.

Only the explicitly designated `prod` target deploys custom schemas directly
as `RAW`, `STAGING`, `INTERMEDIATE`, and `MARTS`, so the production certified
mart is:

```text
ARR_LAB.MARTS.FCT_ARR_SNAPSHOT
```

The role must be able to use the database and warehouse, create and use its
target schemas, and create tables and views within them. Do not use the `prod`
target for development or CI: its stable schema names intentionally omit
developer isolation so downstream production objects have predictable names.

## Snowflake Semantic View Execution

After the production dbt build succeeds:

1. Open a Snowsight SQL worksheet with a role that can create semantic views.
2. Execute `snowflake_semantic_views/snowflake_revenue_metrics.sql`.
3. Confirm that its validation query returns the certified monthly totals.
4. Confirm that querying Ending ARR without a date returns the latest snapshot,
   rather than summing all monthly snapshots.
5. Grant approved consumers `SELECT` on
   `ARR_LAB.SEMANTIC.REVENUE_METRICS`.

The semantic view is a separate Snowflake object and is not created by
`dbt build`.
