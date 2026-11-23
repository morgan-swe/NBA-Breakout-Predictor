# NBA Breakout Predictor

Predicts which NBA players are likely to have a breakout season (a ppg jump of 5 or more over the previous season).

## Setup
```
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Pipeline (run from the project root)
| Step | Command | Output |
|---|---|---|
| Clean the raw CSV (pandas) | `python -m data.clean_data` | `data/processed/player-per-game-cleaned.csv` |
| Build the dataset (pandas) | `python -m utilities.features` | `data/processed/breakout_dataset.csv` |
| Build the SQLite database | `python -m utilities.build_db` | `data/nba.db` (not tracked in git) |

`build_db` loads the raw CSVs into `raw_per_game` and `raw_advanced`, then runs the numbered scripts in `sql/` in order:
- `sql/01_clean.sql` builds `clean_ppg`
- `sql/02_features.sql` builds `breakout_dataset`

`sql/validate.sql` and `sql/explore.sql` are run by hand.

## Layout
- `data/raw/`: original CSVs, never edited
- `data/processed/`: cleaned and model-ready CSVs
- `sql/`: SQL scripts
- `utilities/`: loaders (`load_data.py`), feature code (`features.py`), SQLite helpers (`db.py`, `build_db.py`)
- `analysis/`: notebooks (`01_define_breakout`, `02_model_and_importance`)
