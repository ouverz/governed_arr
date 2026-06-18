# Building One Trusted ARR Metric for Humans and AI

I built this project to answer a simple question that shows up in every revenue team eventually:

> Can we make one ARR number that Finance trusts, RevOps can explain, and AI can safely reuse?

The short answer is yes — but only if the metric is treated as a governed product, not a loose SQL query.

## Why ARR

ARR is a good test case because it looks simple on the surface and gets messy quickly in practice. The metric has to handle:

- monthly, quarterly, and annual billing;
- discounts;
- one-time and services exclusions;
- churn and reactivation;
- renewal uplift;
- historical inclusion even when a subscription is later cancelled or expired.

That means the important work is not just calculating a sum. The important work is defining the rules, enforcing them once, and making the result easy to consume without allowing every downstream tool to reinterpret it.

## What the project does

The repo implements a single governed metric, **Ending ARR**, end to end:

- synthetic Salesforce-style seed data;
- staging models that clean names and types;
- one intermediate model that owns ARR eligibility and annualization;
- certified month-end ARR and movement facts;
- dbt semantic models for governed consumption;
- a Snowflake semantic-view path for BI and AI;
- hand-calculated fixtures, singular tests, unit tests, and model contracts.

The point is to prove that the metric is stable, explainable, and reviewable.

## What makes it trustworthy

The project uses several layers of control:

1. **Metric contract** — who owns the metric, what it means, and what it is not.
2. **Business rules** — effective dates, eligibility, annualization, and exclusions.
3. **Expected answers** — independent fixture totals calculated before implementation.
4. **Tests** — singular tests, unit tests, and contract enforcement.
5. **Semantic layer** — a certified consumption surface so BI and AI do not rebuild the logic differently.

That stack matters because trust is not a vibe. It is the result of repeated checks that all agree with each other.

## Why the semantic layer matters

A semantic layer becomes important when the same metric needs to serve multiple audiences:

- analysts want a reusable definition,
- RevOps wants a business-owned contract,
- Finance wants historical stability,
- and AI needs a constrained surface that does not wander into raw-data ambiguity.

This project uses that tension deliberately. The metric is certified once, then served through governed interfaces.

## What I would emphasize in a portfolio review

If I were presenting this as a portfolio piece, I would focus on four things:

- **Depth over breadth** — one metric, fully worked through.
- **Governance** — business ownership, change control, and invalid-use boundaries.
- **Verification** — tests and hand-calculated fixtures, not just “it runs.”
- **AI readiness** — certified meaning as a prerequisite for safe reuse.

## What is intentionally left out

This is a lab, not a full production platform. I intentionally left out live Metabase deployment, live Snowflake semantic execution in this workspace, multi-currency, usage-based pricing, row-level security, and historical type-2 account dimensions.

Those are valid next steps, but they would dilute the main story.

## The takeaway

The project is really about a broader pattern:

> If you want AI to be useful in revenue operations, first make the metric trustworthy for humans.

Once the metric is governed, tested, and certified, AI can safely consume it instead of improvising over raw tables.
