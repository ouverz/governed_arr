from pathlib import Path

import duckdb


database_path = Path("data/arr_lab.duckdb")

with duckdb.connect(str(database_path), read_only=True) as connection:
    rows = connection.execute(
        """
        select snapshot_date, sum(ending_arr) as ending_arr
        from main_marts.fct_arr_snapshot
        group by snapshot_date
        order by snapshot_date
        """
    ).fetchall()

for snapshot_date, ending_arr in rows:
    print(f"{snapshot_date} | {ending_arr:.2f}")

