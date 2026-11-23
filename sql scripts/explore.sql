-- explore.sql  (practice queries; run by hand, not run by build_db)
-- 1. Top 5 scorers in every season 
WITH top_season_ppg AS (
	SELECT 
		player,
		pts_per_game,
		season,
		ROW_NUMBER() OVER (
			PARTITION BY season
			ORDER BY pts_per_game DESC
		) AS top_5
	FROM [nba_stats].[dbo].[Player Per Game]
	WHERE pts_per_game IS NOT NULL
)
SELECT player, ROUND(pts_per_game, 1), season
FROM top_season_ppg
WHERE top_5 <= 5
ORDER BY season DESC, pts_per_game DESC;

-- 2. Each player's career averages and season count -> GROUP BY, AVG, COUNT
SELECT 
	player, 
	ROUND(AVG(pts_per_game), 1) AS PPG, 
	ROUND(AVG(trb_per_game), 1) AS RPG,
	ROUND(AVG(ast_per_game), 1) AS APG, 
	COUNT(season) AS total_seasons
FROM [nba_stats].[dbo].[Player Per Game]
GROUP BY player
ORDER BY PPG DESC;

-- 3. Average ppg jump by decade                     -> CASE or integer division, GROUP BY
WITH parsed AS (
    SELECT
        TRY_CAST(LEFT(CAST(season AS VARCHAR(20)), 4) AS INT) AS start_year,
        pts_per_game
    FROM [nba_stats].[dbo].[Player Per Game]
    WHERE pts_per_game IS NOT NULL
),
bucketed AS (
    SELECT
        CAST(FLOOR((start_year - 1950) / 10.0) * 10 + 1950 AS INT) AS period_start,
        pts_per_game
    FROM parsed
    WHERE start_year IS NOT NULL
      AND start_year >= 1950
),
span_ppg AS (
    SELECT
        period_start,
        CONCAT(period_start, '-', period_start + 10) AS season_span,
        ROUND(AVG(pts_per_game), 2) AS avg_ppg
    FROM bucketed
    GROUP BY period_start
)
SELECT
    season_span,
    avg_ppg,
    LAG(avg_ppg) OVER (ORDER BY period_start) AS prev_span_ppg,
    ROUND(avg_ppg - LAG(avg_ppg) OVER (ORDER BY period_start), 2) AS span_ppg_jump
FROM span_ppg
ORDER BY period_start;

-- 4. Players in raw_per_game but not in raw_advanced -> LEFT JOIN ... WHERE ... IS NULL
SELECT
    p.player_id,
    p.player,
    p.season,
    p.team
FROM [nba_stats].[dbo].[Player Per Game] AS p
LEFT JOIN [nba_stats].[dbo].[Advanced] AS a
    ON  p.player_id = a.player_id
    AND p.season = a.season
    AND p.team = a.team
WHERE a.player_id IS NULL;

-- 5. Players who scored 20+ ppg in a season after a season under 12 -> LAG() in a CTE
WITH player_history AS (
	SELECT
		player,
		pts_per_game,
		season,
		LAG(pts_per_game) OVER (PARTITION BY player ORDER BY season) AS prev_season_ppg
	FROM [nba_stats].[dbo].[Player Per Game]
)
SELECT
	player,
	pts_per_game,
	season,
	prev_season_ppg
FROM player_history
WHERE pts_per_game >= 20 AND prev_season_ppg <= 12
ORDER BY season DESC;