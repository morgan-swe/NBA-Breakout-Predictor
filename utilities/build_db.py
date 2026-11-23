"""
Rebuilds data/nba.db from scratch. Run from the project root:
    python -m utilities.build_db

1. Loads the raw CSVs into raw_per_game and raw_advanced (unchanged; "NA" becomes NULL).
2. Runs every numbered script in sql/ in order (01_clean.sql, 02_features.sql, ...).
   Files without a number prefix (validate.sql, explore.sql) are for you to run by hand.
"""
import re
from contextlib import closing

import pandas as pd

from utilities import db, load_data

RAW_TABLES = {
    "raw_per_game": load_data.RAW_PPG_PATH,
    "raw_advanced": load_data.RAW_ADV_PATH,
}
BUILD_SCRIPT = re.compile(r"^\d{2}_.*\.sql$")


def load_raw(conn):
    """Load each raw CSV into its own table, replacing it if it already exists."""
    for table, path in RAW_TABLES.items():
        df = pd.read_csv(path)
        df.to_sql(table, conn, if_exists="replace", index=False)
        count = conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        assert count == len(df), f"{table}: loaded {count} rows but the file has {len(df)}"
        print(f"{table}: {count} rows")


def run_build_scripts(conn):
    """Run the numbered .sql files in order."""
    for path in sorted(db.SQL_DIR.glob("*.sql")):
        if BUILD_SCRIPT.match(path.name):
            conn.executescript(path.read_text(encoding="utf-8"))
            print(f"ran {path.name}")


def main():
    with closing(db.get_connection()) as conn:
        load_raw(conn)
        run_build_scripts(conn)
        conn.commit()


if __name__ == "__main__":
    main()
