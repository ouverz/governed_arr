.PHONY: build build-prod build-snowflake-dev clean debug debug-prod debug-snowflake-dev docs docs-serve inspect query refresh refresh-prod semantic-validate unit-test

build:
	docker compose run --rm dbt build

build-prod:
	docker compose run --rm dbt build --target prod

build-snowflake-dev:
	docker compose run --rm dbt build --target snowflake_dev

refresh:
	docker compose run --rm dbt seed --full-refresh
	docker compose run --rm dbt build

refresh-prod:
	docker compose run --rm dbt seed --full-refresh --target prod
	docker compose run --rm dbt build --target prod

clean:
	docker compose run --rm dbt clean

debug:
	docker compose run --rm dbt debug

debug-prod:
	docker compose run --rm dbt debug --target prod

debug-snowflake-dev:
	docker compose run --rm dbt debug --target snowflake_dev

docs:
	docker compose run --rm dbt docs generate

docs-serve:
	docker compose run --rm --service-ports dbt docs serve --host 0.0.0.0 --port 8080

inspect:
	docker compose run --rm --entrypoint python dbt scripts/inspect_duckdb.py

query:
	docker compose run --rm --entrypoint python dbt scripts/query_results.py

semantic-validate:
	docker compose run --rm dbt parse
	docker compose run --rm --entrypoint python dbt scripts/validate_semantic_contract.py

unit-test:
	docker compose run --rm dbt test --select resource_type:unit_test
