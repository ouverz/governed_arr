# Metric Contract: Ending ARR

## Certification

- **Metric:** Ending ARR
- **Business owner:** RevOps
- **Technical owner:** Data
- **Status:** MVP certified
- **Reporting cadence:** Calendar month-end
- **Currency:** EUR only

## Definition

Ending ARR is annualized recurring revenue active at the end of a reporting
period. It excludes one-time fees, services, credits, tax, and inactive
subscription periods.

The certified output grain is:

```text
snapshot_date × account_id × subscription_id × product_family
```

For every eligible active line:

```text
line_arr = net_amount_per_period × 12 / billing_interval_months
```

Ending ARR is the sum of `line_arr` at the certified grain.

ARR eligibility is owned by the product catalog. Subscription-line effective
dates determine when a product contributes ARR within its parent subscription.

## ARR Movements

`fct_arr_movement` compares account-level Ending ARR between consecutive
month-end snapshots and classifies non-zero changes:

- `new`: first positive ARR for an account;
- `expansion`: positive change for an active account;
- `contraction`: negative change while the account retains ARR;
- `churn`: account ARR falls to zero;
- `reactivation`: ARR returns after a prior churn.

Renewals with unchanged ARR create no movement. Renewal uplift is classified as
expansion.

## Approved Dimensions

- snapshot date
- account
- current segment
- current region
- product family

## Invalid Uses

Do not use Ending ARR as GAAP revenue, invoiced revenue, cash collections,
recognized revenue, or open pipeline.

## Controls

- Eligibility and annualization are defined only in
  `int_subscription_arr_lines`.
- Month-end activity and certified-grain aggregation are defined only in
  `fct_arr_snapshot`.
- Expected monthly totals are hand-calculated in `expected_ending_arr.csv`.
- Account-level totals and movements have separate hand-calculated fixtures.
- dbt tests protect annualization, exclusions, active dates, non-negative
  values, pricing math, commercial lineage, grain, movements, and expected
  totals.

## Change Process

Any definition change requires the current and proposed definition, reason,
expected business impact, effective date, backfill decision, RevOps approval,
Data approval, implementation review, and release notes.
