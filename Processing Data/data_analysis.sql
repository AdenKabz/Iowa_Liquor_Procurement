-- DETAILED DATA ANALYSIS
-- CONDUCTED USING DIMENSION TABLES, CROSS-WALK TABLES AND THE SALES FACT TABLE

-- Yearly summary statistics
SELECT
  calendar_year,
  COUNT(*) AS total_transactions,
  SUM(bottles_sold) AS total_bottles_sold,
  SUM(sales_dollars) AS total_sales_dollars,
  SUM(volume_sold_liters) AS total_volume_sold_liters,
  SUM(total_cases_sold) AS total_cases_sold,
  SUM(sales_dollars - (bottles_sold * state_bottle_cost)) AS state_gross_markup
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1
ORDER BY 1;

-- Unique store, vendor, item and category count
SELECT 
  COUNT(DISTINCT IF(item_sk LIKE 'MD5_UNMAPPED%', NULL, item_sk)) AS unique_item_count,
  COUNT(DISTINCT IF(category_sk LIKE 'MD5_UNMAPPED%', NULL, category_sk)) AS unique_category_count,
  COUNT(DISTINCT IF(store_sk LIKE 'MD5_UNMAPPED%', NULL, store_sk)) AS unique_store_count,
  COUNT(DISTINCT IF(vendor_sk LIKE 'MD5_UNMAPPED%', NULL, vendor_sk)) AS unique_vendor_count
FROM tibachap.iowa_liquor_biz.sales_fact;

-- Monthly summary statistics
SELECT
  calendar_month AS month,
  COUNT(*) AS total_transactions,
  SUM(bottles_sold) AS total_bottles_sold,
  SUM(sales_dollars) AS total_sales_dollars,
  SUM(volume_sold_liters) AS total_volume_sold_liters,
  SUM(total_cases_sold) AS total_cases_sold,
  SUM(sales_dollars - (bottles_sold * state_bottle_cost)) AS state_gross_markup
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1
ORDER BY 
  CASE month
    WHEN 'Jan' THEN 1
    WHEN 'Feb' THEN 2
    WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4
    WHEN 'May' THEN 5
    WHEN 'Jun' THEN 6
    WHEN 'Jul' THEN 7
    WHEN 'Aug' THEN 8
    WHEN 'Sep' THEN 9
    WHEN 'Oct' THEN 10
    WHEN 'Nov' THEN 11
    ELSE 12
  END ASC;

-- Weekly summary statistics
SELECT
  day_of_week,
  COUNT(*) AS total_transactions,
  SUM(bottles_sold) AS total_bottles_sold,
  SUM(sales_dollars) AS total_sales_dollars,
  SUM(volume_sold_liters) AS total_volume_sold_liters,
  SUM(total_cases_sold) AS total_cases_sold,
  SUM(sales_dollars - (bottles_sold * state_bottle_cost)) AS state_gross_markup
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1
ORDER BY 
  CASE day_of_week
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    ELSE 7
  END ASC;

-- Seasonal summary statistics
SELECT
  calendar_season AS season,
  COUNT(*) AS total_transactions,
  SUM(bottles_sold) AS total_bottles_sold,
  SUM(sales_dollars) AS total_sales_dollars,
  SUM(volume_sold_liters) AS total_volume_sold_liters,
  SUM(total_cases_sold) AS total_cases_sold,
  SUM(sales_dollars - (bottles_sold * state_bottle_cost)) AS state_gross_markup
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1;

-- Major and minor store count
SELECT
  COUNTIF(is_major_chain = TRUE) AS major_store_count,
  COUNTIF(is_major_chain = FALSE) AS minor_store_count
FROM tibachap.iowa_liquor_biz.sales_fact;

-- Top 10 vendors based on total transactions
SELECT
  COALESCE(dt.vendor_name, 'Unknown Vendor') AS vendor_name,
  COUNT(*) AS total_transactions
FROM `tibachap.iowa_liquor_biz.sales_fact` AS sf
LEFT JOIN `tibachap.iowa_liquor_biz.dt_vendor` AS dt 
  -- Converts the plain text Base64 string into binary bytes to match dt.vendor_sk perfectly
  ON sf.vendor_sk = dt.vendor_sk
GROUP BY 1
ORDER BY total_transactions DESC
LIMIT 10;

-- Pack and bottle_volume_ml summary statistics
-- Top bottle size per pack
SELECT
  pack,
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  AVG(price_per_liter) AS avg_price_per_liter,
  SUM(sales_dollars) AS total_expenditure,
  SUM(bottles_sold) AS total_bottles_ordered,
  SUM(volume_sold_liters) AS total_liters_ordered,
  SUM(total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1,2 
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY pack
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY 1;

-- Product premium tier summary statistics
SELECT
  product_premium_tier,
  COUNT(*) AS total_transactions,
  AVG(price_per_liter) AS avg_price_per_liter,
  SUM(sales_dollars) AS total_expenditure,
  SUM(bottles_sold) AS total_bottles_ordered,
  SUM(volume_sold_liters) AS total_liters_ordered,
  SUM(total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact 
GROUP BY 1;

-- Top pack and bottle size per product premium tier
SELECT
  product_premium_tier,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY product_premium_tier)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY product_premium_tier)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY product_premium_tier
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top item per product premium tier
SELECT
  sf.product_premium_tier,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.product_premium_tier)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.product_premium_tier)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.product_premium_tier
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top category per product premium tier
SELECT
  sf.product_premium_tier,
  c.category_name AS category_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.product_premium_tier)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.product_premium_tier)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.product_premium_tier
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top store per product premium tier
SELECT
  sf.product_premium_tier,
  s.store_name AS store_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.product_premium_tier)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.product_premium_tier)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.product_premium_tier
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top order_size_category per product premium tier
SELECT
  product_premium_tier,
  order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY product_premium_tier)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY product_premium_tier)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY product_premium_tier
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Order size category summary statistics
SELECT
  order_size_category,
  COUNT(*) AS total_transactions,
  AVG(price_per_liter) AS avg_price_per_liter,
  SUM(sales_dollars) AS total_expenditure,
  SUM(bottles_sold) AS total_bottles_ordered,
  SUM(volume_sold_liters) AS total_liters_ordered,
  SUM(total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact 
GROUP BY 1;

-- Top pack and bottle size per order size category
SELECT
  order_size_category,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY order_size_category)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY order_size_category)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY order_size_category
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top item per order size category
SELECT
  sf.order_size_category,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.order_size_category)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.order_size_category)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.order_size_category
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top category per order size category
SELECT
  sf.order_size_category,
  c.category_name AS category_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.order_size_category)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.order_size_category)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.order_size_category
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top store per order size category
SELECT
  sf.order_size_category,
  s.store_name AS store_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.order_size_category)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.order_size_category)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.order_size_category
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top product premium tier per order size category
SELECT
  order_size_category,
  product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY order_size_category)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY order_size_category)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY order_size_category
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- City summary statistics
-- Top 10 cities based on total transactions
SELECT
  s.city AS city,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top 10 addresses based on total transactions
SELECT
  s.address AS address,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 cities
SELECT
  s.city,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 addresses
SELECT
  s.address,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.address)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.address)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.address
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;

-- Top item per top 10 cities
SELECT
  s.city,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top category per top 10 cities
SELECT
  s.city,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top store per top 10 cities
SELECT
  s.city,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top order size category per top 10 cities
SELECT
  s.city,
  sf.order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top product premium tier per top 10 cities
SELECT
  s.city,
  sf.product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.city)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.city)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.city
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- County summary statistics
-- Top 10 counties based on total transactions
SELECT
  s.county AS county,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 counties
SELECT
  s.county,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;

-- Top item per top 10 counties
SELECT
  s.county,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top category per top 10 counties
SELECT
  s.county,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk 
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top store per top 10 counties
SELECT
  s.county,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top order size category per top 10 counties
SELECT
  s.county,
  sf.order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top product premium tier per top 10 counties
SELECT
  s.county,
  sf.product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.county)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.county)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY s.county
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;

-- Top pack and bottle size per year
SELECT
  calendar_year AS year,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_year
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top order size category per year
SELECT
  calendar_year AS year,
  order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_year
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top product premium tier per year
SELECT
  calendar_year AS year,
  product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_year
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top item per year
SELECT
  sf.calendar_year AS year,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_year
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top category per year
SELECT
  sf.calendar_year AS year,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_year
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top store per year
SELECT
  sf.calendar_year AS year,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_year
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Prevailing city per year
SELECT
  sf.calendar_year AS year,
  s.city,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_year
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Prevailing county per year
SELECT
  sf.calendar_year AS year,
  s.county,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_year)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_year)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_year
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top pack and bottle size per month
SELECT
  calendar_month AS month,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_month
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top order size category per month
SELECT
  calendar_month AS month,
  order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_month
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top product premium tier per month
SELECT
  calendar_month AS month,
  product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_month
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top item per month
SELECT
  sf.calendar_month AS month,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_month
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top category per month
SELECT
  sf.calendar_month AS month,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_month
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top store per month
SELECT
  sf.calendar_month AS month,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_month
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Prevailing city per month
SELECT
  sf.calendar_month AS month,
  s.city,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_month
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Prevailing county per month
SELECT
  sf.calendar_month AS month,
  s.county,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_month)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_month)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_month
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE calendar_month
  WHEN 'Jan' THEN 1
  WHEN 'Feb' THEN 2
  WHEN 'Mar' THEN 3
  WHEN 'Apr' THEN 4
  WHEN 'May' THEN 5
  WHEN 'Jun' THEN 6
  WHEN 'Jul' THEN 7
  WHEN 'Aug' THEN 8
  WHEN 'Sep' THEN 9
  WHEN 'Oct' THEN 10
  WHEN 'Nov' THEN 11
  ELSE 12
END;

-- Top pack and bottle size per day of the week
SELECT
  day_of_week,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY day_of_week
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top order size category per day of the week
SELECT
  day_of_week,
  order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY day_of_week
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top product premium tier per day of the week
SELECT
  day_of_week,
  product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY day_of_week
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top item per day of the week
SELECT
  sf.day_of_week,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.day_of_week
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top category per day of the week
SELECT
  sf.day_of_week,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.day_of_week
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top store per day of the week
SELECT
  sf.day_of_week,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.day_of_week
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Prevailing city per day of the week
SELECT
  sf.day_of_week,
  s.city,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.day_of_week
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Prevailing county per day of the week
SELECT
  sf.day_of_week,
  s.county,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.day_of_week)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.day_of_week)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.day_of_week
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY CASE day_of_week
  WHEN 'Monday' THEN 1
  WHEN 'Tuesday' THEN 2
  WHEN 'Wednesday' THEN 3
  WHEN 'Thursday' THEN 4
  WHEN 'Friday' THEN 5
  WHEN 'Saturday' THEN 6
  ELSE 7
END;

-- Top pack and bottle size per season
SELECT
  calendar_season AS season,
  pack, 
  bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_season
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top order size category per season
SELECT
  calendar_season AS season,
  order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_season
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top product premium tier per season
SELECT
  calendar_season AS season,
  product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sales_dollars), SUM(SUM(sales_dollars)) OVER (PARTITION BY calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY calendar_season
  ORDER BY COUNT(*) DESC, SUM(sales_dollars) DESC
) = 1;

-- Top item per season
SELECT
  sf.calendar_season AS season,
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_season
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top category per season
SELECT
  sf.calendar_season AS season,
  c.category_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_season
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Top store per season
SELECT
  sf.calendar_season AS season,
  s.store_name,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_season
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Prevailing city per season
SELECT
  sf.calendar_season AS season,
  s.city,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_season
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Prevailing county per season
SELECT
  sf.calendar_season AS season,
  s.county,
  COUNT(*) AS total_transactions,
  SUM(sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY sf.calendar_season)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY sf.calendar_season)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY sf.calendar_season
  ORDER BY COUNT(*) DESC, SUM(sf.sales_dollars) DESC
) = 1;

-- Item summary statistics
-- Top 10 items based on total transactions
SELECT
  i.item_description AS item_name,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 items
SELECT
  i.item_description AS item_name,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY i.item_description)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY i.item_description)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY i.item_description
  ORDER BY 4 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;
  
-- Top order size category per top 10 items
SELECT
  i.item_description AS item_name,
  sf.order_size_category,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY i.item_description)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY i.item_description)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY i.item_description
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top product premium tier per top 10 items
SELECT
  i.item_description AS item_name,
  sf.product_premium_tier,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY i.item_description)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY i.item_description)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY i.item_description
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Category summary statistics
-- Top 10 categories based on total transactions
SELECT
  c.category_name,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 categories
SELECT
  c.category_name,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY c.category_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY c.category_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY c.category_name
  ORDER BY 4 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;
  
-- Top order size category per top 10 categories
SELECT
  c.category_name,
  sf.order_size_category, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY c.category_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY c.category_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY c.category_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top product premium tier per top 10 categories
SELECT
  c.category_name,
  sf.product_premium_tier, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY c.category_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY c.category_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY c.category_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top item per top 10 categories
SELECT
  c.category_name,
  i.item_description AS item_name, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY c.category_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY c.category_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY c.category_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Store summary statistics
-- Top 10 stores based on total transactions
SELECT
  s.store_name,
  COUNT(*) AS total_transactions,
  AVG(sf.price_per_liter) AS avg_price_per_liter,
  SUM(sf.sales_dollars) AS total_expenditure,
  SUM(sf.bottles_sold) AS total_bottles_ordered,
  SUM(sf.volume_sold_liters) AS total_liters_ordered,
  SUM(sf.total_cases_sold) AS total_cases_ordered,
  ROUND(SAFE_DIVIDE(COUNTIF(sf.is_split_case = TRUE), COUNT(*)) *100, 2) AS split_case_percentage,
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Top pack and bottle size per top 10 stores
SELECT
  s.store_name,
  sf.pack, 
  sf.bottle_volume_ml AS bottle_size,
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.store_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.store_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2, 3
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY s.store_name
  ORDER BY 4 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 4 DESC
LIMIT 10;
  
-- Top order size category per top 10 stores
SELECT
  s.store_name,
  sf.order_size_category, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.store_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.store_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY s.store_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top product premium tier per top 10 stores
SELECT
  s.store_name,
  sf.product_premium_tier, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.store_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.store_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY s.store_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top item per top 10 stores
SELECT
  s.store_name,
  i.item_description AS item_name, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.store_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.store_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_item i ON sf.item_sk = i.item_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY s.store_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  
-- Top category per top 10 stores
SELECT
  s.store_name,
  c.category_name, 
  COUNT(*) AS total_transactions,
  SUM(sf.sales_dollars) AS total_expenditure,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER (PARTITION BY s.store_name)) * 100, 2) AS transaction_percentage,
  ROUND(SAFE_DIVIDE(SUM(sf.sales_dollars), SUM(SUM(sf.sales_dollars)) OVER (PARTITION BY s.store_name)) * 100,2) AS expenditure_percentage
FROM tibachap.iowa_liquor_biz.sales_fact sf
LEFT JOIN tibachap.iowa_liquor_biz.dt_store s ON sf.store_sk = s.store_sk
LEFT JOIN tibachap.iowa_liquor_biz.dt_category c ON sf.category_sk = c.category_sk
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY s.store_name
  ORDER BY 3 DESC, SUM(sf.sales_dollars) DESC
) = 1
ORDER BY 3 DESC
LIMIT 10;
  


