import pandas as pd
import pathlib

# Paths are anchored to the project root so scripts work from any directory
ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"

RAW_PPG_PATH = RAW_DIR / "Player Per Game.csv"
CLEAN_PPG_PATH = PROCESSED_DIR / "player-per-game-cleaned.csv"


def load_raw_ppg():
    """Load the raw Player Per Game.csv file."""
    return pd.read_csv(RAW_PPG_PATH)


def load_clean_ppg():
    """Load the cleaned player-per-game-cleaned.csv file (made by data/clean_data.py)."""
    if not CLEAN_PPG_PATH.exists():
        raise FileNotFoundError(
            f"{CLEAN_PPG_PATH} not found. Run `python -m data.clean_data` from the project root first."
        )
    df = pd.read_csv(CLEAN_PPG_PATH)
    # Catch a stale or edited file early
    assert not df.duplicated(["player_id", "season"]).any(), "cleaned file has duplicate player-seasons"
    return df
