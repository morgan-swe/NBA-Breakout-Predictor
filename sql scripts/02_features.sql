-- 02_features.sql  (SQL Server / T-SQL, run in SSMS)
-- Build dbo.breakout_dataset from dbo.clean_ppg: one row per usable player-season.
-- Goal: the same columns as data/processed/breakout_dataset.csv (11,122 rows):
--   player, player_id, season, pts_per_game, ppg_change, breakout,
--   age, prev_pts_per_game, prev_mp_per_game, prev_fga_per_game, prev_x3pa_per_game,
--   prev_fta_per_game, prev_ast_per_game, prev_trb_per_game, prev_stl_per_game,
--   prev_blk_per_game, prev_tov_per_game, prev_e_fg_percent, prev_g
--
-- Pattern: a CTE that uses LAG() to bring last season's values onto each row.
--   WITH base AS (
--       SELECT player_id, season, pts_per_game,
--              LAG(pts_per_game) OVER (PARTITION BY player_id ORDER BY season) AS prev_pts_per_game,
--              LAG(season)       OVER (PARTITION BY player_id ORDER BY season) AS prev_season
--       FROM dbo.clean_ppg
--   )
--   SELECT ... FROM base WHERE season - prev_season = 1;
--
-- Rules:
--   - breakout = 1 when pts_per_game - prev_pts_per_game >= 5, else 0   (CASE WHEN)
--   - only back-to-back seasons                                          (season - prev_season = 1)
--   - both seasons need enough games: at least 40/82 of that season's length.
--     Season length = the 99th percentile of g within the season:
--       PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY g) OVER (PARTITION BY season)
--     (window functions can't go in WHERE, so compute everything in a CTE first)
--
-- Stretch: JOIN dbo.Advanced (usg_percent, per, bpm...) on player_id, season and team.

USE [nba_stats];
GO

DROP TABLE IF EXISTS dbo.breakout_dataset;
GO

-- WITH base AS (...)
-- SELECT ...
-- INTO dbo.breakout_dataset
-- FROM base
-- WHERE ...;
-- GO
