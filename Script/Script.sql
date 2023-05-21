SELECT * 
FROM weekly_sales;


DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales AS
SELECT 
    STR_TO_DATE(week_date, '%d/%m/%y') week_date
	,FLOOR((DAYOFYEAR(STR_TO_DATE(week_date, '%d/%m/%y')) - 1) / 7) + 1  week_number /* To achieve the requirement in the question such that value from 
	the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc */
    ,MONTH(STR_TO_DATE(week_date, '%d/%m/%y')) month_number
    ,YEAR(STR_TO_DATE(week_date, '%d/%m/%y')) calendar_year
    ,region
    ,platform
    ,segment
	,CASE
		WHEN segment LIKE '%1' THEN 'Young Adults'
        WHEN segment LIKE '%2' THEN 'Middle Aged'
        WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
        ELSE "Unknown"
	 END "age_band"
	,CASE
		WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families'
		ELSE "Unknown"
	 END "demographic"
    ,customer_type
    ,transactions
    ,sales
    ,ROUND((sales / transactions), 2) avg_transaction
FROM weekly_sales
ORDER BY 1;

SELECT * 
FROM clean_weekly_sales;



-- DATA EXPLORATION

SELECT * 
FROM clean_weekly_sales;

-- 1. What day of the week is used for each week_date value?
SELECT 
	 DISTINCT DATE_FORMAT(week_date, '%W') day_used
FROM clean_weekly_sales; -- Monday


-- 2. What range of week numbers are missing from the dataset?
WITH RECURSIVE number_series AS
(
  SELECT 1 AS my_number 
  UNION ALL
  SELECT my_number + 1   
  FROM number_series
  WHERE my_number < 52
)
SELECT my_number
FROM number_series n
LEFT JOIN clean_weekly_sales s
  ON n.my_number = s.week_number
WHERE s.week_number IS NULL;

-- Weeks 1 to 11 and weeks 37 to 52 are missing in the week_number column

-- 3. How many total transactions were there for each year in the dataset?

SELECT
	 calendar_year
	,SUM(transactions) total_transactions 
FROM clean_weekly_sales
GROUP BY 1;

-- 4. What is the total sales for each region for each month?

SELECT
	 region
     ,month_number
	,SUM(sales) total_sales
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;


-- 5. What is the total count of transactions for each platform?

SELECT
	 platform
	,SUM(transactions) total_transactions 
FROM clean_weekly_sales
GROUP BY 1;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?

SELECT
	 calendar_year
	,month_number
	,MONTHNAME(week_date) month
	,SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) Retail_Sales
	,SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) Shopify_Sales
	,CONCAT(ROUND( 100 * SUM(CASE WHEN platform = 'Retail' THEN sales ELSE 0 END) / SUM(sales), 2), '%') pct_retail
	,CONCAT(ROUND( 100 * SUM(CASE WHEN platform = 'Shopify' THEN sales ELSE 0 END) / SUM(sales), 2), '%') pct_shopify 
FROM clean_weekly_sales
GROUP BY 1, 2, 3
ORDER BY 1,2;

-- 7. What is the percentage of sales by demographic for each year in the dataset?

SELECT
	 calendar_year
	,SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) Couples
	,SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) Families
	,SUM(CASE WHEN demographic = 'Unknown' THEN sales ELSE 0 END) "Unknown"
	,CONCAT(ROUND( 100 * SUM(CASE WHEN demographic = 'Couples' THEN sales ELSE 0 END) / SUM(sales), 2), '%') pct_couples
	,CONCAT(ROUND( 100 * SUM(CASE WHEN demographic = 'Families' THEN sales ELSE 0 END) / SUM(sales), 2), '%') pct_families
	,CONCAT(ROUND( 100 * SUM(CASE WHEN demographic = 'Unknown' THEN sales ELSE 0 END) / SUM(sales), 2), '%') pct_unknown 
FROM clean_weekly_sales
GROUP BY 1;

-- 8. Which age_band and demographic values contribute the most to Retail sales?

SELECT
	 age_band
	,demographic
	,SUM(sales) Retails_sales
    ,CONCAT(ROUND(100 * (SUM(sales) / SUM(SUM(sales)) OVER ()), 2), '%') pct_contribution
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY 1, 2
ORDER BY 3 DESC; -- Retirees and Families

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

-- No, we cannot. Since, we have gotten the weekly avg_trans, aggregating further to yearly with give an untrue output. 
-- We need to divide sales by transaction and group by year to get the true average transaction size for each year
SELECT
	 calendar_year
	,platform
	,ROUND(AVG(avg_transaction),0) AS avg_transaction_column
	,SUM(sales) / sum(transactions) AS avg_transaction_grouped
FROM clean_weekly_sales
GROUP BY 1, 2
ORDER BY 1, 2;


-- Before & After Analysis
/*
Taking the week_date value of 2020-06-15 as the baseline week where 
the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the 
period after the change and the previous week_date values would be before
*/

-- To get the week number corresponding to '2020-06-15'
SELECT 
  DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15' 
  AND calendar_year = '2020';


/*	1. What is the total sales for the 4 weeks before and after 2020-06-15? 
	What is the growth or reduction rate in actual values and percentage of sales?
*/

WITH cte AS (
SELECT
	SUM(CASE WHEN week_number BETWEEN 20 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 27 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
)
SELECT
	 before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,CONCAT(ROUND(100 *((after_change / before_change) - 1), 2), '%') pct_diff_after_change
FROM cte;

-- The were was a -1.15% decline in sales comparing 4 weeks before and after the change was introduced.

/*	2. What about the entire 12 weeks before and after?
*/

WITH cte AS (
SELECT
	SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
)
SELECT
	 before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,CONCAT(ROUND(100 *((after_change / before_change) - 1), 2), '%') pct_diff_after_change
FROM cte;

/*  Extending the date range to 12 weeks before and after the introduction of the chnage, 
we see a further sales decline of around a -2.14% .
 */

/*How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019? */


-- 4 weeks
WITH cte AS (
SELECT
	calendar_year
	,SUM(CASE WHEN week_number < 24 AND week_number >= 20 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 27 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
GROUP BY 1
)
SELECT
	 calendar_year
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,CONCAT(ROUND(100 *((after_change / before_change) - 1), 2), '%') pct_diff_after_change
FROM cte;


-- 12 weeks
WITH cte AS (
SELECT
	 calendar_year
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
GROUP BY 1
)
SELECT
	 calendar_year
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,CONCAT(ROUND(100 *((after_change / before_change) - 1), 2), '%') pct_diff_after_change
FROM cte;


-- Insights
/* 
*/

-- 4. Bonus Question
/* Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis? */

-- Region
WITH cte AS (
SELECT
	 region
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
GROUP BY 1
)
SELECT
	 region
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,ROUND(100 *((after_change / before_change) - 1), 2) pct_diff_after_change
FROM cte
ORDER BY 5 ASC;

-- Asia had the highest negative impact in 2020

-- platform
WITH cte AS (
SELECT
	 platform
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
GROUP BY 1
)
SELECT
	 platform
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,ROUND(100 *((after_change / before_change) - 1), 2) pct_diff_after_change
FROM cte
ORDER BY 5 ASC;


-- Retail had the highest negative impact in 2020

-- age_band
WITH cte AS (
SELECT
	 age_band
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
GROUP BY 1
)
SELECT
	 age_band
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,ROUND(100 *((after_change / before_change) - 1), 2) pct_diff_after_change
FROM cte
ORDER BY 5 ASC;

-- Middle Aged group had the highest negative impact in 2020


-- demographic
WITH cte AS (
SELECT
	 demographic
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
GROUP BY 1
)
SELECT
	 demographic
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,ROUND(100 *((after_change / before_change) - 1), 2) pct_diff_after_change
FROM cte
ORDER BY 5 ASC;

-- Family had the highest negative impact in 2020


-- customer_type
WITH cte AS (
SELECT
	 customer_type
	,SUM(CASE WHEN week_number BETWEEN 12 AND 23 THEN sales ELSE 0 END) before_change
    ,SUM(CASE WHEN week_number BETWEEN 24 AND 35 THEN sales ELSE 0 END) after_change
FROM clean_weekly_sales
WHERE calendar_year = '2020'
GROUP BY 1
)
SELECT
	 customer_type
	,before_change
    ,after_change
    ,after_change - before_change AS diff_after_change
    ,ROUND(100 *((after_change / before_change) - 1), 2) pct_diff_after_change
FROM cte
ORDER BY 5 ASC;

-- Guest had the highest negative impact in 2020