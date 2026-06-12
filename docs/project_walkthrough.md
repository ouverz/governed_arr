# ARR Semantic Layer Lab: Sequential Project Walkthrough

## 1. Executive Summary

This project creates a production-inspired, governed definition of **Ending
Annual Recurring Revenue (Ending ARR)**.

It starts with synthetic Salesforce-style commercial data and ends with:

- a certified month-end ARR fact table;
- an explainable ARR movement fact table;
- dbt semantic metrics for Ending ARR and net ARR movement;
- a Snowflake semantic-view definition for governed BI and AI consumption;
- hand-calculated acceptance fixtures, automated tests, documentation, and a
  repeatable Docker-based build.

The core problem is not simply calculating ARR. The project demonstrates how a
data team can make one important business metric:

- precisely defined;
- calculated in one place;
- historically correct;
- independently verifiable;
- difficult for consumers to misuse; and
- portable from a local learning environment to Snowflake.

The most important design choice was to go deep on one metric rather than build
a broad but weak semantic layer.

---

## 2. What Was Actually Created

### Implemented and locally demonstrable

The repository contains a complete local dbt MVP using DuckDB:

1. Synthetic Salesforce-style source data for accounts, products, contracts,
   opportunities, orders, subscriptions, and subscription lines.
2. Hand-calculated expected results for monthly ARR, account-level ARR, and ARR
   movements.
3. Staging models that standardize raw fields and types.
4. An intermediate model that owns ARR eligibility and annualization.
5. Core date and account dimensions.
6. A certified month-end ARR snapshot fact.
7. An account-level ARR movement fact.
8. dbt semantic models and metrics.
9. Verified consumer SQL queries.
10. A metric contract, demo runbook, tests, and generated dbt catalog artifacts.
11. Docker, Makefile, and profile configuration for repeatable local builds.

### Designed but not proven as live integrations

The repository also contains a Snowflake deployment profile and a native
Snowflake semantic-view SQL definition. These are deployment-ready artifacts,
but this workspace does not prove that they have been executed in a live
Snowflake account.

The following broader target-architecture items remain deferred:

- recognized revenue and Just-On reconciliation;
- a live Metabase dashboard;
- a live constrained AI agent;
- production orchestration beyond the implemented GitHub Actions CI/CD
  foundation;
- row-level security;
- multi-currency and usage-based pricing;
- historical type-2 account dimensions.

This scope boundary is deliberate. Those additions are not required to prove
the correctness and governance of Ending ARR.

---

## 3. The Project's Governing Logic

The certified metric is:

> Annualized recurring revenue active at calendar month-end.

For each eligible active subscription line:

```text
line_arr = net_amount_per_period * 12 / billing_interval_months
```

Ending ARR is then the sum of `line_arr` at this certified grain:

```text
snapshot_date x account_id x subscription_id x product_family
```

The metric excludes:

- one-time fees;
- services;
- credits and tax;
- non-USD subscriptions in the MVP; and
- subscription or line periods that are inactive on the snapshot date.

Ending ARR is explicitly not:

- GAAP or recognized revenue;
- invoiced revenue;
- cash collections; or
- sales pipeline.

That distinction matters because ARR is a point-in-time operating metric, not
an accounting revenue measure.

---

## 4. End-to-End Model Flow

```text
Synthetic Salesforce CSV seeds
        |
        v
Staging views: cleaned names and types
        |
        v
int_subscription_arr_lines
  - joins subscription lines, subscriptions, and products
  - decides eligibility
  - calculates line ARR
  - retains excluded lines for auditability
        |
        +----------------------+
        |                      |
        v                      v
dim_date month ends       dim_account
        |                      |
        v                      |
fct_arr_snapshot <-------------+
  - applies effective dates
  - keeps active lines only
  - aggregates to certified grain
        |
        +----------------------+
        |                      |
        v                      v
fct_arr_movement          sem_arr.yml
  - compares months         - Ending ARR metric
  - classifies changes      - net ARR movement metric
        |                      |
        +-----------+----------+
                    v
       Verified SQL / Snowflake semantic view
```

The architecture intentionally separates:

- **cleaning** in staging;
- **business rules** in intermediate models;
- **business-facing facts** in marts; and
- **approved consumption language** in semantic layers.

This separation makes it easier to identify where a definition should change
and prevents consumers from rebuilding ARR logic differently.

---

## 5. Sequential Build and Review Guide

The sequence below is the most useful order for reviewing, explaining, or
rebuilding the project.

### Milestone 1: Define the Business Problem and Limit the Scope

Start with:

- `01_project_plan.md`
- `02_mvp_plan.md`
- `docs/metric_contract_arr.md`

### What was decided

The project would prove one board-level metric, Ending ARR, end to end.

The initial broader idea included booked ARR, recognized ARR, reconciliation,
Metabase, Snowflake, and AI. The MVP deliberately narrowed this to the minimum
needed to prove:

- a correct definition;
- a trustworthy mart;
- governed semantic consumption; and
- repeatable verification.

### Why this decision was taken

Semantic-layer projects often fail when teams expose many metrics before
agreeing on definitions and ownership. Choosing one metric makes disagreements,
edge cases, and governance requirements visible without hiding them inside a
large implementation.

### How to rationalize it

The project's first deliverable is not SQL. It is an agreed contract. A metric
cannot be certified merely because a query runs.

### Review checkpoint

Confirm that the business definition, grain, approved dimensions, exclusions,
ownership, and invalid uses are explicit before reviewing implementation.

---

### Milestone 2: Convert Ambiguous ARR Language into Explicit Rules

The broad phrase "active recurring revenue" is not executable. The MVP plan
therefore resolves the ambiguous parts:

| Question | Decision |
|---|---|
| When is ARR measured? | Calendar month-end |
| What determines historical activity? | Subscription and line effective dates |
| Which products count? | Product catalog field `is_arr_eligible` |
| Which currencies count? | USD only |
| How are billing intervals compared? | Annualize using `12 / billing_interval_months` |
| How are discounts handled? | Use the stored net amount |
| What is the output grain? | Date, account, subscription, product family |
| Can ARR be negative? | No, not in this MVP |
| Are account segment and region historical? | No, current attributes only |

### Important decision: effective dates over current status

A cancelled or expired subscription can still have been active in a historical
month. Therefore, the snapshot logic uses start and end dates rather than
filtering only to rows whose current status is `active`.

This is essential for historically correct reporting.

### Important decision: the product catalog owns eligibility

The products seed declares whether a product is ARR-eligible:

- Platform recurring: eligible;
- Analytics recurring: eligible;
- Services: ineligible;
- Setup fee: ineligible.

This avoids embedding fragile product-name lists inside the ARR query. It also
gives the business a clear control point for product classification.

### Review checkpoint

Ask whether each rule is a deliberate business decision. If a rule changes,
identify the fixture, intermediate model, tests, and documentation that must
change with it.

---

### Milestone 3: Design Synthetic Data Around Business Edge Cases

Review:

- `seeds/raw_salesforce_accounts.csv`
- `seeds/raw_salesforce_products.csv`
- `seeds/raw_salesforce_subscriptions.csv`
- `seeds/raw_salesforce_subscription_lines.csv`
- the remaining commercial lineage seeds

### What was created

The dataset contains six accounts, nine subscriptions, fourteen subscription
lines, and supporting contract, opportunity, order, and order-line records.

The small dataset is intentionally scenario-rich. It demonstrates:

- monthly, quarterly, and annual billing;
- discounting;
- one-time and services exclusions;
- new business;
- expansion;
- contraction;
- renewal uplift;
- churn;
- reactivation;
- subscriptions beginning mid-period;
- cancelled and expired subscriptions; and
- multiple eligible lines aggregating at the certified grain.

### Why synthetic data was chosen

The standard dbt Jaffle Shop dataset models ecommerce orders, not recurring
contracts. Forcing ARR onto it would teach the wrong domain model.

Synthetic data gives complete control over edge cases and expected answers. It
also avoids access, privacy, and reproducibility problems.

### Key examples to understand

**Acme Systems (`A001`)**

- starts with monthly Platform ARR of `12,000`;
- expands to `18,000` in March;
- contracts to `14,400` in May;
- also has setup and services lines that must never contribute ARR.

**Bright Labs (`A002`)**

- starts with an annual subscription worth `2,400`;
- adds a discounted quarterly Analytics line worth `2,400` ARR;
- renews the original subscription at `2,640`, creating a `240` expansion.

**Core Works (`A003`)**

- starts at discounted ARR of `960`;
- churns after February;
- reactivates in May at `1,080`.

### Important decision: calculate expected answers before implementation

Three acceptance-fixture seeds were created:

- `expected_ending_arr.csv`: company total by month;
- `expected_ending_arr_by_account.csv`: account total by month;
- `expected_arr_movements.csv`: classified account movements.

This prevents the implementation from becoming its own source of truth. The
model must match independently recorded expectations.

### Review checkpoint

Trace every important business rule to at least one source row and one expected
result. A rule with no observable scenario is not meaningfully tested.

---

### Milestone 4: Create a Reproducible dbt Runtime

Review:

- `Dockerfile`
- `compose.yaml`
- `dbt_project.yml`
- `profiles.yml`
- `profiles.example.yml`
- `Makefile`
- `macros/generate_schema_name.sql`

### What was created

The project packages dbt Core, dbt-duckdb, and dbt-snowflake in Docker.

The default `dev` target writes to `data/arr_lab.duckdb`. The `snowflake_dev`
target provides isolated Snowflake development or CI schemas, and the `prod`
target provides stable production schemas.

dbt materialization decisions are:

- seeds in a raw schema;
- staging and intermediate models as views;
- marts as tables.

### Why these decisions were taken

**Docker-first execution** removes dependency on a reviewer's host Python or
dbt installation and makes the demo repeatable.

**DuckDB locally** provides a zero-infrastructure warehouse for development and
review.

**Snowflake as a second target** preserves a path to a production-like
deployment without making cloud access a prerequisite for the MVP.

**Views for transformation layers** keep the small learning project transparent
and easy to inspect. **Tables for marts** represent the intended stable,
consumer-facing objects.

The custom schema macro preserves dbt's normal
`<target_schema>_<custom_schema>` isolation for DuckDB and Snowflake
development or CI. Only the explicitly designated Snowflake `prod` target
lands objects directly in stable `RAW`, `STAGING`, `INTERMEDIATE`, and `MARTS`
schemas because the native production semantic view depends on those names.

### Review checkpoint

Run the clean build in `docs/demo_runbook.md` and confirm that a new reviewer
needs only Docker for the local MVP.

---

### Milestone 5: Standardize Raw Data in Staging

Review:

- `models/staging/salesforce/*.sql`
- `models/staging/salesforce/_salesforce__models.yml`

### What was created

Each source seed has a corresponding staging view. The staging models:

- rename raw fields into consistent analytics names;
- cast identifiers, dates, booleans, integers, and decimals;
- keep one row per source record; and
- avoid ARR business logic.

### Why this layer exists

Staging isolates source-system representation from downstream logic. If a raw
Salesforce field changes type or name, the adjustment belongs here, not in
every mart.

Keeping business logic out of staging also makes the ownership boundary clear:
staging describes what the source says; intermediate models decide what it
means for ARR.

### Review checkpoint

Confirm that staging models are simple projections and type casts. A product
eligibility filter or ARR calculation here would be misplaced.

---

### Milestone 6: Centralize ARR Eligibility and Annualization

Review:

- `models/intermediate/revenue/int_subscription_arr_lines.sql`
- `models/intermediate/revenue/_revenue__models.yml`

### What was created

`int_subscription_arr_lines` is the main business-rule model. It joins:

- subscription lines;
- parent subscriptions; and
- the product catalog.

It returns one auditable row per effective-dated subscription line with:

- commercial and amendment lineage;
- pricing inputs;
- subscription and line dates;
- eligibility status; and
- calculated `line_arr`.

### The key calculation

```sql
lines.net_amount_per_period * 12.0 / lines.billing_interval_months
```

This makes monthly, quarterly, and annual prices comparable:

- monthly `1,000` becomes `12,000` ARR;
- quarterly `600` becomes `2,400` ARR;
- annual `2,400` remains `2,400` ARR.

### Important decision: retain ineligible lines

Ineligible lines are not deleted from the intermediate model. They receive:

```text
is_arr_eligible = false
line_arr = 0
```

This makes exclusions inspectable. A reviewer can see that setup and services
rows existed, were evaluated, and contributed zero.

### Why logic is centralized here

If annualization or eligibility were repeated in marts, dashboards, and AI
queries, each consumer could produce a different result. This model creates one
authoritative calculation boundary.

### Review checkpoint

Use line examples such as `L001`, `L006`, `L008`, `L004`, and `L005` to verify
monthly, annual, quarterly-discounted, one-time, and services behavior.

---

### Milestone 7: Establish the Reporting Calendar and Approved Dimensions

Review:

- `models/marts/core/metricflow_time_spine.sql`
- `models/marts/core/dim_date.sql`
- `models/marts/core/dim_account.sql`

### What was created

For the local DuckDB fixture, the daily time spine covers January 1 through
June 30, 2025. `dim_date` reduces it to six approved month-end snapshot dates.
The Snowflake production target instead uses a configurable history start and
reporting start, and advances through the current date unless an explicit end
date is supplied.

`dim_account` exposes the approved current account attributes:

- name;
- segment; and
- region.

### Why this was done

A snapshot metric needs a deliberate reporting calendar. Using `dim_date`
prevents facts from appearing only in months where source events happened.

The dbt semantic layer also requires a standard time spine for time-aware
metrics.

Movement classification needs more history than the published reporting
window. Production therefore calculates balances from
`arr_prod_history_start_date` but publishes movements only from
`arr_prod_reporting_start_date`. The history start must be earlier so an
existing account is not mislabeled as `new` merely because reporting begins.
The fixed local fixture intentionally assumes a zero opening balance in January
2025.

Current account attributes were accepted for the MVP to keep scope controlled.
This means historical ARR can be re-sliced by an account's current segment or
region; a production implementation may instead require type-2 history.

### Review checkpoint

For the local target, confirm that six dates exist and that they are all
calendar month-ends. For production, confirm that history begins before the
published movement range. Treat current account attributes as an explicit MVP
limitation.

---

### Milestone 8: Build the Certified Ending ARR Snapshot

Review:

- `models/marts/revenue/fct_arr_snapshot.sql`
- the `fct_arr_snapshot` contract in
  `models/marts/revenue/_revenue__models.yml`

### What was created

The snapshot fact:

1. selects eligible line-level ARR;
2. joins it to every approved month-end on which both the subscription and line
   are active;
3. aggregates active line ARR to the certified grain; and
4. enforces the output columns and data types through a dbt model contract.

### Why both subscription and line dates are checked

A subscription can be active while a specific line has not started, has ended,
or has been replaced by an amendment. Checking only the subscription dates
would double-count or mis-time expansions and contractions.

### Why the certified grain was chosen

The grain supports common analysis by date, account, subscription, and product
family while combining multiple eligible lines that belong to the same
business-level slice.

It is detailed enough to explain totals but constrained enough to serve as a
stable fact table.

### Certified results

| Snapshot date | Ending ARR |
|---|---:|
| 2025-01-31 | 19,560.00 |
| 2025-02-28 | 21,960.00 |
| 2025-03-31 | 30,600.00 |
| 2025-04-30 | 30,240.00 |
| 2025-05-31 | 25,320.00 |
| 2025-06-30 | 25,320.00 |

### Worked example: Acme Systems

1. `L001` is active in January and February and annualizes to `12,000`.
2. `L002` replaces it in March and April and annualizes to `18,000`.
3. `L003` replaces it from May and annualizes to `14,400`.
4. Setup line `L004` and services line `L005` remain auditable upstream but are
   excluded from the snapshot.
5. The resulting account history is `12,000 -> 12,000 -> 18,000 -> 18,000 ->
   14,400 -> 14,400`.

### Review checkpoint

Pick one account and manually follow source line dates through the intermediate
model into each month-end fact row. Then confirm the company totals.

---

### Milestone 9: Derive Explainable ARR Movements

Review:

- `models/marts/revenue/fct_arr_movement.sql`
- `seeds/expected_arr_movements.csv`

### What was created

The movement fact compares each account's current month-ending ARR with its
prior month:

```text
movement_amount = ending_arr - beginning_arr
```

It classifies non-zero changes as:

- `new`;
- `expansion`;
- `contraction`;
- `churn`; or
- `reactivation`.

Because this mart feeds semantic consumers, its six-column public interface is
protected by an enforced dbt model contract. dbt validates the declared column
names and data types before materializing the table, so an accidental rename,
extra output column, or incompatible amount type fails the build instead of
silently changing the consumer interface.

The model contract does not replace data tests. It protects the table's
structural interface; the movement unit test, accepted-values test,
relationship test, null tests, and golden reconciliation fixture continue to
protect behavior and data quality.

### Important implementation decisions

The model first creates every account-month combination and fills missing ARR
with zero. Without this step, churn would disappear because an account with no
current fact row could not be compared with the prior month.

It also tracks historical maximum ARR. This distinguishes:

- first-ever positive ARR: `new`;
- positive ARR after previously having ARR and reaching zero: `reactivation`.

Unchanged renewals are omitted because they have no ARR movement. Renewal
uplift is an expansion.

### Why movements are derived from the certified snapshot

Movements should explain changes in the trusted balance, not introduce a second
definition of ARR. Deriving movements downstream guarantees that the movement
amounts reconcile with Ending ARR.

### Review checkpoint

Trace Core Works (`A003`): `960` ARR, then zero and churn in March, then `1,080`
and reactivation in May.

---

### Milestone 10: Add Governed Semantic and Consumer Surfaces

Review:

- `models/semantic/sem_arr.yml`
- `analysis/verified_queries.sql`
- `snowflake_semantic_views/snowflake_revenue_metrics.sql`

### What was created

The dbt semantic configuration exposes:

- the `ending_arr` metric from the snapshot fact;
- the `net_arr_movement` metric from the movement fact;
- an account semantic model joined to both facts through the shared `account`
  entity; and
- time, product-family, account name, current segment, current region, and
  movement concepts.

Reference mart SQL demonstrates how BI or analyst consumers should query the
marts:

- aggregate the certified fact;
- join only approved dimensions; and
- never reproduce eligibility or annualization logic.

The native Snowflake semantic view adds:

- semantic relationships;
- business-friendly names and synonyms;
- certified metrics and dimensions;
- verified questions;
- AI instructions; and
- a non-additive declaration for Ending ARR by reporting date.

### Important decision: mark Ending ARR as non-additive over time

Ending ARR is a balance at a point in time. Summing January ARR and February ARR
does not produce a meaningful business value.

The Snowflake definition therefore instructs consumers to use the latest
snapshot when no date is requested, rather than sum multiple snapshots.

### Important decision: constrain AI consumption

The semantic view explicitly tells AI consumers:

- use only the certified metric for ARR questions;
- do not redefine ARR;
- do not treat ARR as revenue, cash, or pipeline; and
- reject inappropriate requests.

This treats an AI interface as another governed consumer, not as an unrestricted
SQL generator.

### Review checkpoint

Ensure that consumer queries aggregate existing facts and never reference raw
pricing fields or rebuild `line_arr`.

---

### Milestone 11: Protect the Metric with Tests and a Data Catalog

Review at a high level:

- `seeds/schema.yml`
- each layer's `_models.yml`
- `tests/*.sql`
- generated artifacts under `target/`

### Test strategy

The project combines two kinds of dbt tests.

**Structural and contract tests** cover:

- primary identifiers;
- required values;
- accepted statuses and billing intervals;
- relationships between commercial objects;
- model output types and required columns.

**Business-rule and reconciliation tests** cover:

- pricing math;
- annualization;
- exclusions;
- valid effective-date ranges;
- active subscription and line behavior;
- certified fact grain;
- non-negative ARR;
- expected company totals;
- expected account totals; and
- expected movement classifications.

The overall theme is that tests protect the business meaning, not merely SQL
execution.

The hand-calculated expected-result seeds are golden acceptance datasets. They
exercise the complete pipeline and reconcile final company totals, account
totals, and movements over the six-month scenario. Focused dbt unit tests serve
a different purpose: they inject small inputs directly into one model so that
annualization, eligibility, effective-date boundaries, and movement
classification failures can be isolated without rebuilding or reasoning
through the full fixture.

### Data catalog and documentation

Descriptions in the YAML files document seeds, models, important columns,
semantic models, and metrics. `dbt docs generate` creates the browsable lineage
graph and catalog in `target/index.html`.

The catalog makes it possible to move from a metric to its mart, upstream
models, columns, descriptions, and tests.

The latest verified build passes all **139** resources, and the generated
manifest contains two metrics and three semantic models.

### Review checkpoint

Use the catalog for lineage and descriptions, then inspect a few representative
business tests. It is not necessary to read every generic `not_null` test to
understand the design.

---

### Milestone 12: Make the Result Operable and Reviewable

Review:

- `README.md`
- `docs/demo_runbook.md`
- `scripts/query_results.py`
- `scripts/inspect_duckdb.py`

### What was created

The README provides the shortest path to build and inspect the project. The
runbook adds clean-build, documentation, DuckDB inspection, Snowflake
deployment, and semantic-view steps.

The query script prints the certified monthly totals. The inspection script
shows:

- deployed objects;
- certified snapshot rows;
- monthly totals;
- auditable excluded lines; and
- explainable movements.

### Why this matters

A governed metric is incomplete if only its author can demonstrate it. The
runbook and inspection scripts turn the implementation into a reviewable
operating procedure.

### Review checkpoint

Follow the runbook from a clean environment and compare the printed totals with
the expected fixture.

---

## 6. Major Design Decisions and Their Trade-Offs

| Decision | Reason | Trade-off or limitation |
|---|---|---|
| Build one metric deeply | Makes correctness and governance demonstrable | Does not yet cover the wider revenue domain |
| Use synthetic SaaS data | Reproducible and designed around edge cases | Does not expose all messiness of a real Salesforce instance |
| Define expected totals first | Gives an independent acceptance oracle | Fixtures must be deliberately updated when rules change |
| Let product catalog own eligibility | Avoids hard-coded product-name logic | Requires disciplined catalog governance |
| Use effective dates for history | Preserves cancelled/expired historical ARR | Assumes source effective dates are trustworthy |
| Centralize logic in one intermediate model | Prevents consumer calculation drift | Changes to core logic affect all downstream consumers |
| Snapshot only at month-end | Matches the certified reporting cadence | Cannot answer arbitrary daily ARR questions |
| Keep excluded lines with zero ARR | Improves auditability | Intermediate model is broader than the final fact |
| Derive movement from snapshots | Guarantees balance-to-movement consistency | Movement detail is account-level, not line-level attribution |
| Use current account attributes | Keeps MVP simple | Historical segment/region analysis can restate history |
| Support DuckDB and Snowflake | Enables local review and production path | Cross-database SQL behavior still needs deployment testing |
| Mark ARR non-additive over time | Prevents invalid multi-period sums | Consumers must understand point-in-time aggregation |

---

## 7. How to Explain the Project to Others

A concise explanation is:

> We first agreed on exactly what Ending ARR means, including its grain,
> exclusions, dates, and ownership. We then designed synthetic subscription
> scenarios and hand-calculated expected answers before writing the model.
> dbt standardizes the sources, calculates eligibility and annualized line value
> once, expands active lines onto approved month-ends, and aggregates them into
> a certified snapshot fact. A second fact explains month-to-month changes as
> new, expansion, contraction, churn, or reactivation. Tests reconcile the
> output to independent fixtures, and semantic definitions give BI and AI
> consumers governed ways to query the same metric without rebuilding it.

The core rationale is:

> The project treats a metric as a managed product, not merely as a SQL
> expression.

---

## 8. Recommended Step-by-Step Personal Review

Use this sequence when revisiting the project:

1. Read the metric contract and state the definition in your own words.
2. Review the explicit MVP decisions and identify the limitations.
3. Inspect the product catalog and subscription-line scenarios.
4. Manually calculate ARR for representative monthly, quarterly, annual,
   discounted, and excluded lines.
5. Compare your calculations with the expected fixture seeds.
6. Review staging only to understand source standardization.
7. Study `int_subscription_arr_lines` until eligibility and annualization are
   clear.
8. Trace one account through `fct_arr_snapshot`.
9. Trace one churn and one reactivation through `fct_arr_movement`.
10. Review the semantic metric and the non-additive-over-time decision.
11. Review the test themes and generated dbt lineage catalog.
12. Run the demo and explain why each output is trustworthy.

At the end, you should be able to answer:

- What exactly counts as Ending ARR?
- Why are the monthly totals historically correct?
- Where is eligibility decided?
- Where is annualization calculated?
- How are movements derived?
- How do tests prove the result?
- How are consumers prevented from redefining the metric?
- Which limitations are intentional MVP choices?

---

## 9. Known Gaps and Review Notes

1. There is no usable Git history in the current workspace. This walkthrough
   reconstructs the project sequence from the plans, dependency graph, models,
   fixtures, tests, and runbook rather than from commit chronology.
2. Live Snowflake, Metabase, and AI-agent execution are not evidenced locally.
   Their definitions and deployment steps exist, but should be validated in
   their target environments.
3. The fixed January-June 2025 time spine is retained only for the local
   synthetic fixture. Production uses a configurable history and reporting
   range.
4. USD-only logic is intentional. Multi-currency ARR would require explicit FX
   policy, dates, and tests.
5. Account segment and region are current-state attributes, so historical
   slicing can be restated after account changes.
6. The broad project plan still contains an older Snowflake follow-on example
   mentioning totals of `5,760`, `7,560`, and `6,600`. Those are inconsistent
   with the implemented and certified six-month fixtures. The authoritative MVP
   totals are the six values in `expected_ending_arr.csv`, the README, and the
   demo runbook.

---

## 10. Final Assessment

The project successfully demonstrates the operating model for a governed ARR
metric:

- business meaning is approved before modeling;
- expected results are independent from implementation;
- transformations have clear layer responsibilities;
- the certified fact has an explicit grain and contract;
- movements reconcile to the certified balance;
- tests protect both structure and business behavior;
- semantic surfaces constrain downstream use; and
- the local build is reproducible and inspectable.

Its strongest lesson is that trustworthy analytics comes from the combination
of definition, data design, modeling boundaries, tests, ownership, and consumer
controls. The SQL calculation is only one part of that system.
