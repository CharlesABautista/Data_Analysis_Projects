-- SELECT DISTINCT(street), COUNT(*)
-- FROM evanston311
-- GROUP BY street
-- ORDER BY street;

-- Remove the house numbers, extra punctuation, and any spaces from the 
-- beginning and end of the street values as a first attempt at cleaning 
-- up the values.

-- SELECT DISTINCT street

-- FROM evanston311
-- ORDER BY street;


-- SELECT * FROM evanston311 LIMIT 1;

-- Count rows where the description includes 'trash' or 
-- 'garbage' but the category does not.


-- SELECT COUNT(*)
-- FROM evanston311
-- WHERE (description ILIKE '%trash%' OR description ILIKE '%garbage%')
-- 	AND category NOT LIKE '%Trash%' AND category NOT LIKE '%Garbage%'

	
-- Find the most common categories for rows with a description 
-- about trash that don't have a trash-related category.
-- -- Count rows with each category
-- SELECT category, COUNT(*)
--   FROM evanston311 
--  WHERE (description ILIKE '%trash%'
--     OR description ILIKE '%garbage%') 
--    AND category NOT LIKE '%Trash%'
--    AND category NOT LIKE '%Garbage%'
--  -- What are you counting?
--  GROUP BY category
--  ORDER BY count DESC
--  LIMIT 10;


-- SELECT (CONCAT(house_num, ' ', street)) AS address
--   FROM evanston311;

-- SELECT split_part(street, ' ', 1) as street_name, COUNT(*)
-- FROM evanston311
-- GROUP BY street_name
-- ORDER BY street_name DESC
-- LIMIT 20;

-- SELECT CASE WHEN length(description) > 50 THEN concat(left(description, 50), '...')
-- 			ELSE description END
-- FROM evanston311
-- WHERE ltrim(split_part(description, ' ', 1)) = 'I'
-- ORDER BY description;

-- Fill in the command below with the name of the temp table
-- DROP TABLE IF EXISTS recode;

-- -- Create and name the temporary table
-- CREATE TEMP TABLE recode AS
-- -- Write the select query to generate the table with distinct values of category and standardized values
--   SELECT DISTINCT category, 
--          rtrim(split_part(category, '-', 1)) AS standardized
--     -- What table are you selecting the above values from?
--     FROM evanston311;
    
-- -- Look at a few values before the next step
-- SELECT DISTINCT standardized 
--   FROM recode 
--  WHERE standardized LIKE 'Trash%Cart'
--     OR standardized LIKE 'Snow%Removal%';


-- -- Code from previous step
-- DROP TABLE IF EXISTS recode;

-- CREATE TEMP TABLE recode AS
--   SELECT DISTINCT category, 
--          rtrim(split_part(category, '-', 1)) AS standardized
--     FROM evanston311;

-- -- Update to group trash cart values
-- UPDATE recode 
--    SET standardized='Trash Cart' 
--  WHERE standardized LIKE 'Trash%Cart';

-- -- Update to group snow removal values
-- UPDATE recode 
--    SET standardized='Snow Removal' 
--  WHERE standardized LIKE 'Snow%Removal%';
    
-- -- Examine effect of updates
-- SELECT  standardized 
--   FROM recode
--  WHERE standardized LIKE 'Trash%Cart'
--     OR standardized LIKE 'Snow%Removal%';

-- UPDATE recode
-- SET standardized = 'UNUSED'
-- WHERE standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart',
-- 						'(DO NOT USE) Water Bill',
-- 						'DO NOT USE Trash',
-- 						'NO LONGER IN USE');

-- SELECT category, standardized
-- FROM recode
-- ORDER BY standardized;

-- SELECT standardized, COUNT(*)
-- FROM evanston311
-- LEFT JOIN recode
-- ON evanston311.category = recode.category
-- GROUP BY standardized
-- ORDER BY COUNT(*) DESC;
-- To clear table if it already exists
-- DROP TABLE IF EXISTS indicators;

-- -- Create the indicators temp table
-- Create temp table indicators AS
--   -- Select id
--   SELECT id, 
--          -- Create the email indicator (find @)
--          CAST (description LIKE '%@%'  AS integer) AS email,
--          -- Create the phone indicator
--          CAST(description like '%___-___-____%' AS int) AS phone 
--     -- What table contains the data? 
--     FROM evanston311;

-- -- Inspect the contents of the new temp table
-- SELECT *
--   FROM indicators;

-- -- Select the column you'll group by
-- SELECT priority,
--        -- Compute the proportion of rows with each indicator
--        SUM(email)/COUNT(*)::decimal AS email_prop, 
--        SUM(phone)/COUNT(*)::decimal AS phone_prop
--   -- Tables to select from
-- FROM evanston311 
-- LEFT JOIN indicators ON evanston311.id = indicators.id
--  -- What are you grouping by?
--  GROUP BY priority;

SELECT date_part('hour', date_created) AS hour,
       count(*)
  FROM evanston311
 GROUP BY hour
 -- Order results to select most common
 ORDER BY count(*) desc
 
 LIMIT 1;


SELECT date_part('hour', date_created) as hour, COUNT(*)
FROM evanston311
GROUP BY hour
ORDER BY COUNT(*) DESC
LIMIT 1;


SELECT to_char(date_created, 'day') as day,
		avg(date_completed - date_created) as duration

FROM evanston311
GROUP BY day, EXTRACT(DOW FROM date_created)
ORDER BY EXTRACT(DOW FROM date_created);


-- Using date_trunc(), find the average number of Evanston 311 requests 
-- created per day for each month of the data. Ignore days with 
-- no requests when taking the average.
-- Aggregate daily counts by month
-- SELECT date_trunc('month', day) as month, avg(count)
-- FROM
-- 		(SELECT date_trunc('day', date_created) as day, COUNT(*) as count
-- 		FROM evanston311
-- 		GROUP BY day 
-- 			) AS daily_count		 

-- GROUP BY month
-- ORDER BY month;


-- SELECT day
-- FROM	(
-- 	SELECT generate_series(min(date_created), max(date_created), '1 day')::date AS day
-- 	FROM evanston311) AS all_dates

-- 	WHERE day NOT IN (SELECT date_created::date
-- 			FROM evanston311);

-- Bins from Step 1
WITH bins AS (
	 SELECT generate_series('2016-01-01',
                            '2018-01-01',
                            '6 months'::interval) AS lower,
            generate_series('2016-07-01',
                            '2018-07-01',
                            '6 months'::interval) AS upper),
-- Daily counts from Step 2
     daily_counts AS (
     SELECT day, count(date_created) AS count
       FROM (SELECT generate_series('2016-01-01',
                                    '2018-06-30',
                                    '1 day'::interval)::date AS day) AS daily_series
            LEFT JOIN evanston311
            ON day = date_created::date
      GROUP BY day)
-- Select bin bounds 
SELECT lower, 
       upper, 
       -- Compute median of count for each bin
       percentile_disc(0.5) WITHIN GROUP (ORDER BY count) AS median
  -- Join bins and daily_counts
  FROM bins
       LEFT JOIN daily_counts
       -- Where the day is between the bin bounds
       ON day >= lower
          AND day < upper
 -- Group by bin bounds
 GROUP BY lower, upper
 ORDER BY lower;


-- generate series with all days from 2016-01-01 to 2018-06-30
WITH all_days AS 
     (SELECT generate_series('2016-01-01',
                             '2018-06-30',
                             '1 day'::interval) AS date),
     -- Subquery to compute daily counts
     daily_count AS 
     (SELECT date_trunc('day', date_created) AS day,
             count(*) AS count
        FROM evanston311
       GROUP BY day)
-- Aggregate daily counts by month using date_trunc
SELECT date_trunc('month', date) AS month,
       -- Use coalesce to replace NULL count values with 0
       avg(coalesce(count, 0)) AS average
  FROM all_days
       LEFT JOIN daily_count
       -- Joining condition
       ON all_days.date=daily_count.day
 GROUP BY month
 ORDER BY month; 

-- Compute the gaps
WITH request_gaps AS (
        SELECT date_created,
               -- lead or lag
               lag(date_created) OVER (ORDER BY date_created) AS previous,
               -- compute gap as date_created minus lead or lag
               date_created - lag(date_created) OVER (ORDER BY date_created) AS gap
          FROM evanston311)
-- Select the row with the maximum gap
SELECT *
  FROM request_gaps
-- Subquery to select maximum gap from request_gaps
 WHERE gap = (SELECT MAX(gap)
                FROM request_gaps);


 -- Truncate the time to complete requests to the day
SELECT date_trunc('day', date_completed -  date_created) AS completion_time,
-- Count requests with each truncated time
       COUNT(*)
  FROM evanston311
-- Where category is rats
 WHERE category = 'Rodents- Rats'
-- Group and order by the variable of interest
 GROUP BY completion_time
 ORDER BY completion_time;

 -- Compute average completion time per category excluding 
 -- the longest 5% of requests (outliers).

--  SELECT category,
--  		AVG(date_trunc('day', day_completed - day_created))

-- FROM evanston311
-- WHERE 


SELECT category, AVG(date_completed - date_created) as avg_completion_time
FROM evanston311
WHERE (date_completed - date_created) < 
(SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY (date_completed - date_created)) 
FROM evanston311)
GROUP BY category
ORDER BY avg_completion_time DESC;

-- Get corr() between avg. completion time and monthly requests.
-- EXTRACT(epoch FROM interval) returns seconds in interval.


SELECT 
avg_completion, count
-- corr(avg_completion, count)

FROM 
(
SELECT  
date_trunc('month', date_created) as month,
AVG(EXTRACT(epoch FROM date_completed - date_created)) as avg_completion,
COUNT(*) as count
FROM evanston311
WHERE category = 'Rodents- Rats' 
GROUP BY month) AS monthly_avgs
;

-- Select the number of requests created and number of 
-- requests completed per month.
