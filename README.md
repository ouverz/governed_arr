# ARR Semantic Layer Lab

A production-inspired learning project for building one governed ARR metric end to end with dbt, Snowflake, Metabase, and an AI-facing semantic layer.

The MVP is a Docker-first dbt project. It uses DuckDB locally for a
reproducible build and retains a Snowflake profile example for deployment.

## Portfolio Highlights

- One governed metric, Ending ARR, defined end to end.
- Real ARR edge cases: billing intervals, discounts, exclusions, churn, reactivation, and renewals.
- A documented metric contract, singular business tests, and model/unit tests that prove the logic.
- A semantic-layer story that distinguishes certified BI consumption from AI consumption.
- A reproducible local build that reviewers can run with Docker only.

## What is intentionally deferred

This repo is scoped as a lab rather than a full production platform.
Deferred items include live Metabase dashboards, live Snowflake semantic execution in this workspace, recognized ARR reconciliation, production orchestration, row-level security, multi-currency, usage-based pricing, and historical type-2 account dimensions.

That boundary is deliberate: it keeps the case study focused on proving one metric deeply instead of spreading effort across too many unfinished surfaces.

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
4. [`docs/singular_business_tests.md`](docs/singular_business_tests.md) for the human-readable test catalog.
5. [`docs/project_walkthrough.md`](docs/project_walkthrough.md) for the step-by-step implementation story.
6. [`docs/demo_runbook.md`](docs/demo_runbook.md) for build and demonstration steps.
7. [`docs/dbt_best_practices_review.md`](docs/dbt_best_practices_review.md) for the architectural critique and open maturity gaps.
8. [`docs/dbt_remediation_plan.md`](docs/dbt_remediation_plan.md) for the implemented hardening sequence.
9. [`snowflake_semantic_views/snowflake_revenue_metrics.sql`](snowflake_semantic_views/snowflake_revenue_metrics.sql) for the native Snowflake semantic view.
10. [`docs/ci_cd.md`](docs/ci_cd.md) for GitHub Actions validation and Snowflake deployment.

## Shareable Drafts

- [`docs/shareable/blog-draft.md`](docs/shareable/blog-draft.md) for a longer portfolio blog post.
- [`docs/shareable/linkedin-draft.md`](docs/shareable/linkedin-draft.md) for a short announcement post.
