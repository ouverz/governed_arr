# dbt Best-Practices Review

## Review Scope

This review assesses the project against current dbt Labs guidance and
production patterns used by established data teams. It focuses on:

- project layering and naming;
- sources and seeds;
- testing and contracts;
- semantic-layer correctness;
- deployment isolation;
- documentation and maintainability.

The project is a strong learning MVP, but several gaps should be addressed
before describing the dbt semantic layer itself as certified or using the
Snowflake target in a shared development or CI environment.

## Findings

### High: Ending ARR is additive across time in the dbt Semantic Layer

**Location:** `models/semantic/sem_arr.yml:26-30`

The `ending_arr` measure is configured as a plain `sum` without a
`non_additive_dimension`. A query that does not group by `snapshot_date`, or
that spans multiple snapshots, can therefore sum several month-end balances.

That contradicts the metric's point-in-time meaning. The native Snowflake
semantic view handles this correctly by declaring Ending ARR non-additive by
reporting date, but the dbt semantic definition does not.

**Impact:** The dbt Semantic Layer can return a mathematically valid but
business-invalid ARR result.

**Recommendation:** Declare `snapshot_date` as the non-additive dimension for
Ending ARR and add an executable semantic-layer validation showing that an
undated query returns the intended snapshot behavior.

---

### High for production: The reporting time spine ends permanently in June 2025

**Location:** `models/marts/core/metricflow_time_spine.sql:1-12`

The time spine is hardcoded from January 1 through June 30, 2025. Because
`dim_date`, `fct_arr_snapshot`, and `fct_arr_movement` all depend on it, a
Snowflake deployment can never produce a snapshot after June 30, 2025.

The fixed range is appropriate for deterministic MVP fixtures, but it conflicts
with the repository's production-target deployment path.

It also creates a movement-history boundary: an account that existed before the
first available snapshot can be incorrectly classified as `new` because no
opening balance exists.

**Impact:** Production ARR stops advancing after June 2025 and truncated
history can create false new-business movements.

**Recommendation:** Keep a fixed time spine only for the local fixture target.
Use a maintained calendar table or configurable reporting range for production,
and include sufficient pre-period history or an opening balance for movement
classification.

---

### High: The documented semantic acceptance criteria are not executed

**Locations:**

- `02_mvp_plan.md:13`
- `02_mvp_plan.md:161`
- `analysis/verified_queries.sql:1-42`

The plan requires the mart, semantic metric, and verified consumer queries to
return the same totals. However:

- `analysis/verified_queries.sql` is an analysis node, which dbt compiles but
  does not execute during `dbt build`;
- the queries operate directly on marts, not through the dbt Semantic Layer;
- there is no saved query, semantic-layer CLI validation, or automated
  comparison of semantic metric output to the mart.

The existing run artifact records the analysis node as successful because it
compiled, not because its four SQL statements returned correct results.

**Impact:** Mart correctness is well tested, but the claim that the dbt
semantic consumption path is verified is unsupported.

**Recommendation:** Add executable semantic validations or saved queries and
run them in CI. Keep direct mart queries as examples, but do not label them as
proof of semantic-metric equivalence.

---

### High for shared Snowflake development: Custom schemas remove dbt isolation

**Locations:**

- `macros/generate_schema_name.sql:1-7`
- `dbt_project.yml:19-31`

For Snowflake targets, the custom macro returns only the custom schema name,
such as `MARTS`, and discards `target.schema`.

This is the exact schema-generation pattern dbt Labs warns against. If two
developers or CI jobs use Snowflake, they will build into the same `STAGING`,
`INTERMEDIATE`, and `MARTS` schemas and can overwrite one another.

**Impact:** Unsafe developer and CI isolation; the configured
`SNOWFLAKE_SCHEMA` is effectively ignored for models with custom schemas.

**Recommendation:** Preserve target-schema isolation for development and CI.
If clean production schema names are required, make that behavior conditional
on a dedicated production target while retaining the default
`<target_schema>_<custom_schema>` behavior elsewhere.

---

### Medium: Approved account dimensions are absent from the dbt semantic graph

**Locations:**

- `docs/metric_contract_arr.md:49-55`
- `models/semantic/sem_arr.yml:13-18`
- `models/semantic/sem_arr.yml:41-43`

The metric contract approves account, segment, and region. The ARR semantic
models define `account` only as a foreign entity. There is no semantic model
over `dim_account` with `account` as a primary entity and segment/region as
dimensions.

The native Snowflake semantic view includes these relationships and dimensions,
but the dbt Semantic Layer does not.

**Impact:** The dbt metric cannot fulfill the documented requirement to query
Ending ARR by segment and region through the semantic layer.

**Recommendation:** Add an account semantic model backed by `dim_account` and
validate joins from both ARR semantic models.

---

### Medium for production readiness: Raw system tables are represented as seeds, not sources

**Locations:**

- `seeds/raw_salesforce_*.csv`
- `seeds/schema.yml:3-122`
- `models/staging/salesforce/*.sql`

The project intentionally uses small synthetic CSVs, which is reasonable for a
reproducible lab. However, dbt Labs recommends seeds for small, static,
infrequently changing reference data and explicitly identifies exported raw
data as a poor seed use case.

There are no dbt `sources`; the generated manifest contains zero source nodes.
Because the lab models the raw inputs as dbt seeds, staging models correctly
use `ref()` instead of `source()`.

**Impact:** The local lab is reproducible, but its raw-to-staging pattern is a
seed-based lab pattern rather than a warehouse-ingestion pattern.

**Recommendation:** Keep seeds as local synthetic inputs and document the seed
pattern explicitly as the lab architecture. If a future production deployment
adds an external landing zone, introduce `source()` declarations there; until
then, `ref()` is the correct dependency for the raw seed layer.

---

### Medium: Complex business logic has data tests but no dbt unit tests

**Locations:**

- `models/intermediate/revenue/int_subscription_arr_lines.sql:35-43`
- `models/marts/revenue/fct_arr_snapshot.sql:12-34`
- `models/marts/revenue/fct_arr_movement.sql:29-84`

The project has strong data and acceptance tests, but no dbt unit tests.
Movement classification contains window functions and multi-branch case logic,
which dbt Labs specifically identifies as a good unit-testing candidate.

The current seed-based tests validate the whole pipeline after materialization.
They do not isolate a model's logic from upstream data.

**Impact:** Refactoring complex classification or effective-date logic is
slower to diagnose when it fails.

**Recommendation:** Add focused unit tests for:

- ARR annualization and eligibility;
- effective-date boundary behavior;
- new versus reactivation classification;
- churn caused by a missing current-month fact row.

Run unit tests in development and CI, not production.

---

### Medium: Only one of the two semantic-facing marts has a contract

**Location:** `models/marts/revenue/_revenue__models.yml:4-71`

`fct_arr_snapshot` has an enforced model contract. `fct_arr_movement`, which is
also exposed through a semantic model, does not.

**Impact:** Movement columns or data types can change without contract
enforcement even though downstream semantic definitions depend on them.

**Recommendation:** Enforce a contract on `fct_arr_movement` and consider
contracts for other stable public models. Contracts are not necessary for every
staging or intermediate model.

---

### Low: The written contract and accepted subscription statuses disagree

**Locations:**

- `02_mvp_plan.md:58`
- `seeds/schema.yml:61-65`
- `models/staging/salesforce/_salesforce__models.yml:40-44`

The MVP plan says only `active` and `cancelled` statuses are accepted, while
the implementation also accepts `expired`.

Using effective dates and allowing expired records is reasonable, but the
documentation and implementation should state the same rule.

**Recommendation:** Update the contract language to explain that current status
is descriptive and that effective dates determine historical inclusion.

---

### Low: Singular business tests are not documented

**Location:** `tests/*.sql`

The singular tests are well named, but there is no `tests/*.yml` file providing
descriptions for the generated dbt docs catalog.

**Recommendation:** Add concise descriptions for the high-value singular tests,
especially expected-total reconciliation and effective-date tests.

## Optional Maturity Improvements

These are useful for a production project but are not defects in this scoped
lab:

- Add CI that runs parsing, unit tests, modified-state builds, and data tests.
- Add model owners, groups, access levels, and exposures when real consumers
  exist.
- Add contracts and versions only for stable public interfaces, not every
  model.
- Add source freshness when real ingestion timestamps are available.
- Add a SQL formatter/linter and document the chosen style.
- Add saved queries for common semantic consumption paths.
- Add `require-dbt-version` to protect non-Docker execution from incompatible
  dbt versions.
- Mark stable consumer-facing models as public and protect internal layers when
  the project adopts dbt model access controls.
- Plan migration from the current measure-based semantic YAML when adopting
  dbt's newer semantic specification.
- Expand model and column documentation where it materially helps consumers;
  avoid documenting trivial columns merely to increase coverage.

## Practices Already Done Well

- The staging, intermediate, and marts layering follows dbt Labs' recommended
  source-conformed to business-conformed progression.
- Staging models are grouped by source system, named consistently, remain
  one-to-one with inputs, and avoid joins and aggregations.
- Business logic is centralized in a clearly purposed intermediate model.
- Intermediate models are isolated in a dedicated schema and marts are
  materialized as tables.
- The mart grain is explicit and protected by a dedicated test.
- Expected company totals, account totals, and movement classifications are
  independently recorded and reconciled.
- Tests cover business behavior, not only nullability and uniqueness.
- The certified snapshot mart has an enforced contract.
- Documentation clearly distinguishes ARR from revenue, cash, and pipeline.
- Docker and DuckDB make the learning MVP reproducible.

## Recommended Remediation Order

1. Fix dbt Semantic Layer non-additivity for Ending ARR.
2. Replace or parameterize the production time spine.
3. Add the missing account semantic model and executable semantic validations.
4. Make Snowflake schema generation safe for development and CI.
5. Add dbt unit tests around movement and effective-date logic.
6. Contract `fct_arr_movement`.
7. Clarify the lab-only seed pattern and design the production `source()` path.
8. Resolve documentation inconsistencies and add singular-test descriptions.

## Verification Performed

- An independent dbt-focused reviewer ran a fresh DuckDB build: **136/136
  passed**, with no warnings or errors.
- The independent reviewer successfully parsed the Snowflake target.
- Existing generated artifacts previously recorded 137 successful results; the
  one-result difference likely reflects command or resource selection rather
  than a reported failure.
- Snowflake execution and native semantic-view creation were not run.

## References

- dbt Labs, [How we structure our dbt projects](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)
- dbt Labs, [Staging: Preparing our atomic building blocks](https://docs.getdbt.com/best-practices/how-we-structure/2-staging)
- dbt Labs, [Intermediate: Purpose-built transformation steps](https://docs.getdbt.com/best-practices/how-we-structure/3-intermediate)
- dbt Labs, [Marts: Business-defined entities](https://docs.getdbt.com/best-practices/how-we-structure/4-marts)
- dbt Labs, [Add sources to your DAG](https://docs.getdbt.com/docs/build/sources)
- dbt Labs, [Add seeds to your DAG](https://docs.getdbt.com/docs/build/seeds)
- dbt Labs, [Unit tests](https://docs.getdbt.com/docs/build/unit-tests)
- dbt Labs, [Data tests](https://docs.getdbt.com/docs/build/data-tests)
- dbt Labs, [Custom schemas](https://docs.getdbt.com/docs/build/custom-schemas)
- dbt Labs, [Semantic models](https://docs.getdbt.com/docs/build/semantic-models)
- dbt Labs, [Entities](https://docs.getdbt.com/docs/build/entities)
- dbt Labs, [Measures](https://docs.getdbt.com/docs/build/measures)
- dbt Labs, [Saved queries](https://docs.getdbt.com/docs/build/saved-queries)
- GitLab Data Team, [dbt Guide](https://handbook.gitlab.com/handbook/enterprise-data/platform/dbt-guide/)
