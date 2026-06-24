# ARR Semantic Layer Lab

A minimal, production-shaped ARR metric product with governed definitions,
repeatable validation, and a clear operating model from raw inputs to
consumable metrics.

This repository demonstrates one certified business metric, Ending ARR,
implemented as a governed data product rather than a loose analytics demo.
The local MVP uses DuckDB for reproducible validation and includes the
Snowflake deployment path as part of the operating model, not as an afterthought.

## What this project proves

- one metric can be defined explicitly and certified end to end;
- business rules can be owned, versioned, tested, and reviewed;
- public marts can be protected with contracts;
- semantic consumption can sit on top of governed definitions; and
- CI/CD can validate the pipeline before deployment.

## What this project does not claim

- it is not a full finance system;
- it is not a live production ingestion pipeline in the local lab;
- it does not prove a hosted dbt Semantic Layer query path locally; and
- it is intentionally scoped to one metric, not a broad analytics platform.

## Portfolio Highlights

- One governed metric, Ending ARR, defined end to end.
- Real ARR edge cases: billing intervals, discounts, exclusions, churn, reactivation, and renewals.
- A documented metric contract, singular business tests, and model/unit tests that prove the logic.
- A governed consumption story that distinguishes certified BI and AI reuse from raw-table interpretation.
- A reproducible local build that reviewers can run with Docker only.

## Pattern borrowed from mature revenue stacks

The project follows a pattern used by stronger revenue analytics teams: keep raw inputs separate, derive historical truth with effective dates, and expose a clean consumption layer on top. In practice that means the ARR logic is anchored in point-in-time snapshot facts rather than current-state rows, so month-end truth stays stable and explainable. The same separation also makes it easier to publish a certified dataset for BI or semantic consumption without asking downstream users to interpret raw source tables directly.

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

## Public Assets

- [`docs/shareable/portfolio-case-study.html`](docs/shareable/portfolio-case-study.html) as the primary visual case-study page.
- [`docs/shareable/blog-draft.md`](docs/shareable/blog-draft.md) as the long-form publication draft.
- [`docs/shareable/linkedin-draft.md`](docs/shareable/linkedin-draft.md) as the short announcement draft.
