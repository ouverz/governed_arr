# ARR Semantic Layer Lab — Project Plan

This document describes the target architecture and full project direction. See
[`02_mvp_plan.md`](02_mvp_plan.md) for the scoped first release, acceptance
criteria, and implementation timeline.

## 1. Purpose

This project is a hands-on exercise to internalize how a modern data team would build one certified revenue metric end to end.

The goal is not to build a complete enterprise data platform. The goal is to prove the operating model for one board-level metric: **Ending ARR**.

The project should mimic a real production environment:

- raw source systems
- dbt staging, intermediate, mart, and semantic layers
- Snowflake as the warehouse
- Metabase as the BI consumer
- an AI-facing semantic surface
- tests, documentation, ownership, and change control

## 2. Design Principle

Start with one metric in depth.

Do not build a semantic universe. Build one certified ARR metric that can be consumed consistently by:

- a dbt mart
- a dbt semantic model
- a Snowflake semantic view
- Metabase dashboards
- a constrained LLM agent

## 3. Dataset Strategy

### Recommendation

Use a **synthetic SaaS revenue dataset created specifically for this project**, rather than plain Jaffle Shop.

Jaffle Shop is useful for learning dbt mechanics, but it is an ecommerce dataset. It does not naturally contain subscriptions, contract periods, booked ARR, recognized revenue, subscription lines, renewals, expansions, contractions, or churn.

A better learning dataset should include:

- accounts
- opportunities
- subscriptions
- subscription lines
- invoices or revenue schedules
- products
- users/events later, if Product usage is added

### Why not use Jaffle Shop directly?

Jaffle Shop is an excellent dbt sandbox, but it models customers and orders. ARR requires recurring contracts and time-based revenue. If we force ARR onto ecommerce orders, the exercise becomes artificial.

### Proposed approach

Create a local synthetic dataset inspired by a B2B SaaS company:

```text
raw_salesforce_accounts.csv
raw_salesforce_products.csv
raw_salesforce_opportunities.csv
raw_salesforce_contracts.csv
raw_salesforce_orders.csv
raw_salesforce_order_lines.csv
raw_salesforce_subscriptions.csv
raw_salesforce_subscription_lines.csv
raw_juston_revenue_schedules.csv   # reconciliation phase
raw_product_usage_events.csv       # optional later
```

This gives us full control over edge cases:

- booked ARR differs from recognized ARR
- one-time fees excluded from ARR
- services excluded from ARR
- discounts and credits
- expansions
- contractions
- churn
- paused subscriptions
- multi-currency later if desired

## 4. Business Scenario

The company has two revenue views:

1. **Salesforce booked ARR**
   - Based on closed-won opportunities and subscription contracts.
   - Used by Sales and RevOps.

2. **Just-On recognized ARR / revenue schedule**
   - Based on billing and recognition schedules.
   - Used by Finance.

Today these reconcile by hand.

The project should make the difference visible by producing:

- Booked ARR
- Recognized ARR
- Variance
- Variance reason
- Certified Board ARR

## 5. Target Metric

### Certified Metric

**Ending ARR**

### Definition

Annualized recurring revenue active at the end of a reporting period, excluding one-time fees, services, credits, tax, and inactive subscriptions.

### Grain

One row per:

```text
snapshot_date × account_id × subscription_id × product_family
```

### Valid dimensions

- snapshot date
- account
- segment
- region
- product family

### Invalid uses

Ending ARR must not be used as:

- GAAP revenue
- invoiced revenue
- cash collections
- open pipeline
- recognized revenue

## 6. Project Folder Structure

```text
arr-semantic-layer-lab/
  README.md
  dbt_project.yml
  packages.yml
  profiles.example.yml

  seeds/
    raw_salesforce_accounts.csv
    raw_salesforce_products.csv
    raw_salesforce_opportunities.csv
    raw_salesforce_contracts.csv
    raw_salesforce_orders.csv
    raw_salesforce_order_lines.csv
    raw_salesforce_subscriptions.csv
    raw_salesforce_subscription_lines.csv
    expected_ending_arr.csv
    expected_ending_arr_by_account.csv
    expected_arr_movements.csv
    raw_juston_revenue_schedules.csv  # reconciliation phase

  models/
    staging/
      salesforce/
        stg_salesforce__accounts.sql
        stg_salesforce__products.sql
        stg_salesforce__opportunities.sql
        stg_salesforce__contracts.sql
        stg_salesforce__orders.sql
        stg_salesforce__order_lines.sql
        stg_salesforce__subscriptions.sql
        stg_salesforce__subscription_lines.sql
      juston/  # reconciliation phase
        stg_juston__revenue_schedules.sql

    intermediate/
      revenue/
        int_subscription_arr_lines.sql
        int_arr_recognition_months.sql  # reconciliation phase
        int_arr_reconciliation.sql      # reconciliation phase

    marts/
      core/
        dim_account.sql
        dim_date.sql
      revenue/
        fct_arr_snapshot.sql
        fct_arr_movement.sql
        fct_arr_reconciliation.sql  # reconciliation phase

    semantic/
      sem_arr.yml

  semantic_views/
    snowflake_revenue_metrics.sql

  metabase/
    dashboard_spec.md
    questions.md

  docs/
    01_project_plan.md
    02_metric_contract_arr.md
    03_revops_data_working_agreement.md
    04_governance_and_ci.md

  scripts/
    generate_seed_data.py
```

## 7. dbt Layering

### Raw / Seeds

For the delivered MVP, CSV seeds stand in for Fivetran-loaded raw Salesforce tables.
Just-On seeds and models are reserved for the later reconciliation phase.

In a production-like Snowflake setup, these would land in schemas such as:

```text
RAW_SALESFORCE
RAW_JUSTON
```

### Staging

Staging models clean names and types only.

Rules:

- no business logic
- no joins except light deduplication if needed
- one staging model per source table
- source columns renamed into analytics-friendly names

Example:

```text
raw_salesforce_subscriptions
→ stg_salesforce__subscriptions
```

### Intermediate

Intermediate models encode business logic.

Examples:

- annualization logic
- exclusion of services and one-time fees
- subscription status rules
- effective-dated subscription-line logic
- ARR movement classification
- booked ARR vs recognized ARR comparison in the reconciliation phase

### Mart

Marts are business-facing tables.

Primary marts:

- `fct_arr_snapshot`
- `fct_arr_movement`
- `dim_account`
- `dim_date`

The reconciliation phase adds `fct_arr_reconciliation`.

### Semantic Layer

The dbt semantic model defines:

- entities
- dimensions
- measures
- metrics
- descriptions
- valid uses

Snowflake semantic views expose the AI-friendly serving surface with:

- synonyms
- comments
- verified queries
- AI instructions

## 8. Snowflake Design

Suggested schemas:

```text
ARR_LAB.RAW
ARR_LAB.STAGING
ARR_LAB.INTERMEDIATE
ARR_LAB.MARTS
ARR_LAB.SEMANTIC
```

Suggested warehouses:

```text
TRANSFORMING
ARR_LAB_BI_WH
ARR_LAB_AGENT_WH
```

The lab can start with one small warehouse, but the design should document separation of concerns.

## 9. Metabase Exposure

Metabase should consume mart or semantic objects, not raw source tables.

Initial dashboard:

- Ending ARR over time
- Ending ARR by segment
- Ending ARR by region
- Ending ARR by product family
- Booked vs recognized ARR variance
- Top accounts by Ending ARR

Metabase may define a visible metric, but it must not become the source of truth for ARR logic.

## 10. AI Agent Exposure

The AI agent should only access approved semantic objects.

Allowed:

```text
semantic.revenue_metrics
fct_arr_snapshot
fct_arr_movement
```

The reconciliation phase also allows `fct_arr_reconciliation`.

Not allowed:

```text
raw Salesforce tables
raw Just-On tables
intermediate models
ad hoc SQL definitions of ARR
```

Agent instructions:

- Use only certified metrics.
- Do not redefine ARR.
- Do not use opportunity amount as ARR.
- Do not use recognized revenue as ARR unless explicitly asked.
- Include the ARR definition in answers.
- Ask for clarification if the requested metric is not certified.

## 11. Governance Workflow

### Ownership

RevOps owns:

- business definition
- inclusions and exclusions
- certification of ARR
- board reporting acceptance

Data owns:

- dbt implementation
- tests
- lineage
- documentation
- semantic exposure
- deployment process

### Change process

Any ARR definition change requires:

1. current definition
2. proposed definition
3. reason for change
4. expected business impact
5. effective date
6. backfill decision
7. RevOps approval
8. Data approval
9. implementation PR
10. release notes

## 12. Minimum dbt Tests

Required tests:

- primary keys not null
- primary keys unique where appropriate
- relationships between facts and dimensions
- accepted values for subscription status
- ARR amount non-negative unless explicitly modeling credits
- no duplicate account/subscription/product rows per snapshot date
- reconciliation variance is explainable

Revenue-specific checks:

- one-time fees excluded from Ending ARR
- services excluded from Ending ARR
- inactive subscriptions excluded
- monthly contracts annualized correctly
- annual contracts not double annualized

## 13. Implementation Milestones

### Milestone 1 — Skeleton

- project folder
- dbt project initialized
- seed files generated
- staging models built

### Milestone 2 — ARR Logic

- intermediate ARR line model
- month-end snapshot mart
- dbt tests
- documentation

### Milestone 3 — Reconciliation

- booked ARR
- recognized ARR
- variance mart
- variance reasons

### Milestone 4 — Semantic Layer

- dbt semantic model
- Snowflake semantic view SQL
- metric contract documentation

### Milestone 5 — BI + Agent Simulation

- Metabase dashboard spec
- example SQL questions
- LLM agent prompt/instructions
- verified queries

## 14. Definition of Done

The project is complete when the same ARR number can be retrieved from:

- dbt mart SQL
- dbt semantic metric definition
- Snowflake semantic view
- Metabase dashboard spec
- simulated AI agent query

And the project documents:

- who owns the metric
- what the metric means
- what is excluded
- what tests protect it
- how the definition can change

## 15. Opinionated Scope Cuts

Defer:

- full product analytics
- predictive churn
- full ingestion orchestration
- Terraform/IaC
- enterprise data catalog
- real-time pipelines
- full reverse ETL
- row-level security beyond documented design

Include only enough to mimic production discipline without overwhelming the learning goal.
