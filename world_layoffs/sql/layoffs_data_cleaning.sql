-- ========================================================================================
--                        WORLD_LAYOFFS | DATA CLEANING
-- ========================================================================================

-- Use the layoffs_analytics database
use layoffs_analytics;

-- Preview the raw dataset
SELECT * 
FROM layoffs_raw
LIMIT 10;

-- -------------------------- DATA CLEANING STEPS -----------------------------------------
-- 1) Create a staging table and rename incorrect column headers
-- 2) Remove duplicates
-- 3) Standardize data (format text, dates, etc.)
-- 4) Handle NULL and blank values where applicable
-- 5) Remove unnecessary rows and columns
-- ----------------------------------------------------------------------------------------

-- ========================================================================================
-- STEP 1 – CREATE A STAGING TABLE AND RENAME INCORRECT COLUMN HEADERS
-- ========================================================================================

-- Create a staging table with the same structure as layoffs_raw
CREATE TABLE layoffs_staging
LIKE layoffs_raw;

-- Verify that the staging table was created (should return an empty result)
SELECT *
FROM layoffs_staging;

-- Insert data from raw table into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs_raw;

-- Verify that data has been inserted
SELECT *
FROM layoffs_staging;

-- Check row counts to confirm data copied correctly
SELECT COUNT(*) FROM layoffs_raw;
SELECT COUNT(*) FROM layoffs_staging;

-- Fix the header of the company column (removed typo)
ALTER TABLE layoffs_staging
RENAME COLUMN `ï»¿company` TO `company`;

-- Verify that the company column name has been fixed
SELECT *
FROM layoffs_staging;

-- ========================================================================================
-- STEP 2 – REMOVE DUPLICATES 
-- ========================================================================================

-- Identify duplicate rows using ROW_NUMBER()
-- Duplicate rows are those where row_num > 1
WITH duplicate_data_cte AS
( 
	SELECT *, 
			ROW_NUMBER() OVER(
				PARTITION BY company, location, total_laid_off, `date`, 
							 percentage_laid_off, industry, stage, 
                             funds_raised, country 
				ORDER BY `date` DESC
			) AS row_num
	FROM layoffs_staging
)
SELECT * 
FROM duplicate_data_cte
WHERE row_num > 1;

-- Verify duplicates in the CTE results
SELECT * 
FROM layoffs_staging
WHERE company = 'Cazoo';

-- Once confirmed, we can proceed with deleting duplicates.
-- Note: MySQL does not allow DELETE directly from a CTE.
-- Solution: Create a new staging table (layoffs_staging2) including 
-- the row_num column so that we can delete rows where row_num > 1.

--  Create a new staging table to store cleaned data (including row_num)
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data from layoffs_staging into layoffs_staging2
-- Add row numbers to help identify and remove duplicates
INSERT INTO layoffs_staging2
SELECT *, ROW_NUMBER() OVER(
PARTITION BY company, location, total_laid_off, `date`, percentage_laid_off, 
	industry, stage, funds_raised, country ORDER BY date DESC) as row_num
FROM layoffs_staging;

-- Verify that the data is successfully inserted
SELECT * 
FROM layoffs_staging2;

SELECT COUNT(*)
FROM layoffs_staging2;

-- Identify any remaining duplicates in the new table
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- ========================================================================================
-- STEP 3 – STANDARDIZE DATA
-- ========================================================================================

SELECT * 
FROM layoffs_staging2;
-- ----------------------------------------------------------------------------------------
-- CHECK EXTRA SPACES 
-- ----------------------------------------------------------------------------------------

-- Search for leading/trailing spaces
SELECT country
FROM layoffs_staging2
WHERE country != TRIM(country);

-- Search for internal multiple spaces
SELECT country
FROM layoffs_staging2
WHERE country LIKE '%  %';

-- Only company column has extra leading/trailing spaces.
-- Use trim() to remove extra spaces. 
UPDATE layoffs_staging2
SET company = trim(company);

-- ----------------------------------------------------------------------------------------
-- CHECK TYPOS OR INCONSISTENT ENTRIES 
-- ----------------------------------------------------------------------------------------

-- COMPANY COLUMN -------------------------------------------------------------------------

-- Scan distinct company names to identify typos and inconsistencies
SELECT DISTINCT company
FROM layoffs_staging2
ORDER BY company;

-- Check for entries containing the word 'copy' (possible duplicates)
SELECT DISTINCT *
FROM layoffs_staging2
WHERE company LIKE '%loop%';

-- Remove ' copy' suffix from company names (data entry duplication issue)
-- Affected rows: 5
UPDATE layoffs_staging2
SET company = REPLACE(company, ' copy', '')
WHERE company LIKE '% copy';

-- Inspect specific company entries that may have inconsistencies
SELECT *
FROM layoffs_staging2
WHERE company LIKE '%skip%';

-- Standardize company names: 'Skip the Dishes' and 'SkipTheDishes'
-- Update them as 'SkipTheDishes'
UPDATE layoffs_staging2
SET company = 'SkipTheDishes'
WHERE company = 'Skip the Dishes';

-- Standardize company names: Cult.fit and Curefit are same company; 
-- Update them to 'Cure.fit' - official parent company name
UPDATE layoffs_staging2
SET company = 'Cure.fit'
WHERE company IN ('Cult.fit', 'Curefit');

-- Standardize company names: 'Kape' and 'Kape Technologies' refer to the same company; 
-- Update them as 'Kape Technologies' - official full company name
UPDATE layoffs_staging2
SET company = 'Kape Technologies'
WHERE company = 'Kape';

-- Standardize company names: 'Loop' and 'LOOP' refer to the same company; 
-- Update them as 'Loop' - official company name
UPDATE layoffs_staging2
SET company = 'Loop'
WHERE company = 'LOOP';

-- Standardize company names: '7shifts' and '7Shifts' refer to the same company; 
-- Update them as '7shifts' - official company name
UPDATE layoffs_staging2
SET company = '7shifts'
WHERE company = '7Shifts';

-- Standardize company names: 'Mr Yum' and 'Mr. Yum' pertain to the same company. 
-- Update them as 'Mr Yum'.
UPDATE layoffs_staging2
SET company = 'Mr Yum'
WHERE company = 'Mr. Yum';

-- Update 'Deep Instict' to 'Deep Instinct'
UPDATE layoffs_staging2
SET company = 'Deep Instinct'
WHERE company = 'Deep Instict';

-- LOCATION COLUMN ------------------------------------------------------------------------

-- Scan distinct locations to identify typos and inconsistencies
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;

-- Inspect specific location entries that may have inconsistencies
SELECT *
FROM layoffs_staging2
WHERE location LIKE '%skip%';

-- Apply corrections to standardize location names

-- Standardize location column by removing ', Non-U.S.' suffix
-- since the country column already provides the official country
UPDATE layoffs_staging2
SET location = REPLACE(location, ', Non-U.S.', '')
WHERE location LIKE '%Non-U.S%';

-- Character Encoding Fix: Update 'DÃƒÂ¼sseldorf' and change it to 'Düsseldorf'
UPDATE layoffs_staging2
SET location = 'Düsseldorf'
WHERE location = 'DÃƒÂ¼sseldorf';

-- Character Encoding Fix: Update 'FÃƒÂ¸rde' and change it to 'Førde'.
UPDATE layoffs_staging2
SET location = 'Førde'
WHERE location = 'FÃƒÂ¸rde';

-- Character Encoding Fix: Update 'FlorianÃƒÂ³polis' and change it to 'Florianópolis'
UPDATE layoffs_staging2
SET location = 'Florianópolis'
WHERE location = 'FlorianÃƒÂ³polis';

-- Character Encoding Fix: Update 'MalmÃƒÂ¶' and change it to 'Malmö'
UPDATE layoffs_staging2
SET location = 'Malmö'
WHERE location = 'MalmÃƒÂ¶';

-- Character Encoding Fix: Update 'WrocÃ…â€šaw' and change it to 'Wrocław'
UPDATE layoffs_staging2
SET location = 'Wrocław'
WHERE location = 'WrocÃ…â€šaw';

-- Standardize location name 'Luxembourg, Raleigh' and change it to 'Luxembourg' 
-- for consistency
UPDATE layoffs_staging2
SET location = 'Luxembourg'
WHERE location = 'Luxembourg, Raleigh';

-- Standardize location name 'Melbourne, Victoria' and change it to 'Melbourne' 
-- for consistency
UPDATE layoffs_staging2
SET location = 'Melbourne'
WHERE location = 'Melbourne, Victoria';

-- Update location for 'The Org' company
-- Replace 'New Delhi, New York City' with 'New York City'
UPDATE layoffs_staging2
SET location = 'New York City'
WHERE company = 'The Org';

-- DATE COLUMN ----------------------------------------------------------------------------
-- Convert string-formatted dates (M/D/YYYY) into DATE data type values
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%c/%e/%Y');

-- Modify `date` column to DATE type 
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- INDUSTRY COLUMN ------------------------------------------------------------------------

-- Scan distinct industries to identify typos and inconsistencies
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Industry column mostly clean; no typos detected

-- STAGE COLUMN ---------------------------------------------------------------------------

-- Scan distinct stages to identify typos and inconsistencies
SELECT DISTINCT stage
FROM layoffs_staging2
ORDER BY stage;

-- No typos or obvious formatting issues found in stage column.

-- COUNTRY COLUMN -------------------------------------------------------------------------

-- Scan distinct industries to identify typos and inconsistencies
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Standardize country names: 'UAE' and 'United Arab Emirates' refer to the same country
-- Updated all entries to use the official full name 'United Arab Emirates'
UPDATE layoffs_staging2
SET country = 'United Arab Emirates'
WHERE country IN ('UAE', 'United Arab Emirates');

-- DATE_ADDED COLUMN ----------------------------------------------------------------------
-- Convert string-formatted dates (M/D/YYYY) into DATE data type values
UPDATE layoffs_staging2
SET date_added = STR_TO_DATE(date_added, '%c/%e/%Y');

-- Modify `date` column to DATE type 
ALTER TABLE layoffs_staging2
MODIFY COLUMN date_added DATE;

-- ========================================================================================
-- STEP 4 – HANDLE NULL AND BLANK VALUES WHERE APPLICABLE
-- ========================================================================================

-- HANDLE BLANK VALUES --------------------------------------------------------------------

-- Check columns with blank values
SELECT 
	SUM(CASE WHEN company = '' THEN 1 ELSE 0 END) AS company_blanks,
    SUM(CASE WHEN location = '' THEN 1 ELSE 0 END) AS location_blanks,
    SUM(CASE WHEN total_laid_off = '' THEN 1 ELSE 0 END) AS total_laid_off_blanks,
    SUM(CASE WHEN percentage_laid_off = '' THEN 1 ELSE 0 END) AS percentage_blanks,
    SUM(CASE WHEN industry = '' THEN 1 ELSE 0 END) AS industry_blanks,
    SUM(CASE WHEN stage = '' THEN 1 ELSE 0 END) AS stage_blanks,
    SUM(CASE WHEN funds_raised = '' THEN 1 ELSE 0 END) AS funds_raised_blanks,
    SUM(CASE WHEN country = '' THEN 1 ELSE 0 END) AS country_blanks
FROM layoffs_staging2;

-- Convert blank values to NULL for consistency
UPDATE layoffs_staging2
SET 
	location = NULLIF(location,''),
	total_laid_off = NULLIF(total_laid_off,''),
    percentage_laid_off = NULLIF(percentage_laid_off, ''),
    industry = NULLIF(industry, ''),
    stage = NULLIF(stage, ''),
    funds_raised = NULLIF(funds_raised, ''),
    country = NULLIF(country, '');

-- HANDLE NULL VALUES ---------------------------------------------------------------------

-- Count NULL values in every column
SELECT 
	SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS company_null,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS location_null,
    SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS total_laid_off_null,
    SUM(CASE WHEN `date` IS NULL THEN 1 ELSE 0 END) AS date_null,
    SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS percentage_laid_off_null,
    SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS industry_null,
    SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END) AS stage_null,
    SUM(CASE WHEN funds_raised IS NULL THEN 1 ELSE 0 END) AS funds_raised_null,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_null,
    SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) AS date_added_null
FROM layoffs_staging2;

-- LOCATION COLUMN ------------------------------------------------------------------------
SELECT *
FROM layoffs_staging2
WHERE location IS NULL;

-- One null value found under location column
-- Leaving as NULL due to no reference data.
SELECT *
FROM layoffs_staging2
WHERE company LIKE '%Hunt%';

-- TOTAL_LAID_OFF COLUMN ------------------------------------------------------------------------
-- Identify rows with NULL value for total_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;

-- 1482 null values found under total_laid_off
-- Update data type from TEXT to INT
ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off INT;

-- PERCENTAGE_LAID_OFF COLUMN -------------------------------------------------------------
-- Identify rows with NULL value for percentage_laid_off
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL;

-- 1588 null values found under percentage_laid_off
-- Update data type from TEXT to INT
ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DECIMAL(5,3);

-- TOTAL_LAID_OFF AND PERCENTAGE_LAID_OFF NULL
SELECT COUNT(*)
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Exclude 702 rows where both total_laid_off and percentage_laid_off were NULL
-- Reason: No numeric layoff data available; not useful for analysis
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- INDUSTRY COLUMN ------------------------------------------------------------------------
-- Identify rows with NULL industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Two null values found under industry
-- Leaving them as NULL due to no reference data.
SELECT *
FROM layoffs_staging2
WHERE company LIKE '%Eyeo%';

-- STAGE COLUMN ---------------------------------------------------------------------------
-- Identify rows with NULL stage
SELECT *
FROM layoffs_staging2
WHERE stage IS NULL;

-- Five null values found under stage column
-- Leaving them as NULL to preserve accuracy and data integrity.
-- Company funding stage may change over time.
SELECT *
FROM layoffs_staging2
WHERE company LIKE '%Zapp%';

-- FUNDS_RAISED COLUMN --------------------------------------------------------------------
-- Identify rows with NULL value for funds_raised
SELECT *
FROM layoffs_staging2
WHERE funds_raised IS NULL;

-- 487 null values found. These are left as NULL to preserve data integrity.
-- Update the data type from text to decimal
ALTER TABLE layoffs_staging2
MODIFY COLUMN funds_raised DECIMAL(15,2);

-- COUNTRY COLUMN -------------------------------------------------------------------------
-- Identify rows with NULL country
SELECT *
FROM layoffs_staging2
WHERE country IS NULL;

-- Two null values found under country
-- Check location column to determine correct country
SELECT *
FROM layoffs_staging2
WHERE location LIKE '%Montreal%';

-- Update country column based on verified location
-- Fit Analytics: location indicates Germany
UPDATE layoffs_staging2
SET country = 'Germany'
WHERE company = 'Fit Analytics'
AND country IS NULL;

-- Ludia: location indicates Canada
UPDATE layoffs_staging2
SET country = 'Canada'
WHERE company = 'Ludia'
AND country IS NULL;

-- ========================================================================================
-- STEP 5: REMOVE UNNECESSARY ROWS AND COLUMNS 
-- ========================================================================================

-- Delete row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;

-- ========================================================================================
-- Final clean dataset
-- Display all rows in descending order by date
-- Data cleaning is now complete
-- ========================================================================================
SELECT *
FROM layoffs_staging2
ORDER BY date DESC;

-- Data integrity check
SELECT 
	(SELECT COUNT(*) FROM layoffs_raw) - 
	(SELECT COUNT(*) FROM layoffs_staging2)
AS rows_removed;
-- 705 rows removed: 3 duplicates + 702 nulls (total_laid_off & percentage_laid_off)