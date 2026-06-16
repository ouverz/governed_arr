# Singular Business Test Catalog

This catalog gives the human-readable intent for the high-value singular tests in `tests/*.sql`.

## Certified totals

- `assert_ending_arr_expected_totals.sql`
  - Reconciles monthly Ending ARR to the hand-calculated fixture totals.
  - Protects the board-level answer from silent drift.

- `assert_ending_arr_expected_by_account.sql`
  - Reconciles monthly Ending ARR by account to the expected fixture.
  - Protects slicing by account from duplicating or dropping ARR.

- `assert_arr_movements_expected.sql`
  - Reconciles account-level ARR movement classifications and amounts to the expected fixture.
  - Protects the movement story from misclassifying new, expansion, contraction, churn, or reactivation.

## Eligibility and effective dates

- `assert_ineligible_lines_excluded.sql`
  - Ensures ineligible subscription lines do not contribute ARR.
  - Protects services, setup fees, and other excluded items from leaking into the metric.

- `assert_line_annualization.sql`
  - Verifies recurring pricing annualizes correctly across monthly and quarterly billing intervals.
  - Protects the line-level ARR math.

- `assert_line_dates_within_subscription.sql`
  - Ensures subscription lines stay within valid subscription dates.
  - Protects historical inclusion from broken effective dates.

- `assert_snapshot_only_contains_active_lines.sql`
  - Ensures snapshot rows only link to lines active on the snapshot date.
  - Protects month-end balance logic.

- `assert_snapshot_only_contains_active_subscriptions.sql`
  - Ensures snapshot rows only link to subscriptions active on the snapshot date.
  - Protects historical inclusion from inactive parent subscriptions.

## Grain and value constraints

- `assert_snapshot_grain.sql`
  - Ensures the certified fact has one row per snapshot date, account, subscription, and product family.
  - Protects the model from accidental duplication.

- `assert_ending_arr_non_negative.sql`
  - Ensures no certified snapshot row has negative Ending ARR.
  - Protects the public fact from invalid balances.

- `assert_pricing_math.sql`
  - Verifies stored net amount matches quantity, price, and discount math.
  - Protects the upstream pricing fields used by ARR eligibility.

## How to read this catalog

The SQL files remain the executable source of truth. This catalog is the short narrative index for reviewers who want the business intent before reading each query.
