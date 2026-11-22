"""
Builds the model-ready breakout dataset from the cleaned Player Per Game data.

Run from the project root to build and save it:
    python -m utilities.features

Notebooks then load the saved file with load_dataset().
"""
import pandas as pd

from utilities import load_data

# Players need the same SHARE of their season's games (40 of 82 in a normal season),
# so shortened seasons (1999, 2012, 2020, 2021) aren't treated unfairly
MIN_SHARE = 40 / 82

# A ppg jump of at least this much counts as a breakout (roughly the top 5-6% of jumps)
BREAKOUT_THRESHOLD = 5

# Last season's stats used as clues. Only past data, so the model can't see the answer
STAT_COLS = ["pts_per_game", "mp_per_game", "fga_per_game", "x3pa_per_game",
             "fta_per_game", "ast_per_game", "trb_per_game", "stl_per_game",
             "blk_per_game", "tov_per_game", "e_fg_percent", "g"]
FEATURES = ["age"] + ["prev_" + c for c in STAT_COLS]

DATASET_PATH = load_data.PROCESSED_DIR / "breakout_dataset.csv"


def add_season_changes(df):
    """Sort by player and season, then add the columns used to compare back-to-back seasons."""
    df = df.copy()

    # Season length: the 99th percentile of games played in that season
    # (the max can exceed 82 because traded players' combined rows add up games)
    df["season_len"] = df.groupby("season")["g"].transform(lambda x: x.quantile(0.99))
    df["enough_games"] = df["g"] >= MIN_SHARE * df["season_len"]

    df = df.sort_values(["player_id", "season"])
    # Change in ppg vs the previous row for the same player
    df["ppg_change"] = df.groupby("player_id")["pts_per_game"].diff()
    # Years between those two rows (1 = back-to-back seasons)
    df["season_gap"] = df.groupby("player_id")["season"].diff()
    # Did the player have enough games in the previous season? (first season -> False)
    df["prev_enough"] = df.groupby("player_id")["enough_games"].shift(1, fill_value=False)
    return df


def usable_mask(df):
    """Rows where this season and the previous one are back-to-back and both have enough games."""
    return (df["season_gap"] == 1) & df["enough_games"] & df["prev_enough"]


def add_label_and_features(df):
    """Add the breakout label and last season's stats (the prev_ columns)."""
    df = df.copy()
    df["breakout"] = (df["ppg_change"] >= BREAKOUT_THRESHOLD).astype(int)
    # shift(1) must run on the full sorted table so "previous row" means "previous season"
    for c in STAT_COLS:
        df["prev_" + c] = df.groupby("player_id")[c].shift(1)
    return df


def build_dataset():
    """Return one row per usable player-season with the label and features."""
    df = load_data.load_clean_ppg()
    df = add_season_changes(df)
    df = add_label_and_features(df)
    usable = df[usable_mask(df)].dropna(subset=FEATURES)
    keep = ["player", "player_id", "season", "pts_per_game", "ppg_change", "breakout"] + FEATURES
    return usable[keep].reset_index(drop=True)


def load_dataset():
    """Load the saved dataset made by `python -m utilities.features`."""
    if not DATASET_PATH.exists():
        raise FileNotFoundError(
            f"{DATASET_PATH} not found. Run `python -m utilities.features` from the project root first."
        )
    return pd.read_csv(DATASET_PATH)


if __name__ == "__main__":
    dataset = build_dataset()
    DATASET_PATH.parent.mkdir(parents=True, exist_ok=True)
    dataset.to_csv(DATASET_PATH, index=False)
    print(f"Saved {len(dataset)} rows to {DATASET_PATH}; breakout rate {dataset['breakout'].mean():.3f}")
