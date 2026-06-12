# CI/CD Runbook

## Purpose

GitHub Actions validates every proposed change locally before it can be
deployed to Snowflake. Snowflake development and production deployments use
separate GitHub environments so their credentials, permissions, and approval
rules can differ.

## Continuous Integration

`.github/workflows/ci.yml` runs for pull requests, pushes to `main`, and manual
dispatches. It:

1. creates the ignored runtime `profiles.yml` from `profiles.example.yml`;
2. parses the DuckDB, isolated Snowflake development, and production targets;
3. creates empty model relations so unit tests can infer input schemas on a
   fresh runner;
4. runs the focused dbt unit tests;
5. downloads the latest successful `main` manifest, when one exists;
6. builds modified nodes with their dependencies and descendants;
7. runs the complete local DuckDB build and data-test suite;
8. executes the local semantic contract validator; and
9. publishes the successful `main` manifest for future state comparison.

The first successful `main` run has no prior manifest, so modified-state
selection is skipped. The complete build still runs.

The modified-state build is an optimization and change-impact check, not a
replacement for the complete local build. Prefixing and suffixing
`state:modified` with `+` includes required ancestors and affected descendants
in the fresh CI database.

## GitHub Configuration

Create GitHub environments named `development` and `production`.

Add these secrets to both environments:

- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_PASSWORD`

Add these environment variables, or rely on the profile defaults:

- `SNOWFLAKE_ROLE`
- `SNOWFLAKE_DATABASE`
- `SNOWFLAKE_WAREHOUSE`

Require reviewers on the `production` environment. This is the approval gate
that prevents a manual production dispatch from deploying immediately.

Set the repository variable `ENABLE_SNOWFLAKE_CD` to `true` only after the
development environment credentials are configured and a manual development
deployment succeeds.

## Continuous Deployment

`.github/workflows/snowflake-deploy.yml` supports two deployment paths.

### Development

A manual `development` dispatch builds into an isolated namespace such as:

```text
DBT_GHA_123456_RAW
DBT_GHA_123456_STAGING
DBT_GHA_123456_INTERMEDIATE
DBT_GHA_123456_MARTS
```

After `ENABLE_SNOWFLAKE_CD=true`, each successful `CI` workflow on `main`
starts the same isolated development deployment. The deployment checks out the
exact commit validated by that CI run.

Protect `main` with the required CI status check. Deployment is downstream of
CI and is not a substitute for branch protection.

### Production

Production deployment is manual only:

1. Open **Actions** and select **Snowflake deployment**.
2. Choose **Run workflow** and select `production`.
3. Obtain approval from a required reviewer on the `production` environment.
4. The workflow validates the connection, refreshes the lab seeds, and runs
   `dbt build --target prod`.

The production target writes to stable `RAW`, `STAGING`, `INTERMEDIATE`, and
`MARTS` schemas. It must never be used for pull-request or development builds.

## Important Limitations

- This lab still deploys seed-based fixture inputs. Replace them with governed
  production `source()` inputs before treating production deployment as a real
  ingestion pattern.
- The native Snowflake semantic view is a separate SQL deployment and is not
  created by these workflows.
- Password authentication is supported by the current profile. Prefer
  key-pair or workload-identity authentication before production use.
- The custom semantic validator proves local contract behavior; it does not
  execute a hosted dbt Semantic Layer query.
