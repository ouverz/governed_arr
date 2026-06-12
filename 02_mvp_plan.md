# ARR Semantic Layer Lab — MVP Plan

## 1. MVP Outcome

Build and demonstrate one governed metric, **Ending ARR**, from synthetic source data through a tested dbt mart and a documented semantic contract.

At the end of the MVP, a reviewer must be able to:

1. run the dbt project from an empty development schema;
2. inspect the source records that contribute to Ending ARR;
3. query Ending ARR by month, segment, region, and product family;
4. verify that ineligible lines and inactive subscriptions are excluded;
5. reconcile the mart and reference consumer queries locally, then obtain the
   same total from a credentialed semantic metric query before claiming live
   semantic-layer certification; and
6. understand the metric owner, definition, limitations, and change process.

The MVP proves metric correctness and governance. It does not prove every planned integration.

## 2. Scope

### Included

- Synthetic SaaS data covering the required ARR edge cases
- dbt project configuration and a Snowflake development profile example
- Salesforce-style source seeds for accounts, products, opportunities,
  contracts, orders, order lines, subscriptions, and subscription lines
- Staging models for each source
- One intermediate model containing effective-dated line-level ARR logic
- `dim_account` and `dim_date`
- Month-end `fct_arr_snapshot` and explainable `fct_arr_movement` marts
- dbt semantic models for `ending_arr` and `net_arr_movement`
- Metric contract and ownership documentation
- dbt schema tests and singular business-rule tests
- Verified SQL queries representing Metabase and AI-agent consumption
- A repeatable build and demo procedure

### Deferred Until After MVP

- Booked ARR derived from Salesforce opportunities and orders
- Just-On revenue schedules and recognized ARR
- Reconciliation mart and variance reasons
- Live Metabase deployment
- Snowflake semantic view
- Live LLM agent
- Multi-currency, usage pricing, and historical account attributes
- Production CI/CD, orchestration, infrastructure as code, and row-level security

These are separate increments because none is required to prove that Ending ARR is correctly defined, modeled, tested, and consumable.

## 3. Metric Contract Decisions

The project plan states the broad definition but leaves several implementation choices open. The MVP uses the following explicit rules.

| Decision | MVP rule |
|---|---|
| Reporting period | Calendar month-end only |
| Snapshot range | Fixed range represented in `dim_date` and synthetic data |
| Active subscription | `start_date <= snapshot_date` and `end_date >= snapshot_date` |
| Status | Only `active` and `cancelled` statuses are accepted; effective dates determine historical inclusion |
| Eligible line | `charge_type = 'recurring'` and product family is not `Services` |
| Annualization | `net_amount_per_period * 12 / billing_interval_months` |
| Discounts | Reflected in `net_amount_per_period` before annualization |
| Credits, tax, one-time fees | Excluded from Ending ARR |
| Currency | USD only |
| Output grain | One row per `snapshot_date × account_id × subscription_id × product_family` |
| Multiple eligible lines at output grain | Aggregated into one row |
| Negative ARR | Not allowed in the MVP fact |
| Account attributes | Current segment and region; no historical type-2 behavior |

### Ending ARR Formula

For every eligible subscription line active on the snapshot date:

```text
line_arr = net_amount_per_period × 12 / billing_interval_months
```

Then:

```text
ending_arr = sum(line_arr)
```

at the declared output grain.

### Required Synthetic Scenarios

The seed data must make each rule observable:

- monthly recurring line annualized by 12;
- annual recurring line not double-annualized;
- quarterly recurring line annualized by 4;
- discounted recurring line using its net amount;
- one-time fee excluded;
- services line excluded;
- subscription beginning during the snapshot range;
- subscription ending during the snapshot range;
- cancelled subscription included before its effective end date and excluded after it;
- two eligible lines aggregating to the same output grain.

Expected totals for every snapshot month must be recorded before model implementation. They become the acceptance fixture.

## 4. Proposed Model Graph

```text
raw_salesforce_accounts
  -> stg_salesforce__accounts
  -> dim_account

raw_salesforce_subscriptions
  -> stg_salesforce__subscriptions
     \
raw_salesforce_subscription_lines
  -> stg_salesforce__subscription_lines
     -> int_subscription_arr_lines
        + dim_date
        -> fct_arr_snapshot
           -> sem_arr / ending_arr
           -> reference mart consumer queries
```

`int_subscription_arr_lines` owns eligibility and annualization logic. `fct_arr_snapshot` owns date expansion and aggregation to the certified grain. Consumer queries must not recreate either rule.

## 5. Deliverables

```text
dbt_project.yml
packages.yml
profiles.example.yml
seeds/
models/
  sources.yml
  staging/
  intermediate/revenue/int_subscription_arr_lines.sql
  marts/core/dim_account.sql
  marts/core/dim_date.sql
  marts/revenue/fct_arr_snapshot.sql
  semantic/sem_arr.yml
tests/
  assert_ending_arr_expected_totals.sql
  assert_ineligible_lines_excluded.sql
  assert_snapshot_grain.sql
analysis/
  verified_queries.sql
docs/
  metric_contract_arr.md
  demo_runbook.md
```

## 6. Acceptance Criteria

The MVP is done only when all of the following pass:

- `dbt seed`, `dbt build`, and `dbt test` complete successfully.
- Every source and model has a description.
- Key fields are tested for `not_null`, `unique`, `relationships`, or accepted values as appropriate.
- `fct_arr_snapshot` has no duplicate rows at its certified grain.
- No fact row has null or negative Ending ARR.
- Actual monthly totals equal the pre-recorded expected totals.
- One-time fees, services, and inactive periods contribute zero ARR.
- Monthly, quarterly, and annual billing intervals annualize correctly.
- The mart and reference consumer queries resolve to the expected monthly
  totals locally. A credentialed semantic metric query must resolve to the same
  totals before live semantic-layer certification.
- A clean-schema demo can be completed from the runbook without undocumented steps.

## 7. Implementation Timeline

Estimate: **8 focused working days for one builder**, assuming Snowflake access and dbt credentials are available on day 1.

| Day | Work | Exit gate |
|---|---|---|
| 1 | Initialize dbt project, profile example, folders, and source contracts | `dbt debug` succeeds and empty project parses |
| 2 | Design synthetic scenarios, calculate expected totals, generate seeds | Seed review confirms every required scenario and expected total |
| 3 | Build and test staging models and dimensions | Source, staging, and dimension tests pass |
| 4 | Implement line eligibility and annualization | Line-level rule tests pass |
| 5 | Implement month-end snapshot fact and grain tests | Mart totals match acceptance fixture |
| 6 | Add semantic model, metric contract, and reference queries | Local contract validation passes; credentialed semantic execution remains an explicit certification gate |
| 7 | Add documentation, ownership, change rules, and demo runbook | Another reader can trace definition to source fields |
| 8 | Run clean-schema build, fix defects, and record demo results | All acceptance criteria pass |

### Checkpoints

- **End of day 2:** approve business rules and expected totals before writing ARR logic.
- **End of day 5:** approve the mart as the certified source before adding consumption surfaces.
- **End of day 8:** MVP go/no-go review against acceptance criteria.

## 8. Follow-On Increments

### Increment 2 — Reconciliation

Add opportunities, revenue schedules, booked ARR, recognized ARR, variance, and explainable variance reasons.

Estimate: 5–7 working days.

### Increment 3 — Consumer Integrations

Deploy the Snowflake semantic view, connect Metabase, and validate dashboard totals against the certified mart.

Estimate: 3–5 working days, excluding access provisioning.

#### Snowflake Semantic View Execution Task

1. Provision `ARR_LAB`, warehouse `TRANSFORMING`, role `TRANSFORMER`, and
   required grants.
2. Configure the Dockerized dbt `prod` target with Snowflake credentials.
3. Run `dbt debug --target prod` and resolve connection or grant failures.
4. Run `dbt build --target prod`; confirm the certified mart exists as
   `ARR_LAB.MARTS.FCT_ARR_SNAPSHOT` and dimensions exist in `ARR_LAB.MARTS`.
5. Execute `snowflake_semantic_views/snowflake_revenue_metrics.sql` in Snowsight.
6. Validate that the semantic view returns the certified monthly totals:
   `$5,760`, `$7,560`, and `$6,600`.
7. Validate that a metric query without `snapshot_date` returns the latest
   snapshot instead of summing snapshots.
8. Grant consumers `SELECT` on `ARR_LAB.SEMANTIC.REVENUE_METRICS` without
   granting access to raw or intermediate schemas.
9. Connect Metabase and Cortex Analyst to the approved semantic object and
   compare their outputs with the certified mart.

Exit gate: Snowflake semantic-view queries, Metabase, and Cortex Analyst return
the same certified Ending ARR totals as the dbt mart, and consumers cannot query
unapproved schemas.

### Increment 4 — Constrained AI Agent

Expose only certified semantic objects, add verified questions, enforce metric-use instructions, and evaluate responses.

Estimate: 3–5 working days.

## 9. Risks and Controls

| Risk | Control |
|---|---|
| Business rules change during implementation | Approve the metric contract and expected totals at the day-2 checkpoint |
| Seed data is too clean to test exclusions | Require every listed synthetic scenario |
| Logic is duplicated in consumers | Keep eligibility and annualization only in intermediate models |
| Semantic total differs from mart | Make total equality an acceptance test |
| Snowflake access delays the build | Resolve credentials before day 1; otherwise timeline starts when access is available |
| MVP expands into reconciliation or live integrations | Treat each deferred area as a separately accepted increment |

## 10. Immediate Build Order

1. Approve or amend the metric contract decisions in section 3.
2. Create the dbt skeleton and connection profile.
3. Define synthetic rows and hand-calculated expected totals.
4. Implement models in dependency order.
5. Add tests alongside each model, not after modeling is complete.
6. Add semantic and consumer surfaces only after the mart is accepted.
