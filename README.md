# NBA Breakout Predictor

Predicts which NBA players are likely to have a breakout season (a ppg jump of 5 or more over the previous season).

The data is cleaned and shaped in SQL Server (SSMS), and the model is trained in Python.

## Setup

### Python
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### SQL Server
1. In SSMS, create a database called `nba_stats`.
2. Import the raw CSVs with the wizard (right-click the database > Tasks > Import Flat File):
   - `data/raw/Player Per Game.csv` as `dbo.[Player Per Game]`
   - `data/raw/Advanced.csv` as `dbo.[Advanced]`
3. On the "Modify Columns" screen, set `int` for `season`, `age`, `g` and `gs`, and `float` for the stat columns. Columns containing the text `NA` may load as text; handle them with `NULLIF(col, 'NA')` and `TRY_CAST`.
4. Check the load: both tables should have 33,780 rows.

## SQL scripts (run in SSMS, in order)
| Script | What it does |
|---|---|
| `sql scripts/01_clean.sql` | Copies `Player Per Game` into `dbo.ppg_staging`, then removes non-NBA rows, seasons before 1980, players with under 10 games, and the per-team rows of traded players (keeps the combined `2TM`/`3TM` row). Expected result: 18,720 rows |
| `sql scripts/02_features.sql` | In progress. Will build `dbo.breakout_dataset` (last season's stats, `ppg_change` and the `breakout` label) using `LAG()`. Expected result: 11,122 rows |
| `sql scripts/validate.sql` | Run by hand. Row counts, duplicate checks and other sanity checks |
| `sql scripts/explore.sql` | Run by hand. Practice queries (rankings, joins, window functions) |

## Python pipeline (run from the project root)
The notebooks currently use a dataset built in pandas. The SQL scripts reproduce it, and the pandas version is the answer key to check them against.

| Step | Command | Output |
|---|---|---|
| Clean the raw CSV | `python -m data.clean_data` | `data/processed/player-per-game-cleaned.csv` |
| Build the dataset | `python -m utilities.features` | `data/processed/breakout_dataset.csv` |

Then run the notebooks in `analysis/` in order.

## Layout
- `data/raw/`: original CSVs, never edited
- `data/processed/`: cleaned and model-ready CSVs
- `sql scripts/`: T-SQL scripts for SQL Server
- `utilities/`: loaders (`load_data.py`) and feature code (`features.py`). `db.py` and `build_db.py` are an earlier SQLite loader that the SQL Server workflow doesn't use
- `analysis/`: notebooks (`01_define_breakout`, `02_model_and_importance`)
