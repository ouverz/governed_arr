from pathlib import Path

import duckdb


database_path = Path("data/arr_lab.duckdb")

queries = {
    "Deployed objects": """
        select table_schema, table_name, table_type
        from information_schema.tables
        where table_schema not in ('information_schema', 'pg_catalog')
        order by table_schema, table_name
    """,
    "Certified Ending ARR rows": """
        select *
        from main_marts.fct_arr_snapshot
        order by snapshot_date, account_id, subscription_id, product_family
    """,
    "Certified monthly totals": """
        select snapshot_date, sum(ending_arr) as ending_arr
        from main_marts.fct_arr_snapshot
        group by snapshot_date
        order by snapshot_date
    """,
    "Auditable excluded lines": """
        select subscription_line_id, product_family, charge_type, is_arr_eligible, line_arr
        from main_intermediate.int_subscription_arr_lines
        where not is_arr_eligible
        order by subscription_line_id
    """,
    "Explainable ARR movements": """
        select snapshot_date, account_id, beginning_arr, ending_arr, movement_amount, movement_type
        from main_marts.fct_arr_movement
        order by snapshot_date, account_id
    """,
}


def print_result(title: str, connection: duckdb.DuckDBPyConnection, sql: str) -> None:
    result = connection.execute(sql)
    columns = [description[0] for description in result.description]
    rows = result.fetchall()
    widths = [
        max(len(column), *(len(str(row[index])) for row in rows))
        for index, column in enumerate(columns)
    ]

    print(f"\n{title}")
    print(" | ".join(column.ljust(widths[index]) for index, column in enumerate(columns)))
    print("-+-".join("-" * width for width in widths))
    for row in rows:
        print(" | ".join(str(value).ljust(widths[index]) for index, value in enumerate(row)))


with duckdb.connect(str(database_path), read_only=True) as connection:
    for query_title, query_sql in queries.items():
        print_result(query_title, connection, query_sql)
