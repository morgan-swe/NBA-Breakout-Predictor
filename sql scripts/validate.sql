-- validate.sql  (SQL Server / T-SQL; run by hand in SSMS: highlight a query and press F5)

-- Raw tables loaded correctly? (expect 33780 each)
SELECT 'Player Per Game' AS tbl, COUNT(*) AS n FROM [nba_stats].[dbo].[Player Per Game]
UNION ALL
SELECT 'Advanced', COUNT(*) FROM [nba_stats].[dbo].[Advanced];

-- Rows per league in the raw data
SELECT lg, COUNT(*) AS n FROM [nba_stats].[dbo].[Player Per Game] GROUP BY lg;

-- Raw duplicates on (player_id, season, team)? (expect none)
SELECT player_id, season, team, COUNT(*) AS n
FROM [nba_stats].[dbo].[Player Per Game]
GROUP BY player_id, season, team
HAVING COUNT(*) > 1;

-- Raw rows per player-season: more than 1 means a traded player (combined row + per-team rows)
SELECT TOP 20 player_id, season, COUNT(*) AS n
FROM [nba_stats].[dbo].[Player Per Game]
GROUP BY player_id, season
HAVING COUNT(*) > 1;

-- After you build dbo.clean_ppg, add your own checks here:
--   * row count is 18720
--   * no duplicate (player_id, season)
--   * no 'NA' strings or NULL mp_per_game left
