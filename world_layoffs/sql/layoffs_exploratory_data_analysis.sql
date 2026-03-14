-- =====================================================================================================================
-- 			             				  EXPLORATORY DATA ANALYSIS (EDA)
--                                                WORLD_LAYOFFS
-- =====================================================================================================================
use layoffs_analytics;

-- --------------------------------------------- EDA FRAMEWORK ---------------------------------------------------------
-- 1.) Structure Overview
-- 2.) Time Coverage
-- 3.) Overall Impact
-- 4.) Company Analysis
-- 5.) Industry Analysis
-- 6.) Geographic Analysis
-- 7.) Stage and Funding Analysis
-- 8.) Extreme Cases
-- 9.) Trend Analysis
-- 10.) Key Insights Summary
-- ---------------------------------------------------------------------------------------------------------------------

-- =====================================================================================================================
-- 1.) STRUCTURE OVERVIEW
-- =====================================================================================================================

-- Q: How big is the dataset before and after cleaning? ----------------------------------------------------------------
	SELECT 
		(SELECT COUNT(*) FROM layoffs_raw) AS total_rows_raw,
		(SELECT COUNT(*) FROM layoffs_staging2) AS total_rows_cleaned;

-- RESULTS / INSIGHTS:
-- The raw dataset contains 4,299 records.
-- After data cleaning, the dataset was reduced to 3,594 records.
-- A total of 705 records were removed due to duplicates, missing/null values,
-- and data standardization processes.

-- Q: What column exists? ----------------------------------------------------------------------------------------------
	SELECT *
	FROM layoffs_staging2
	LIMIT 10;

-- RESULTS / INSIGHTS:
-- company, location, total_laid_off, date, industry, percentage_laid_off,
-- source, stage, funds_raised, country, date_added

-- =====================================================================================================================
-- 2.) TIME COVERAGE
-- =====================================================================================================================

-- Q: What is the date range of the dataset? ---------------------------------------------------------------------------
	SELECT MIN(date) AS start_date, MAX(date) AS end_date
	FROM layoffs_staging2;
    
-- RESULTS / INSIGHTS:
-- Date range is from 2020-03-11 to 2026-02-20.

-- ======================================================================================================================
-- 3.) OVERALL IMPACT
-- ======================================================================================================================

-- Q: What are the total layoffs, total layoff events, and the ave layoffs per company? ---	
	WITH company_totals_cte AS 
	(
		SELECT company, SUM(total_laid_off) AS company_layoffs	
		FROM layoffs_staging2
		GROUP BY company
	)
	SELECT 
		COUNT(*) AS total_companies,
		(SELECT COUNT(*) FROM layoffs_staging2) AS total_layoff_events,
		SUM(company_layoffs) AS total_layoffs,
		AVG(company_layoffs) AS avg_layoffs_per_company
	FROM company_totals_cte;			
    
-- RESULTS / INSIGHTS:
-- There are 2,481 companies in the dataset,
-- with a total of 829,853 layoffs and 3,594 layoff events.
-- On average, each company laid off 427 employees.

-- =====================================================================================================================
-- 4.) COMPANY ANALYSIS
-- =====================================================================================================================

 -- Q: What are the top 5 companies with largest layoff counts? --------------------------------------------------------
	 SELECT 
		company AS company_name, 
		COUNT(company) AS layoff_events,
		SUM(total_laid_off) AS total_layoffs,
        SUM(total_laid_off) / (SUM(SUM(total_laid_off)) OVER()) *100 AS pc_total,
		ROUND(SUM(SUM(total_laid_off)) OVER(ORDER BY SUM(total_laid_off) DESC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0
				/ SUM(SUM(total_laid_off)) OVER(), 2) AS pc_cum_total
	 FROM layoffs_staging2
	 GROUP BY company
	 ORDER BY total_layoffs DESC, layoff_events DESC
	 LIMIT 5;
     
-- RESULTS / INSIGHTS:
-- Amazon has the highest number of layoffs (58024) across 12 layoff events,
-- followed by Intel, Microsoft, Meta and Salesforce.

-- Q: What are the top 5 companies with highest frequency of layoff events? --------------------------------------------
	SELECT company AS company_name, 
		COUNT(company) AS layoff_events,
		SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging2
	GROUP BY company
	ORDER BY layoff_events DESC, total_layoffs DESC
	LIMIT 5;
    
-- RESULTS / INSIGHTS:
-- Amazon and Salesforce have the highest number of layoff events (12 each).
-- Followed by Rivian (11), Microsoft(10) and Google (10).
-- Though the total layoffs for these companies vary, they experienced frequent workforce
-- reductions, indicating repeated workforce adjustments. 

-- OVERALL INSIGHT:
-- Higher layoff frequency does not always mean larger total layoffs, 
-- because some companies had fewer layoff events but larger layoff number, 
-- while others had more frequent but smaller ones.

-- =====================================================================================================================
-- 5.) INDUSTRY ANALYSIS
-- =====================================================================================================================

-- Q: Which industries have experienced the highest number of layoffs? -------------------------------------------------
	WITH industry_analysis_cte AS
	(
		SELECT 
			industry, 
            SUM(total_laid_off) AS total_layoffs,
			COUNT(*) AS layoff_events,
			ROUND(AVG(total_laid_off), 0) AS avg_layoff_size,
			
			-- Individual contribution %
			ROUND(SUM(total_laid_off) * 100.0 / SUM(SUM(total_laid_off)) OVER(), 2) AS percent_of_total,

			-- Cumulative total
			SUM(SUM(total_laid_off)) OVER(ORDER BY SUM(total_laid_off) DESC
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_layoffs,

			-- Cumulative %
			ROUND(SUM(SUM(total_laid_off)) OVER(ORDER BY SUM(total_laid_off) DESC
					ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0
					/ SUM(SUM(total_laid_off)) OVER(), 2) AS cumulative_percentage

		FROM layoffs_staging2
		WHERE industry IS NOT NULL
		GROUP BY industry
	)
	SELECT *,
		   RANK() OVER(ORDER BY total_layoffs DESC) AS ranking
	FROM industry_analysis_cte
	ORDER BY avg_layoff_size DESC;

-- RESULTS / INSIGHTS:
-- 1. Top 5 industries with highest total layoffs are: Retail, Hardware, Other, Consumer, Transportation 
-- 2. Retail is the most affected industry, contributing 12.59% of total layoffs.
-- 3. Although Hardware ranks second in total layoffs, it has significantly fewer layoff events 
-- compared to other top industries, suggesting larger layoffs per event.
-- 4. Cumulative percentages show that top 5 industries account for ~50–55% of all layoffs.

-- 2023 HIGHLIGHTS -----------------------------------------------------------------------------------------------------

-- Q: Which industries have the highest layoffs during 2023?
SELECT 	
		industry, 
        SUM(total_laid_off) AS total_layoffs,
        COUNT(*) AS layoff_events,
        SUM(total_laid_off) * 100.0  / SUM(SUM(total_laid_off)) OVER() AS percent_total_2023
FROM layoffs_staging2
WHERE YEAR(`date`) = 2023 AND industry IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;

-- RESULTS / INSIGHTS:
-- In 2023, the industries with the highest layoffs were Other (38,687; 14.6%), Retail (32,133; 12.2%), 
-- and Consumer (30,303; 11.5%). Finance and Healthcare had more frequent layoff events (140 and 108) 
-- but lower total layoffs, indicating smaller-scale events.

-- =====================================================================================================================
-- 6.) GEOGRAPHIC ANALYSIS
-- =====================================================================================================================

-- Q: What is the distribution of layoffs by country? ------------------------------------------------------------------
	SELECT country, 
			COUNT(*) AS layoff_events, 
			SUM(total_laid_off) AS total_layoffs,
			ROUND(AVG(total_laid_off), 0) AS avg_layoff_size,
			SUM(total_laid_off) * 100 / SUM(SUM(total_laid_off)) OVER() AS percent_of_total
	FROM layoffs_staging2
	WHERE (country IS NOT NULL) AND (country != '')
	GROUP BY country
	ORDER BY total_layoffs DESC;    
    
-- RESULT / INSIGHT:
-- 1. The United States dominates global layoffs, accounting for nearly 70% of total reported layoffs.
-- 2. India follows, accounting 7.81% of the global layoffs which is much smaller than USA.
-- 3. Although the Netherlands has relatively few layoff events (24), it has the highest average
-- layoff size (1136 per event), indicating fewer but more severe layoff events. 

-- Q: Which cities are most affected by layoffs worldwide based on total layoffs? --------------------------------------
	SELECT 	country, 
			location, 
            SUM(total_laid_off) AS total_layoffs,
            SUM(total_laid_off) * 100 / SUM(SUM(total_laid_off)) OVER() AS percent_total
	FROM layoffs_staging2
	WHERE (location IS NOT NULL) AND (country IS NOT NULL)
	GROUP BY country, location
	ORDER BY total_layoffs DESC;
    
-- RESULTS / INSIGHTS:
-- The SF Bay Area is the most affected city globally, accounting for 30.84% of total layoffs.
-- It is followed by the U.S. city of Seattle, which accounts for 12.39% of total layoffs.
-- Other cities, including New York City, Bengaluru, and Austin, have significantly smaller shares, 
-- indicating that layoffs are particularly concentrated in SF Bay Area and Seattle.

-- =====================================================================================================================
-- 7.) STAGE AND FUNDING ANALYSIS
-- =====================================================================================================================

-- Q: Which funding stage experiences the most layoffs? ----------------------------------------------------------------
	SELECT stage,
		   COUNT(*) AS layoff_events,
		   SUM(total_laid_off) AS total_layoffs,
		   ROUND(AVG(total_laid_off),0) AS avg_layoff_size,
		   SUM(total_laid_off) * 100 / SUM(SUM(total_laid_off)) OVER() AS percent_total
	FROM layoffs_staging2
	WHERE stage IS NOT NULL AND stage != ''
	GROUP BY stage
	ORDER BY total_layoffs DESC;

-- RESULTS / INSIGHTS:
-- Post-IPO stage dominates all other stages in terms of total layoffs, layoff frequency, and average layoff size.
-- It has 502,606 total layoffs across 867 events, accounting for 60.57% of global layoffs, 
-- with an average of 708 layoffs per event — indicating both frequent and large-scale layoffs.
-- Other stages, such as Unknown (76,957 layoffs, 9.27%) and Acquired (71,153 layoffs, 8.57%), 
-- have significantly smaller impact.

-- Q: Which funding range experiences the highest total layoffs? -------------------------------------------------------
	SELECT 
		CASE 
			WHEN funds_raised <= 1 THEN 'a. 0-1M'
			WHEN funds_raised <= 10 THEN 'b. 1-10M'
			WHEN funds_raised <= 50 THEN 'c. 10-50M'
			WHEN funds_raised <= 100 THEN 'd. 50-100M'
			WHEN funds_raised <= 500 THEN 'e. 100-500M'
			WHEN funds_raised <= 1000 THEN 'f. 500-1000M'
			ELSE 'g. More than 1B'
		END AS funding_range,
		COUNT(*) AS layoff_events,
		SUM(total_laid_off) AS total_layoffs,
		ROUND(AVG(total_laid_off),0) AS avg_layoff_size
	FROM layoffs_staging2
	WHERE funds_raised IS NOT NULL
	GROUP BY funding_range
	ORDER BY funding_range;

-- RESULTS / INSIGHTS:
-- Companies with funding above $1B experience the highest total layoffs (246,625), with an average of 707 layoffs per event.
-- Mid-funded companies in the 100-500M range have the most frequest layoff events (1255) but smaller layoffs per event(172). 
-- Early stage companies (0-1M) have fewer layoff events but each event is extremely large, averaging 1103 layoffs. 

-- =====================================================================================================================
-- 8.) EXTREME CASES
-- =====================================================================================================================

-- Q: How many layoff events involved the entire workforce? (excluding NULLs) ------------------------------------------
	SELECT COUNT(*) AS total_100_percent_layoffs
	FROM layoffs_staging2
	WHERE percentage_laid_off = 1
	  AND total_laid_off IS NOT NULL;
    
-- Q: Which industries were mostly affected by 100% workforce reduction? (excluding NULLs) ------------------------------
	SELECT 
		industry, 
		SUM(total_laid_off) AS total_layoffs,
		ROUND(AVG(total_laid_off),0) AS avg_layoff_size,
		COUNT(total_laid_off) AS layoff_events,  -- counts only non-NULL
		ROUND(COUNT(total_laid_off) * 100.0 / SUM(COUNT(total_laid_off)) OVER(),2) AS percent_total
	FROM layoffs_staging2
	WHERE percentage_laid_off = 1
	  AND total_laid_off IS NOT NULL
	GROUP BY industry
	ORDER BY layoff_events DESC;
    
-- RESULTS / INSIGHTS:
-- There were 87 layoff events where companies laid off 100% of their workforce.
-- The Healthcare, Retail, and Food industries were the top contributors, each with 10 events.
-- Construction had only 1 event but a very high total number of layoffs (2,434), indicating 
-- extremely high-intensity reduction in that case.

-- Q: Check smallest and largest 100% layoffs per industry, excluding NULLs --------------------------------------------
	SELECT 
        industry,
		MIN(total_laid_off) AS min_layoffs,
		MAX(total_laid_off) AS max_layoffs,
		ROUND(AVG(total_laid_off),2) AS avg_layoffs,
		COUNT(*) AS layoff_events
	FROM layoffs_staging2
	WHERE percentage_laid_off = 1
	  AND total_laid_off IS NOT NULL
	GROUP BY industry
	ORDER BY max_layoffs DESC;

-- RESULTS / INSIGHTS:
-- Construction had only 1 event but extremely high total layoffs (2434).
-- Crypto and Aerospace also had few event but very large layoffs per event. 
-- In contrast, Food, Retail and Healthcare, had many events with smaller layoff total
-- showing frequest but smaller workforce reductions. 

-- =====================================================================================================================
-- 8.) TREND ANALYSIS
-- =====================================================================================================================

-- Q: What is the yearly layoff trend in the dataset? ------------------------------------------------------------------
	SELECT 
		YEAR(`date`) AS year, 
        SUM(total_laid_off) AS total_layoffs,
        COUNT(*) AS layoff_events
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY year
    ORDER BY year DESC;
    
-- RESULTS / INSIGHTS:
-- 1. 2023 recorded the highest total layoffs (264,320) and the highest number of layoff events (846), 
-- making it the peak year in the dataset.
-- 2. 2022 had a similar number of layoff events (819), but the total layoffs (164,319) were significantly lower 
-- than in 2023. This suggests that layoffs in 2023 were larger in scale per event.
-- 3. Other years show substantially lower totals and event counts, suggesting that the 
-- most significant workforce reductions occurred primarily between 2022 and 2023.

-- Q: How did the total layoffs changed year-over-year? ----------------------------------------------------------------
	WITH yearly_layoffs_cte AS 
    (
		SELECT 
			YEAR(`date`) AS year,
			SUM(total_laid_off) AS total_layoffs
		FROM layoffs_staging2
		WHERE total_laid_off IS NOT NULL
		GROUP BY year
	)
    SELECT year,
			total_layoffs,
            ROUND(
				
                (total_layoffs - LAG(total_layoffs) OVER(ORDER BY year))
				/ LAG(total_layoffs) OVER (ORDER BY year) * 100, 
            2) AS yoy_percent_change
    FROM yearly_layoffs_cte;

-- RESULTS / INSIGHTS:
-- 2021 experienced an 80% decline in layoffs compared to 2020.
-- 2022 saw the most dramatic increase, with layoffs growing by 938% year-over-year.
-- Layoffs continued increasing in 2023, reaching the highest total in the dataset.
-- From 2024 onward, layoffs declined consistently, indicating a possible stabilization phase.

-- 2023 HIGHLIGHTS -----------------------------------------------------------------------------------------------------

-- Q: Which month in 2023 has the highest layoffs?
SELECT
		DATE_FORMAT(`date`, '%Y-%m') AS month_year, 
        SUM(total_laid_off) AS total_layoffs,
        SUM(total_laid_off) * 100.0 / SUM(SUM(total_laid_off)) OVER() AS percent_total_2023
FROM layoffs_staging2
WHERE YEAR(`date`) = 2023
GROUP BY month_year
ORDER BY total_layoffs DESC;

-- RESULTS / INSIGHTS:
-- January is the peak month with 33.94% of total 2023 layoffs,
-- followed by February and March, showing that layoffs were concentrated in Q1 2023.

-- =====================================================================================================================
-- 10.) KEY INSIGHTS SUMMARY 
-- =====================================================================================================================
-- 1. The dataset has 3,594 layoff events from 2,481 companies, covering 2020 to 2026.
--    Total layoffs worldwide are 829,853.
-- 2. Most layoffs happened in the United States, especially in the SF Bay Area and Seattle.
-- 3. Retail, Hardware, and Consumer industries had the most layoffs.
-- 4. Big companies, especially Post-IPO and those with over $1B funding, had the largest layoffs.
-- 5. Some extreme cases show companies laying off 100% of their workforce, mostly in Healthcare, Retail, and Food.
-- 6. Yearly trend:
--      • 2021: big drop in layoffs (-80%)
--      • 2022: huge increase (+938%)
--      • 2023: peak layoffs (264,320)
--    		– Top industries: Other, Retail, Consumer
--          – Peak month: January (33.9% of 2023 layoffs)
--      • 2024–2026: layoffs gradually went down
-- 7. Overall pattern: layoffs spike in certain years and industries, then slowly decrease, showing a cycle.