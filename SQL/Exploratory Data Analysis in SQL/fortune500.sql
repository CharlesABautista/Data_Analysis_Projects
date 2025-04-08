-- -- SELECT (COUNT(*) - COUNT(ticker)) AS MISSING	
-- -- FROM fortune500;

-- -- SELECT (COUNT(*) - COUNT(industry)) AS MISSING	
-- -- FROM fortune500;

-- SElECT c.name 
-- FROM company AS c
-- INNER JOIN fortune500 AS f ON c.ticker = f.ticker; 

-- -- SELECT * FROM fortune500 LIMIT 5;
-- -- SELECT * FROM company;

-- SELECT * FROM stackoverflow LIMIT 5;


-- -- 
-- SELECT type, COUNT(tag) AS count
-- FROM tag_type 
-- GROUP BY type
-- ORDER BY count;

-- SELECT c.name AS companies, tt.tag, tt.type
-- FROM company AS c
-- INNER JOIN tag_company AS tc ON c.id = tc.company_id
-- INNER JOIN tag_type AS tt ON tt.tag = tc.tag
-- WHERE tt.type = (SELECT type
-- 	FROM tag_type 
-- 	GROUP BY type```
-- 	ORDER BY COUNT(tag) DESC
-- 	LIMIT 1)
-- ;

-- SELECT *
-- FROM fortune500;

--Check for 2016-2017 revenues_change and explore distribution of fortune500 companies

-- SELECT revenues_change::integer, COUNT(*) as companies
-- FROM fortune500
-- WHERE revenues_change > 0
-- GROUP BY revenues_change::integer
-- ORDER BY revenues_change DESC
-- ;


-- SELECT COUNT(*) as companies
-- FROM fortune500
-- WHERE revenues_change > 0
-- ;



-- -- ave reven per employee in each company by sector
-- SELECT avg(revenues/employees::numeric) AS average_revenue, sector
-- FROM fortune500
-- GROUP by sector
-- ORDER BY average_revenue DESC
-- ; 

-- select unanswered_count/question_count::decimal, unanswered_pct
-- from stackoverflow 
-- WHERE question_count != 0
-- ;


-- select 
--   sector,
-- 	min(profits),
-- 	max(profits),
-- 	avg(profits),
-- 	stddev(profits)
-- from fortune500
--  -- What to group by?
--  GROUP BY sector
--  -- Order by the average profits
--  ORDER BY avg(profits);


-- What is the standard deviation across tags in the maximum number
-- of Stack Overflow questions per day? 
-- What about the mean, min, and max of the maximums as well?

-- Compute standard deviation of maximum values
-- SELECT stddev(maxval),
-- 	   -- min
--        min(maxval),
--        -- max
--        max(maxval),
--        -- avg
--        avg(maxval)
--   -- Subquery to compute max of question_count by tag
--   FROM (SELECT max(question_count) AS maxval
--           FROM stackoverflow
--          -- Compute max by...
--          GROUP BY tag) AS max_results; -- alias for subquery



-- -- Truncate employees
-- SELECT TRUNC(employees, -5) AS employee_bin,
--        -- Count number of companies with each truncated value
--        COUNT(*)
--   FROM fortune500
--  -- Use alias to group
--  GROUP BY employee_bin
--  -- Use alias to order
--  ORDER BY employee_bin;

-- SELECT TRUNC(employees, -4) AS employees_bin, COUNT(*)
-- FROM fortune500
-- WHERE employees < 100000
-- GROUP BY employees_bin
-- ORDER BY employees_bin
-- ;



-- Summarize the distribution of the number of questions 
-- with the tag "dropbox" on Stack Overflow per day by binning the data.

-- WITH dropbox AS (
-- 	SELECT question_count
			
-- 	FROM stackoverflow
-- 	WHERE tag = 'dropbox'),


-- -- -- Create lower and upper bounds of bins
-- 	bins AS (SELECT generate_series(2200, 3100-50, 50) AS lower,
-- 	       generate_series(2200+50, 3100, 50) AS upper)

-- SELECT lower, upper, COUNT(question_count)
-- FROM bins
-- LEFT JOIN dropbox ON 
-- 	question_count >= lower AND question_count < upper
-- GROUP BY lower, upper
-- ORDER BY upper	

-- ;




-- Compute the correlation between revenues and profits.
-- Compute the correlation between revenues and assets.
-- Compute the correlation between revenues and equity.
-- SELECT 
-- 	CORR(revenues,profits) AS rev_profits,
-- 	CORR(revenues,assets) AS rev_assets,
-- 	CORR(revenues,equity) AS rev_equity
-- FROM fortune500;



-- Compute the mean and median assets of Fortune 500 companies by sector
-- SELECT
-- 	sector,
-- 	avg(assets) AS mean,
-- 	percentile_disc(.5) WITHIN GROUP (ORDER BY assets) AS median
-- FROM fortune500
-- GROUP BY sector
-- ORDER BY mean;



-- Find the Fortune 500 companies that have profits in the top 20% for their sector (compared to other Fortune 500 companies).
-- To do this, first, find the 80th percentile of profit for each sector with

DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS
  SELECT sector, 
         percentile_disc(0.8) WITHIN GROUP (ORDER BY profits) AS pct80
    FROM fortune500 
   GROUP BY sector;

-- -- Select columns, aliasing as needed
-- SELECT title, fortune500.sector, 
--        profits, profits/pct80 AS ratio
-- -- What tables do you need to join?  
--   FROM fortune500 
--        LEFT JOIN profit80
-- -- How are the tables joined?
--        ON fortune500.sector=profit80.sector
-- -- What rows do you want to select?
--  WHERE profits > pct80;



-- The Stack Overflow data contains daily question counts through 
-- 2018-09-25 for all tags, but each tag has a different starting date
-- in the data.
-- Find out how many questions had each tag on the first date 
-- for which data for the tag is available, as well as how many 
-- questions had the tag on the last day. Also, compute the 
-- difference between these two values.

-- DROP TABLE IF EXISTS startdates;

-- CREATE TEMP TABLE startdates AS

-- SELECT tag, min(date) as mindate
-- FROM stackoverflow
-- GROUP BY tag;


-- SELECT startdates.tag, mindate, so_min.question_count as min_date_question_count
-- , so_max.question_count as max_date_question_count,
-- (so_max.question_count - so_min.question_count) AS change

-- FROM startdates
-- INNER JOIN stackoverflow as so_min
-- ON startdates.tag = so_min.tag AND startdates.mindate = so_min.date
-- INNER JOIN stackoverflow as so_max 
-- ON startdates.tag = so_max.tag AND so_max.date = '2018-09-25'

DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;

-- Select each column, rounding the correlations
SELECT measure, 
       round(profits::decimal, 2) AS profits,
       round(profits_change::decimal, 2) AS profits_change,
       round(revenues_change::decimal, 2) AS revenues_change
  FROM correlations;