import pandas as pd
import unicodedata
from utilities import load_data

# Load the data from the CSV file
df = load_data.load_raw_ppg()

# Standardize text
def strip_accents(value):
  """
  Removes name accents to make searching for the player easier:
  Luka Dončić now become Luka Doncic
  """
  if not isinstance(value, str):
    return value
  normalized = unicodedata.normalize("NFKD", value)
  return normalized.encode("ascii", "ignore").decode("utf-8")

df["player_search"] = df["player"].apply(strip_accents)

# Remove duplicate entries
df = df.drop_duplicates()

# Handle missing data
df = df.dropna(subset=["mp_per_game"]) # Drops players with NULL minutes

# League filter
df = df[df["lg"] == "NBA"] # Drop any leagues that arent the NBA

# Drop 2027 season since its incomplete
df = df[~df["season"].isin([2027])]

# Drop players with fewer than 10 games (small samples give noisy per-game stats)
df = df[df["g"] >= 10]

# Remove eras that don't contain the 3pt stats
df = df[df["season"] >= 1980]

# Keep the 2TM, 3TM rows and remove the individual team stats
# is_total: True for combined rows (2TM, 3TM, ...)
df["is_total"] = df["team"].str.match(r"^\dTM$")
# has_total: True for every row of a player-season that has a combined row
df["has_total"] = df.groupby(["player_id", "season"])["is_total"].transform("any")
# Keep combined rows, plus rows of players who weren't traded
df = df[df["is_total"] | ~df["has_total"]]
df = df.drop(columns=["is_total", "has_total"])

# Safety check: exactly one row per player-season
assert not df.duplicated(["player_id", "season"]).any()

# Output the cleaned data
load_data.PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

df.to_csv(load_data.CLEAN_PPG_PATH, index=False)