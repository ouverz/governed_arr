FROM python:3.12-slim

ARG DBT_DUCKDB_VERSION=1.9.6
ARG DBT_CORE_VERSION=1.11.11
ARG DBT_SNOWFLAKE_VERSION=1.10.2

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    "dbt-core==${DBT_CORE_VERSION}" \
    "dbt-duckdb==${DBT_DUCKDB_VERSION}" \
    "dbt-snowflake==${DBT_SNOWFLAKE_VERSION}"

WORKDIR /usr/app

ENTRYPOINT ["dbt"]
CMD ["build", "--profiles-dir", "."]
