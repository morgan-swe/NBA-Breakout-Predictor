-- 01_clean.sql  (SQL Server / T-SQL, run in SSMS)
-- Build dbo.clean_ppg from [Player Per Game]: one row per player-season.

USE [nba_stats];
GO

DROP TABLE IF EXISTS [dbo].[ppg_staging];
GO

-- Create staging table
SELECT *
INTO [dbo].[ppg_staging]
FROM [dbo].[Player Per Game];

-- Delete any rows that aren't in the NBA
SELECT*
FROM [dbo].[ppg_staging]
WHERE lg != 'NBA';

DELETE FROM [dbo].[ppg_staging]
WHERE lg != 'NBA';

-- Delete all seasons before 3pt era (seasons < 1980)
SELECT*
FROM [dbo].[ppg_staging]
WHERE season < 1980;

DELETE FROM [dbo].[ppg_staging]
WHERE season < 1980;

-- Delete all rows with under 10 games per season
SELECT*
FROM [dbo].[ppg_staging]
WHERE g < 10;

DELETE FROM [dbo].[ppg_staging]
WHERE g < 10;

-- Did not need to delete anything here since removing player with less than 10 games took care of it
SELECT*
FROM [dbo].[ppg_staging]
WHERE mp_per_game IS NULL;

-- Traded players: keep their combined row (2TM, 3TM, etc.) and remove their per team rows
-- Check if all the combined rows have a row_num = 1
WITH single_tm AS (
SELECT player, team, season, g, player_id,
	ROW_NUMBER() OVER(
		PARTITION BY 
			season,
			player_id
		ORDER BY g DESC
	) AS row_num
FROM [dbo].[ppg_staging]
)
SELECT*
FROM single_tm
WHERE row_num > 1 AND team LIKE '[0-9]TM';

-- Traded players per team rows contain a row_num value greater than 1
WITH single_tm AS (
SELECT player, team, season, g, player_id,
	ROW_NUMBER() OVER(
		PARTITION BY 
			season,
			player_id
		ORDER BY g DESC
	) AS row_num
FROM [dbo].[ppg_staging]
)
DELETE FROM single_tm
WHERE row_num != 1;

-- Delete 2027 season since its incomplete
DELETE FROM [dbo].[ppg_staging]
WHERE season > 2026;

-- Create clean table
EXEC sp_rename 'dbo.ppg_staging', 'clean_ppg';

-- Finish with checks
SELECT COUNT(*) FROM [dbo].[clean_ppg];  -- expect 18720
SELECT player_id, season FROM [dbo].[clean_ppg]
GROUP BY player_id, season HAVING COUNT(*) > 1;  -- expect no rows