# Building One Governed ARR Metric

Most ARR implementations fail for a familiar reason: the definition is treated as an implementation detail. Different teams calculate the same number different ways, then spend time reconciling why the answers do not match.

I built this project to avoid that pattern. It focuses on one metric, Ending ARR, and treats the metric itself as the product. The scope is intentionally narrow, but the implementation goes deep enough to prove the definition, the ownership model, the validation stack, and the delivery path.

## Why ARR is the right test case

ARR looks simple until you have to make it real. Then the edge cases show up:

- monthly, quarterly, and annual billing
- discounts
- one-time fees and services exclusions
- churn and reactivation
- renewal uplift
- historical inclusion even when a subscription is later cancelled

That is why the project focuses on **Ending ARR** instead of trying to build a broad semantic layer with many half-finished metrics. If the foundation is weak, every downstream dashboard, model, or AI assistant will reinterpret the metric differently.

## What the project actually does

The repo implements one governed metric end to end:

- synthetic Salesforce-style seed data
- staging models that standardize names and types
- one intermediate model that owns ARR eligibility and annualization
- certified month-end ARR and movement facts
- dbt semantic models for governed consumption
- a Snowflake semantic-view path for BI and AI
- hand-calculated fixtures, singular tests, unit tests, and model contracts

The point is not just to calculate ARR. The point is to prove that the metric is stable, explainable, and reviewable.

## The trust stack

The strongest part of the project is the stack of controls around the metric:

1. **Metric contract** - who owns the metric, what it means, and what it is not
2. **Business rules** - effective dates, eligibility, annualization, and exclusions
3. **Expected answers** - independent fixture totals calculated before implementation
4. **Tests** - singular tests, unit tests, and contract enforcement
5. **Semantic consumption** - a certified surface so BI and AI do not rebuild the logic differently

That stack matters because trust is not a vibe. It is the result of repeated checks that all agree with each other.

## Why the semantic layer matters

A semantic layer becomes important when the same metric needs to serve multiple audiences:

- analysts want a reusable definition
- RevOps wants a business-owned contract
- Finance wants historical stability
- AI needs a constrained surface that does not wander into raw-data ambiguity

This project uses that tension deliberately. The metric is certified once, then served through governed interfaces.

## How I would prove the Snowflake side

The repo includes both of the important ingredients:

- the native Snowflake semantic view SQL
- the validation queries that prove the object and its outputs

The strongest evidence for Snowflake is a simple proof packet:

- a worksheet screenshot showing the semantic view DDL or `SHOW SEMANTIC VIEWS`
- `SHOW SEMANTIC METRICS` and `SHOW SEMANTIC DIMENSIONS`
- a query result for month-end Ending ARR
- the same monthly totals compared to the expected fixtures in the repo

That turns the Snowflake piece from “we wrote SQL” into “we verified the governed object exists and returns the expected answers.”

## What makes this portfolio-worthy

If I were presenting this as a portfolio piece, I would emphasize four things:

- **Depth over breadth** - one metric, fully worked through
- **Governance** - business ownership, change control, and invalid-use boundaries
- **Verification** - tests and hand-calculated fixtures, not just “it runs”
- **Controlled reuse** - certified meaning as the prerequisite for safe BI and AI consumption

## What I intentionally left out

This is a lab, not a full production platform. I intentionally left out live Metabase deployment, live Snowflake semantic execution in this workspace, multi-currency, usage-based pricing, row-level security, and historical type-2 account dimensions.

Those are valid next steps, but they would dilute the main story.

## A more tangible way to show the project

If you want this to leave a stronger impression than a standard blog post, the best asset is not more words - it is a **visual case study page**.

For this repo, that means:

- a hero diagram of the metric flow
- a small line chart of certified monthly ARR
- a proof stack showing contract / logic / evidence / controls
- a short Snowflake validation section with query screenshots

That format makes the work feel like a product story, not a code dump.

## The takeaway

The project is really about a broader pattern:

> If you want AI to be useful in revenue operations, first make the metric trustworthy for humans.

Once the metric is governed, tested, and certified, AI can safely consume it instead of improvising over raw tables.
