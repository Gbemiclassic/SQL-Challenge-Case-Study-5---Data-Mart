# <p align="center" style="margin-top: 0px;"> Maven Fuzzy Factory
## <p align="center">  Mid Course Project




### 1. Gsearch seems to be the biggest driver of our business. Could you pull monthly trends for gsearch sessions and orders so that we can showcase the growth there?

Steps:

* Left Join the website_sessions table to the orders table to get sessions resulted orders
* Use COUNT DISTINCT to get the number of sessions and orders
* Filter the utm_source to inlcude 'gsearch' only

```sql
SELECT
	YEAR(w.created_at) AS year, 
	MONTH(w.created_at) AS month, 
	COUNT(DISTINCT w.website_session_id) AS sessions, 
	COUNT(DISTINCT o.order_id) AS orders, 
FROM website_sessions w
	LEFT JOIN orders o
		ON o.website_session_id = w.website_session_id
WHERE w.created_at < '2012-11-27' -- request date
	AND w.utm_source = 'gsearch'
GROUP BY 1,2;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q1.jpg">

There has been a general upward trend in sessions and orders across the month
  
 ---

### 2. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 

Steps:

* Combine CASE statement with COUNT DISTINCT to get sessions and orders for brand and nonbrand utm_campaign.


```sql
SELECT
	YEAR(w.created_at) AS year, 
	MONTH(w.created_at) AS month, 
	COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN w.website_session_id ELSE NULL END) AS nonbrand_sessions, 
	COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN w.website_session_id ELSE NULL END) AS brand_sessions, 
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders
FROM website_sessions w
	LEFT JOIN orders o
		ON o.website_session_id = w.website_session_id
WHERE w.created_at < '2012-11-27'
	AND w.utm_source = 'gsearch'
GROUP BY 1,2;
```

### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q2.jpg">

We can also see an upward trend in sessions and orders across the month for both brand and nonbrand utm_campaign.

---

### 3. While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 

steps:

* Combine CASE statement with COUNT DISTINCT to get sessions and orders for the different device types.
* Filter the utm_source and utm_campaign to inlcude only 'gsearch' and 'nonbrand' respectively.


```sql
SELECT
	YEAR(w.created_at) AS year, 
	MONTH(w.created_at) AS month, 
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN w.website_session_id ELSE NULL END) AS desktop_sessions, 
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_orders,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN w.website_session_id ELSE NULL END) AS mobile_sessions, 
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions w
	LEFT JOIN orders o
		ON o.website_session_id = w.website_session_id
WHERE w.created_at < '2012-11-27'
	AND w.utm_source = 'gsearch'
    AND w.utm_campaign = 'nonbrand'
GROUP BY 1,2;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q3.jpg">


While desktop devices had more sessions and orders than mobile devices, both devices saw an increase between March and November. 

---

### 4. I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?

Steps:

* First, let's view the various utm sources and referers to see the traffic we're getting


```sql
SELECT DISTINCT 
	utm_source,
	utm_campaign, 
	http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q4a.jpg">


* Now, let's define our CASE statement logic with utm sources and referers. 

```sql
SELECT
	YEAR(w.created_at) AS year, 
	MONTH(w.created_at) AS month, 
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN w.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN w.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN w.website_session_id ELSE NULL END) AS organic_search_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN w.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions w
WHERE w.created_at < '2012-11-27'
GROUP BY 1,2;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q4b.jpg">

We can see that our organic and direct type in sessions increased across the months. This shows that our brand is getting more and more popular with users.

---

### 5. I’d like to tell the story of our website performance improvements over the course of the first 8 months. Could you pull session to order conversion rates, by month? 

Steps:

* Left Join the website_sessions table to the orders table to get sessions resulted orders
* Use COUNT DISTINCT to get the number of sessions and orders
* Divide the orders by sessions to get to conversion rate

```sql
SELECT
	YEAR(w.created_at) AS year, 
	MONTH(w.created_at) AS month, 
	COUNT(DISTINCT w.website_session_id) AS sessions, 
	COUNT(DISTINCT o.order_id) AS orders, 
	COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) AS conversion_rate    
FROM website_sessions w
	LEFT JOIN orders o
		ON o.website_session_id = w.website_session_id
WHERE w.created_at < '2012-11-27'
GROUP BY 1,2;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q5.jpg">


There has been a general upward trend in conversion rate across the month with increasing sessions and orders 

---

### 6. For the gsearch lander test, please estimate the revenue that test earned us (Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use nonbrand sessions and revenue since then to calculate incremental value)

steps:

* For this step, we'll find the first pageview id 

```sql
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	wp.website_session_id, 
	MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews wp
	INNER JOIN website_sessions w
		ON w.website_session_id = wp.website_session_id
		AND w.created_at < '2012-07-28' -- prescribed by the assignment
		AND wp.website_pageview_id >= 23504 -- first page_view
		AND utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
GROUP BY 
	wp.website_session_id;
```

* Next, we'll bring in the landing page to each session, like last time, but restricting to home or lander-1 this time


```sql
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_landing_pages
SELECT 
	f.website_session_id, 
	wp.pageview_url AS landing_page
FROM first_test_pageviews f
	LEFT JOIN website_pageviews wp
		ON wp.website_pageview_id = f.min_pageview_id
WHERE wp.pageview_url IN ('/home','/lander-1'); 
```

* Then we make a table to bring in orders


```sql
CREATE TEMPORARY TABLE nonbrand_test_sessions_w_orders
SELECT
	n.website_session_id, 
	n.landing_page, 
	o.order_id AS order_id
FROM nonbrand_test_sessions_w_landing_pages n
	LEFT JOIN orders o
		ON o.website_session_id = n.website_session_id; 
```

* To find the difference between conversion rates 

```sql
SELECT
	landing_page, 
	COUNT(DISTINCT website_session_id) AS sessions, 
	COUNT(DISTINCT order_id) AS orders,
	COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conv_rate
FROM nonbrand_test_sessions_w_orders
GROUP BY 1; 
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q6a.jpg">


-- .0318 for /home, vs .0406 for /lander-1 
-- .0087 additional orders per session


* Finally

```sql
SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145 -- last /home session
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'; 
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q6c.jpg">

-- 22,972 website sessions since the test

-- X .0087 incremental conversion = 200 incremental orders since 2012-07-28
-- roughly 4 months, so roughly 50 extra orders per month. Not bad!

---

### 7. For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28). 

steps:

* Creat a flag for each of the pageview urls

```sql
CREATE TEMPORARY TABLE session_level_made_it_flagged
SELECT
	website_session_id, 
	MAX(homepage) AS saw_homepage, 
	MAX(custom_lander) AS saw_custom_lander,
	MAX(products_page) AS product_made_it, 
	MAX(mrfuzzy_page) AS mrfuzzy_made_it, 
	MAX(cart_page) AS cart_made_it,
	MAX(shipping_page) AS shipping_made_it,
	MAX(billing_page) AS billing_made_it,
	MAX(thankyou_page) AS thankyou_made_it
FROM(
		SELECT
			w.website_session_id, 
			wp.pageview_url, 
			CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
			CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
			CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
			CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page, 
			CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
			CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
			CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
			CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
		FROM website_sessions w
			LEFT JOIN website_pageviews wp
				ON w.website_session_id = wp.website_session_id
		WHERE w.utm_source = 'gsearch' 
			AND w.utm_campaign = 'nonbrand' 
			AND w.created_at < '2012-07-28'
			AND w.created_at > '2012-06-19'
		ORDER BY 
			w.website_session_id,
			wp.created_at
	) AS pageview_level
GROUP BY 
	website_session_id
;
```

* Then, show the progression of the sessions to the thank you page (check out page)

```sql
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
		WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
		ELSE 'wrong logic' 
	END AS segment, 
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it_flagged 
GROUP BY 1;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q7a.jpg">

* Finally, show the click rates across the pageview urls

```sql
SELECT
	CASE 
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        	WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        	ELSE 'wrong logic' 
	END AS segment, 
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT website_session_id) AS lander_click_rt,
    	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rt,
    	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rt,
    	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_level_made_it_flagged
GROUP BY 1;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q7b.jpg">
 

---

### 8. I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand monthly impact.

steps:

* Left join the website_pageview to the orders table.
* Restrict date range to (Sep 10 – Nov 10) as stated in the enquiry
* Restrick the pageview_url to the billing page variations alone.


```sql
SELECT
	billing_version_seen, 
	COUNT(DISTINCT website_session_id) AS sessions, 
	SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
 FROM( 
	SELECT 
		wp.website_session_id, 
		wp.pageview_url AS billing_version_seen, 
		o.order_id, 
		o.price_usd
	FROM website_pageviews wp
		LEFT JOIN orders o
			ON o.website_session_id = wp.website_session_id
	WHERE wp.created_at > '2012-09-10' -- stated in the requirement
		AND wp.created_at < '2012-11-10' -- stated in the requirement
		AND wp.pageview_url IN ('/billing','/billing-2')
	) AS billing_pageviews_and_order_data
GROUP BY 1;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q8a.jpg">

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: $8.51 per billing page view


* Let's compare it to last month.
```sql
SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE pageview_url IN ('/billing','/billing-2') 
AND created_at BETWEEN '2012-10-27' AND '2012-11-27' -- past month;
```
### Output:
<p align="left" style="margin-bottom: 0px !important;">
<img src="https://github.com/Gbemiclassic/Maven-Fuzzy-Factory/blob/main/Images/Part%201%20Query%20Output/P1Q8b.jpg">

-- 1,193 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: $10,152 over the past month
