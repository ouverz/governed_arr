# dbt Best-Practices Remediation Plan

## Purpose

This plan implements the non-optional findings from
`docs/dbt_best_practices_review.md` one recommendation at a time, from high to
low severity.

Each recommendation is a separate review checkpoint. Do not combine later
recommendations into the current change merely because they touch the same
file. At every checkpoint:

1. inspect the focused diff;
2. parse the DuckDB and Snowflake targets;
3. run the smallest relevant validation;
4. run the full local `dbt build`;
5. record anything that cannot be validated locally; and
6. review the result before starting the next recommendation.

Optional maturity improvements from the review are intentionally excluded.

## Implementation Sequence

### 1. Prevent Ending ARR from being summed across snapshots

**Severity:** High

**Problem:** Ending ARR is a point-in-time balance, but the dbt semantic measure
is currently additive across `snapshot_date`.

**Implementation:**

- Configure `ending_arr` with `snapshot_date` as a non-additive dimension.
- Use the latest snapshot in the queried time range.
- Keep `net_arr_movement` additive across time.

**Acceptance criteria:**

- Both dbt targets parse successfully.
- The generated manifest records `snapshot_date` and `max` for the Ending ARR
  measure's non-additive behavior.
- Existing mart totals and tests remain unchanged.

**Status:** Completed on June 12, 2026

**Verification performed:**

- DuckDB target parsed successfully.
- Snowflake target parsed successfully with placeholder connection values.
- The generated manifest records `snapshot_date`, `window_choice: max`, and no
  additional window groupings for the `ending_arr` measure.
- Full local build passed: `136/136`, with zero warnings or errors.

**Not verified locally:** A live dbt Semantic Layer query returning the latest
snapshot. That executable proof is the subject of recommendation 2.

---

### 2. Make semantic acceptance criteria executable

**Severity:** High

**Problem:** `analysis/verified_queries.sql` compiles but does not execute
during `dbt build`, and it validates marts rather than the dbt semantic metric.

**Implementation:**

- Add an executable validation path for the dbt semantic metric.
- Validate monthly Ending ARR against the certified expected totals.
- Validate an undated Ending ARR query returns the latest snapshot rather than
  the sum of all snapshots.
- Reword direct mart queries so they are not presented as semantic-layer proof.

**Acceptance criteria:**

- A repeatable command executes the semantic validations.
- Semantic monthly totals match the certified expected totals.
- Undated Ending ARR equals `25,320.00`, not the six-month sum of `153,000.00`.
- The validation command and limitations are documented.

**Review note:** The exact execution mechanism depends on available dbt
Semantic Layer tooling and credentials. Do not claim local semantic execution
if only parsing or mart SQL can be run.

**Status:** Local validation implemented; live semantic execution remains open

**Implemented locally:**

- `make semantic-validate` parses the semantic definition and executes
  `scripts/validate_semantic_contract.py`.
- The script verifies the parsed non-additive rule, reconciles monthly mart
  totals to the expected fixture, confirms latest Ending ARR is `25,320.00`,
  and rejects the invalid all-snapshot sum of `153,000.00`.
- Direct mart analyses and MVP documentation no longer claim to prove live dbt
  Semantic Layer behavior.

**Remaining certification gate:** Execute `ending_arr` through a credentialed
dbt Semantic Layer environment and reconcile both monthly and undated results.
The pinned dbt Core image has no local `dbt sl`, `mf`, or MetricFlow query
command, so this cannot be truthfully verified in the local DuckDB workflow.

---

### 3. Separate the local fixture time spine from production time

**Severity:** High for production

**Problem:** The time spine ends on June 30, 2025, so a production deployment
would stop producing snapshots and can misclassify accounts at the history
boundary.

**Implementation:**

- Preserve the fixed January-June 2025 range for deterministic local fixtures.
- Give the Snowflake production target a maintained or configurable calendar
  range.
- Define the history lookback or opening-balance rule required before the first
  reported movement month.
- Document how production operators advance and maintain the reporting range.

**Acceptance criteria:**

- Local certified fixture totals remain unchanged.
- Production-compiled SQL extends beyond June 30, 2025.
- Movement reporting has an explicit history-boundary rule.
- DuckDB and Snowflake targets parse successfully.

**Status:** Completed on June 12, 2026

**Implementation decision:**

- DuckDB targets retain the fixed January-June 2025 fixture and explicitly
  assume a zero opening balance at the first month.
- Snowflake targets calculate snapshots from `arr_prod_history_start_date`,
  publish movements from the later `arr_prod_reporting_start_date`, and advance
  through `current_date` unless `arr_prod_reporting_end_date` is supplied.
- Production compilation fails when history start is not earlier than reporting
  start.
- Exact six-month fixture-reconciliation tests run locally only; production
  retains the general business and data-quality test suite.

**Verification performed:**

- Full DuckDB build passed unchanged: `136/136`, with zero warnings or errors.
- Local semantic-contract validation passed with latest Ending ARR of
  `25,320.00`.
- Snowflake target parsed successfully with placeholder connection values.
- Snowflake compilation with a deterministic end date generated a time spine
  from `2020-01-01` through `2026-12-31`.
- Compiled movement SQL calculates full history and publishes rows from
  `2021-01-01`.
- Snowflake retains `108` tests; only the three exact six-month fixture
  reconciliations are disabled.
- An unsafe configuration with equal history and reporting starts failed
  compilation as intended.

**Residual requirement:** The configured history start must correspond to
source history that actually exists. A longer calendar cannot replace missing
source history; use an explicit opening-balance source when prior subscription
history is unavailable.

---

### 4. Restore Snowflake development and CI schema isolation

**Severity:** High for shared Snowflake development

**Status:** Completed

**Problem:** The custom schema macro discards `target.schema`, causing
developers and CI jobs to build into shared schemas.

**Implementation:**

- Retain dbt's default `<target_schema>_<custom_schema>` behavior outside the
  dedicated production target.
- Allow clean production schemas only for the explicitly designated production
  target.
- Update deployment documentation and native semantic-view prerequisites to
  match the resulting production schema names.

**Acceptance criteria:**

- Development and CI compilation preserve `target.schema`.
- The production target compiles to the intended stable schemas.
- No documented deployment path relies on an ignored `SNOWFLAKE_SCHEMA`.

**Implemented:**

- The schema macro uses clean custom schema names only for the explicitly
  designated Snowflake `prod` target.
- Added a `snowflake_dev` target that uses `SNOWFLAKE_SCHEMA` as an isolation
  prefix and follows dbt's default schema naming behavior.
- Added Make targets and deployment guidance for isolated Snowflake
  development and CI.
- Clarified that the native Snowflake semantic view depends on a `prod` build.

**Verification:**

- An offline `snowflake_dev` parse with
  `SNOWFLAKE_SCHEMA=DBT_ISOLATION_TEST` generated isolated relations including
  `ARR_LAB.DBT_ISOLATION_TEST_raw.raw_salesforce_accounts` and
  `ARR_LAB.DBT_ISOLATION_TEST_marts.fct_arr_snapshot`.
- An offline `prod` parse generated stable relations including
  `ARR_LAB.raw.raw_salesforce_accounts` and
  `ARR_LAB.marts.fct_arr_snapshot`.
- The complete DuckDB build passed all `136` resources with no warnings or
  errors.
- The executable semantic contract validation passed and retained the
  certified latest Ending ARR of `25,320`.

**Residual requirement:** A live Snowflake build was not run because no
Snowflake credentials are available locally. The target profiles and generated
relation names were validated through offline parsing.

---

### 5. Add approved account dimensions to the dbt semantic graph

**Severity:** Medium

**Status:** Completed

**Problem:** The metric contract approves account, segment, and region, but the
dbt semantic graph cannot expose those dimensions.

**Implementation:**

- Add a semantic model backed by `dim_account`.
- Define `account` as its primary entity.
- Expose account name, segment, and region as categorical dimensions.
- Validate joins from ARR snapshot and movement semantic models.

**Acceptance criteria:**

- Both dbt targets parse successfully.
- Semantic queries can group Ending ARR by segment and region.
- Joined totals reconcile to certified totals without duplication.

**Implemented:**

- Added an `account` semantic model backed by `dim_account`, with `account` as
  its primary entity.
- Exposed current account name, segment, and region as categorical dimensions.
- Retained the shared `account` foreign entity on both ARR snapshot and
  movement semantic models.
- Extended the executable semantic validator to inspect the semantic graph and
  reconcile both fact-to-account joins without duplication.

**Verification:**

- DuckDB, Snowflake `prod`, and isolated `snowflake_dev` targets parsed
  successfully.
- The complete DuckDB build passed all `136` resources with no warnings or
  errors and reported three semantic models.
- The semantic validator confirmed all approved account dimensions, both
  semantic join paths, `30` grouped segment/region result rows, and unchanged
  certified snapshot and movement totals after account joins.

**Residual requirement:** This pinned local dbt image has no executable
MetricFlow or dbt Semantic Layer query command. Grouping behavior and
non-duplication are proven through manifest inspection and equivalent DuckDB
queries; a live semantic query remains an environment-level verification.

---

### 6. Define the production `source()` path while retaining local fixtures

**Severity:** Medium for production readiness

**Status:** Deferred in this lab

**Problem:** Synthetic exported Salesforce data is represented as dbt seeds,
which is appropriate locally but not the intended production raw-data pattern.

**Implementation:**

- Keep seeds as deterministic local test inputs.
- Add and document Snowflake source declarations for production raw tables.
- Make staging models select from local seed refs or production sources through
  a clear, maintainable target-aware pattern.
- Add appropriate source-level tests where they replace current seed tests.

**Acceptance criteria:**

- Local builds remain fully reproducible.
- Snowflake compilation shows staging lineage entering through dbt sources.
- Documentation clearly separates fixture inputs from production ingestion.

**Lab decision:** The current case study intentionally models the raw Salesforce
inputs as seeds and keeps `ref()` in staging. Production `source()` modeling is a
follow-on exercise for a live ingestion path, not a defect in the local MVP.

---

### 7. Add focused dbt unit tests for complex ARR logic

**Severity:** Medium

**Status:** Completed

**Problem:** End-to-end data tests are strong, but failures in complex model
logic are not isolated.

**Implementation:**

- Unit test ARR eligibility and annualization.
- Unit test subscription and line effective-date boundaries.
- Unit test new versus reactivation classification.
- Unit test churn caused by a missing current-month fact row.

**Acceptance criteria:**

- Unit tests use small, explicit inputs and expected outputs.
- Each important branch can fail independently of the full seed pipeline.
- The complete local build remains green.

**Implemented:**

- Added a focused unit test for ARR eligibility and monthly/quarterly
  annualization in `int_subscription_arr_lines`.
- Added a focused unit test for subscription and line effective-date boundaries
  in `fct_arr_snapshot`.
- Added a focused unit test for new, expansion, contraction, churn, and
  reactivation classification in `fct_arr_movement`.
- Retained the expected-result seeds as golden end-to-end acceptance datasets
  rather than coupling them into the unit-test fixtures.
- Added `make unit-test` for fast local execution.

**Verification:**

- The focused unit-test selection passed all `3` unit tests.
- The complete DuckDB build passed all `139` resources with no warnings or
  errors, including the three unit tests and existing golden-dataset
  reconciliations.

---

### 8. Enforce a contract on `fct_arr_movement`

**Severity:** Medium

**Status:** Completed

**Problem:** The movement mart is a semantic-facing public interface without an
enforced model contract.

**Implementation:**

- Define the movement mart's stable column data types.
- Enable contract enforcement.
- Confirm the SQL returns types compatible with both DuckDB and Snowflake.

**Acceptance criteria:**

- Contract enforcement succeeds on DuckDB.
- The Snowflake target parses successfully.
- Existing movement reconciliation tests remain green.

**Implemented:**

- Enabled contract enforcement for the semantic-facing `fct_arr_movement`
  mart.
- Declared its stable interface as `snapshot_date` and `account_id`, three
  `decimal(18,2)` ARR amounts, and `movement_type`.
- Documented that the contract protects structural compatibility while tests
  continue to protect business behavior and data quality.

**Verification:**

- The focused movement build passed contract enforcement, its unit test, and
  all adjacent movement data tests.
- The generated manifest records the movement contract as enforced with all
  six declared data types.
- The Snowflake production target parsed successfully.
- The complete DuckDB build passed all `139` resources with no warnings or
  errors, including the golden movement reconciliation.

---

### 9. Align subscription-status documentation with implementation

**Severity:** Low

**Problem:** The written plan lists only `active` and `cancelled`, while the
implementation also accepts `expired`.

**Implementation:**

- Document `expired` as an accepted descriptive status.
- State that effective dates, rather than current status alone, determine
  historical ARR inclusion.
- Check all metric-contract and walkthrough wording for consistency.

**Acceptance criteria:**

- Documentation and accepted-values tests describe the same rule.
- No wording implies that current status alone determines historical ARR.

---

### 10. Document high-value singular business tests

**Severity:** Low

**Status:** Completed

**Problem:** Singular tests are named clearly but the business intent is easier
for reviewers to understand when summarized in one place.

**Implementation:**

- Add concise documentation for the singular tests.
- Emphasize expected-total reconciliation, effective dates, eligibility, and
  fact grain.

**Acceptance criteria:**

- All singular tests have a readable business-intent summary.
- Descriptions explain the protected business behavior without restating SQL.

**Implemented:**

- Added `docs/singular_business_tests.md` as the narrative index for the high-
  value singular tests.
- Grouped the tests by certified totals, eligibility/effective dates, and grain/
  value constraints.
- Linked the catalog from the project walkthrough so reviewers can find it from
  the main review path.

## Deferred

All items listed under **Optional Maturity Improvements** in
`docs/dbt_best_practices_review.md` are deferred for a later review. They are
not part of this implementation sequence.
