# ARR Semantic Layer Lab

A production-inspired learning project for building one governed ARR metric end to end with dbt, Snowflake, Metabase, and an AI-facing semantic layer.

The MVP is a Docker-first dbt project. It uses DuckDB locally for a
reproducible build and retains a Snowflake profile example for deployment.

## Quick Start

Prerequisite: a running Docker daemon.

```bash
docker compose build
docker compose run --rm dbt build
docker compose run --rm --entrypoint python dbt scripts/query_results.py
```

Expected certified Ending ARR:

```text
2025-01-31 | 19560.00
2025-02-28 | 21960.00
2025-03-31 | 30600.00
2025-04-30 | 30240.00
2025-05-31 | 25320.00
2025-06-30 | 25320.00
```

Inspect the local deployment:

```bash
make inspect
```

Generate and serve dbt docs at `http://localhost:8080`:

```bash
make docs
make docs-serve
```

Configure `.env` from `.env.example`, then validate and deploy to Snowflake:

```bash
make debug-prod
make build-prod
```

## Documentation

1. [`01_project_plan.md`](01_project_plan.md) for the target architecture.
2. [`02_mvp_plan.md`](02_mvp_plan.md) for the scoped first release and implementation timeline.
3. [`docs/metric_contract_arr.md`](docs/metric_contract_arr.md) for the certified metric contract.
4. [`docs/demo_runbook.md`](docs/demo_runbook.md) for build and demonstration steps.
5. [`snowflake_semantic_views/snowflake_revenue_metrics.sql`](snowflake_semantic_views/snowflake_revenue_metrics.sql) for the native Snowflake semantic view.
6. [`docs/ci_cd.md`](docs/ci_cd.md) for GitHub Actions validation and Snowflake deployment.
