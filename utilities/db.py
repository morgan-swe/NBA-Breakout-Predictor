"""Helpers for the SQLite database (data/nba.db)."""
import sqlite3
from contextlib import closing

import pandas as pd

from utilities import load_data

DB_PATH = load_data.ROOT / "data" / "nba.db"
SQL_DIR = load_data.ROOT / "sql"


def get_connection():
    """Open a connection to data/nba.db (created if it doesn't exist). Close it when you're done."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def query(sql, params=None):
    """Run a SELECT and return the result as a DataFrame. Handy in notebooks:
        db.query("SELECT * FROM clean_ppg WHERE season = ?", (2024,))
    """
    with closing(get_connection()) as conn:
        return pd.read_sql_query(sql, conn, params=params)
