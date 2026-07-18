-- DETAILED DATA EXPLORATION

-- Discover the number of null values in each column
SELECT
  SUM(CASE WHEN invoice_and_item_number IS NULL THEN 1 ELSE 0 END) AS invoice_item_number_nulls,
  SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS date_nulls,
  SUM(CASE WHEN store_number IS NULL THEN 1 ELSE 0 END) AS store_number_nulls,
  SUM(CASE WHEN store_name IS NULL THEN 1 ELSE 0 END) AS store_name_nulls,
  SUM(CASE WHEN address IS NULL THEN 1 ELSE 0 END) AS address_nulls,
  SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS city_nulls,
  SUM(CASE WHEN zip_code IS NULL THEN 1 ELSE 0 END) AS zip_code_nulls,
  SUM(CASE WHEN store_location IS NULL THEN 1 ELSE 0 END) AS store_location_nulls,
  SUM(CASE WHEN county_number IS NULL THEN 1 ELSE 0 END) AS county_number_nulls,
  SUM(CASE WHEN county IS NULL THEN 1 ELSE 0 END) AS county_nulls,
  SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS category_nulls,
  SUM(CASE WHEN category_name IS NULL THEN 1 ELSE 0 END) AS category_name_nulls,
  SUM(CASE WHEN vendor_number IS NULL THEN 1 ELSE 0 END) AS vendor_number_nulls,
  SUM(CASE WHEN vendor_name IS NULL THEN 1 ELSE 0 END) AS vendor_name_nulls,
  SUM(CASE WHEN item_number IS NULL THEN 1 ELSE 0 END) AS item_number_nulls,
  SUM(CASE WHEN item_description IS NULL THEN 1 ELSE 0 END) AS item_description_nulls,
  SUM(CASE WHEN pack IS NULL THEN 1 ELSE 0 END) AS pack_nulls,
  SUM(CASE WHEN bottle_volume_ml IS NULL THEN 1 ELSE 0 END) AS bottle_volume_ml_nulls,
  SUM(CASE WHEN state_bottle_cost IS NULL THEN 1 ELSE 0 END) AS state_bottle_cost_nulls,
  SUM(CASE WHEN state_bottle_retail IS NULL THEN 1 ELSE 0 END) AS state_bottle_retail_nulls,
  SUM(CASE WHEN bottles_sold IS NULL THEN 1 ELSE 0 END) AS bottles_sold_nulls,
  SUM(CASE WHEN sale_dollars IS NULL THEN 1 ELSE 0 END) AS sale_dollars_nulls,
  SUM(CASE WHEN volume_sold_liters IS NULL THEN 1 ELSE 0 END) AS volume_sold_liters_nulls,
  SUM(CASE WHEN volume_sold_gallons IS NULL THEN 1 ELSE 0 END) AS volume_sold_gallons_nulls
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- 85459 address_nulls, 85458 city_nulls, 85525 zip_code_nulls, 2519004 store_location_nulls, 9883996 county_number_nulls, 162261 county_nulls, 16974 category_nulls, 25040 category_name_nulls, 9 vendor_number_nulls, 7 vendor_name_nulls, 10 state_bottle_cost_nulls, 10 state_bottle_retail_nulls and 10 sale_dollars_nulls.

-- Total count of the records
SELECT
  COUNT(*) AS record_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
-- 34016839 rows 

  -- Exploring every column from left to right
-- 1) invoice_and_item_number
-- i) blank values
SELECT 
  COUNT(*) AS blank_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE TRIM(invoice_and_item_number) = '';
-- zero blanks

-- ii) length
SELECT 
  LENGTH(invoice_and_item_number) AS id_length,
  COUNT(*) AS count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 1;
-- length categories returned: 9, 10, 12, 15 and 16

-- iii) duplicates
SELECT
  invoice_and_item_number,
  COUNT(*) AS id_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY 2 DESC;
-- no duplicates

-- 2) date
-- i) Find rows that don't follow a YYYY-MM-DD format
SELECT
  date
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE NOT REGEXP_CONTAINS(CAST(date AS STRING), r'^[0-9]{4}-[0-9]{2}-[0-9]{2}$');
-- no rows returned

-- ii) Earliest and latest dates
SELECT
  MIN(date) AS earliest_date,
  MAX(date) AS latest_date
FROM `bigquery-public-data.iowa_liquor_sales.sales`
-- 2012-01-03 to 2026-04-30

-- iii) ensure all years and months are present
SELECT
 EXTRACT(YEAR FROM date) AS year,
 EXTRACT(MONTH FROM date) AS month_number,
 FORMAT_DATE('%B', date) AS month
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1, 2, 3
ORDER BY 1, 2;
-- all years and months are present

-- 3) store_number
-- i) blank count
SELECT
  COUNT(*) AS blank_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE TRIM(store_number) = '';
-- no blanks

-- ii) length
SELECT 
  LENGTH(store_number) AS store_number_length,
  COUNT(*) AS count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 1;
-- length categories returned: 4 and 5

-- iii) Number of unique store numbers
SELECT
  store_number,
  COUNT(*) AS store_number_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 3431 rows returned

-- 4) store_name
-- i) blank count
SELECT 
  COUNT(*) AS blank_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE TRIM(store_name) = '';
-- zero blanks

-- ii) Number of unique stores
SELECT
  store_name,
  COUNT(*) AS count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 3692 rows returned

-- iii) Store numbers representing more than one store name
SELECT 
  store_number,
  COUNT(DISTINCT store_name) AS unique_names,
  STRING_AGG(DISTINCT store_name, ', ') AS store_names_list
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 
  store_number
HAVING 
  unique_names > 1
ORDER BY 
  unique_names DESC;
-- 456 rows returned

-- iv) Store names having more than one store number
SELECT 
  store_name,
  COUNT(DISTINCT store_number) AS unique_numbers,
  STRING_AGG(DISTINCT store_number, ', ') AS store_number_list
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 
  1
HAVING 
  unique_numbers > 1
ORDER BY 
  unique_numbers DESC;
-- 216 rows returned

-- iv) Store names having more than one store number
SELECT 
  store_name,
  COUNT(DISTINCT store_number) AS unique_numbers,
  STRING_AGG(DISTINCT store_number, ', ') AS store_number_list
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 
  1
HAVING 
  unique_numbers > 1
ORDER BY 
  unique_numbers DESC;
-- 408 rows returned

-- vi) Store name to store location mapping
SELECT
  store_name,
  COUNT(DISTINCT ST_ASTEXT(store_location)) AS store_location_count,
  ARRAY_AGG(DISTINCT ST_ASTEXT(store_location)) AS store_locations
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE store_location IS NOT NULL
GROUP BY 1
HAVING store_location_count > 1
ORDER BY 2 DESC;
-- 2382 rows returned

-- 5) address
-- i) Number of addresses
SELECT 
    address,
    COUNT(*) AS record_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 3360 rows returned

-- ii) Duplicate addresses
SELECT 
    address,
    COUNT(DISTINCT address) AS address_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
HAVING COUNT(DISTINCT address) > 1
ORDER BY 2 DESC;
-- no duplicates

-- iii) Length of address
SELECT 
  LENGTH(address) AS address_length
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE address IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- 30 rows returned

-- 6) city
-- i) Number of cities
SELECT
  city,
  COUNT(*) AS city_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 506 rows returned

-- 7) zip_code
-- i) Number of zip codes
SELECT
  zip_code,
  COUNT(*) AS zip_code_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 1064 rows returned

-- ii) Length of zipcodes
SELECT
  LENGTH(zip_code) AS zipcode_length
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE zip_code IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- length categories returned: 7 and 5

-- 8) store_location
-- i) Number of store locations
SELECT
  ST_ASTEXT(store_location) AS store_location,
  COUNT(*) AS store_location_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 10900 rows returned

-- 9) county_number
-- i) Number of county numbers
SELECT
  county_number,
  COUNT(*) AS county_number_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 100 rows returned

-- 10) county
-- i) Number of counties
SELECT
  county,
  COUNT(*) AS county_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 101 rows returned

-- 11) category
-- i) Number of category ids
SELECT
  category,
  COUNT(*) AS category_id_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 186 rows returned

-- ii) Length of category ids
SELECT
  LENGTH(category) AS category_id_length
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE category IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- length categories returned: 9, 8 and 7

-- iii) Category id to category name mapping
SELECT
  category,
  COUNT(DISTINCT category_name) AS category_name_count,
  ARRAY_AGG(DISTINCT category_name) AS category_names
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
HAVING category_name_count > 1
ORDER BY 2 DESC;
-- 30 rows returned

-- 12) category_name
-- i) Number of category names
SELECT
  category_name,
  COUNT(*) AS category_name_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 104 rows returned

-- ii) Category name to category id mapping
SELECT
  category_name,
  COUNT(DISTINCT category) AS category_id_count,
  ARRAY_AGG(DISTINCT category) AS category_ids
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE category IS NOT NULL
GROUP BY 1
HAVING category_id_count > 1
ORDER BY 2 DESC;
-- 68 rows returned

-- iii) Category name to item description mapping
SELECT
  category_name,
  COUNT(DISTINCT item_description) AS item_description_count,
  ARRAY_AGG(DISTINCT item_description) AS item_descriptions
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE item_description IS NOT NULL
GROUP BY 1
HAVING item_description_count > 1
ORDER BY 2 DESC;
-- 99 rows returned

-- 13) vendor_number
-- i) Number of vendor numbers
SELECT
  vendor_number,
  COUNT(*) AS vendor_number_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 853 rows returned

-- ii) Length of vendor numbers
SELECT
  LENGTH(vendor_number) AS vendor_number_length
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE vendor_number IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- Length categories returned: 5, 4, 3 and 2

-- iii) Vendor number to vendor name mapping
SELECT
  vendor_number,
  COUNT(DISTINCT vendor_name) AS vendor_name_count,
  ARRAY_AGG(DISTINCT vendor_name) AS vendor_names
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE vendor_name IS NOT NULL
GROUP BY 1
HAVING vendor_name_count > 1
ORDER BY vendor_name_count DESC;
-- 192 rows returned

-- 14) vendor_name
-- i) Number of vendor names
SELECT
  vendor_name,
  COUNT(*) AS vendor_name_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 665 rows returned

-- ii) Vendor name to vendor number mapping
SELECT
  vendor_name,
  COUNT(DISTINCT vendor_number) AS vendor_number_count,
  ARRAY_AGG(DISTINCT vendor_number) AS vendor_numbers
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE vendor_number IS NOT NULL
GROUP BY 1
HAVING vendor_number_count > 1
ORDER BY vendor_number_count DESC;
-- 419 rows returned

-- 15) item_number
-- i) Number of item numbers
SELECT
  item_number,
  COUNT(*) AS item_number_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 15633 rows returned

-- ii) Length of item numbers
SELECT
  LENGTH(item_number) AS item_number_length
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE item_number IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;
-- Length categories returned: 7, 6, 5, 4 and 3

-- iii) Item number to item description mapping
SELECT
  item_number,
  COUNT(DISTINCT item_description) AS item_description_count,
  ARRAY_AGG(DISTINCT item_description) AS item_descriptions
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE item_description IS NOT NULL
GROUP BY 1
HAVING item_description_count > 1
ORDER BY 2 DESC;
-- 2392 rows returned

-- 16) item_description
-- i) Number of item descriptions
SELECT
  item_description,
  COUNT(*) AS item_description_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 14533 rows returned

-- ii) Item description to item number mapping
SELECT
  item_description,
  COUNT(DISTINCT item_number) AS item_number_count,
  ARRAY_AGG(DISTINCT item_number) AS item_numbers
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE item_number IS NOT NULL
GROUP BY 1
HAVING item_number_count > 1
ORDER BY 2 DESC;
-- 2363 rows returned

-- iii) Item description to category name mapping
SELECT
  item_description,
  COUNT(DISTINCT category_name) AS category_name_count,
  ARRAY_AGG(DISTINCT category_name) AS category_names
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE category_name IS NOT NULL
GROUP BY 1
HAVING category_name_count > 1
ORDER BY 2 DESC;
-- 2759 rows returned

-- 17) pack
-- i) Number of packs
SELECT
  pack,
  COUNT(*) AS pack_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 29 rows returned

-- ii) Mininum and maximum number of packs
SELECT
  MIN(pack) AS lowest_pack_count,
  MAX(pack) AS highest_pack_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- lowest pack is 1 and highest pack is 336

-- 18) bottle_volume_ml
-- i) Bottle volume distribution
SELECT
  bottle_volume_ml,
  COUNT(*) AS bottle_volume_ml_count
FROM `bigquery-public-data.iowa_liquor_sales.sales`
GROUP BY 1
ORDER BY 2 DESC;
-- 59 rows returned

-- ii) Mininum and maximum number of bottle_volume_ml
SELECT
  MIN(bottle_volume_ml) AS lowest_bottle_volume_ml,
  MAX(bottle_volume_ml) AS highest_bottle_volume_ml
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- lowest is 0 and highest is 378000

-- 19) state_bottle_cost
-- i) Minimum, maximum and average values
SELECT
  MIN(state_bottle_cost) AS min_state_bottle_cost,
  MAX(state_bottle_cost) AS max_state_bottle_cost,
  ROUND(AVG(state_bottle_cost), 2) AS avg_state_bottle_cost
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is 0, max is 24989.02 and avg is 11.16

-- 20) state_bottle_retail
-- i) Minimum, maximum and average values
SELECT
  MIN(state_bottle_retail) AS min_state_bottle_retail,
  MAX(state_bottle_retail) AS max_state_bottle_retail,
  ROUND(AVG(state_bottle_retail), 2) AS avg_state_bottle_retail
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is 0, max is 37483.53 and avg is 16.75

-- ii) state bottle retail vs state bottle cost consistency
-- checking if there is state botlle retail less than state bottle cost
SELECT
  *
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE state_bottle_retail < state_bottle_cost;
-- 269 rows returned

-- 21) bottles_sold
-- i) Minimum, maximum and average values
SELECT
  MIN(bottles_sold) AS min_bottles_sold,
  MAX(bottles_sold) AS max_bottles_sold,
  ROUND(AVG(bottles_sold), 2) AS avg_bottles_sold
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is -768, max is 15000 and avg is 11.02

-- 22) sale_dollars
-- i) Minimum, maximum and average values
SELECT
  MIN(sale_dollars) AS min_sale_dollars,
  MAX(sale_dollars) AS max_sale_dollars,
  ROUND(AVG(sale_dollars), 2) AS avg_sale_dollars
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is -9720, max is 279557.28 and avg is 148.86

-- ii) Sale dollars inconsistency
-- checking if sale dollars is not equal to (state_bottle_retail * bottles_sold)
SELECT
  *
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE ROUND(sale_dollars, 2) <> ROUND(state_bottle_retail * bottles_sold, 2);
-- 1261876 rows returned

-- 23) volume_sold_liters
-- i) Minimum, maximum and average values
SELECT
  MIN(volume_sold_liters) AS min_volume_sold_liters,
  MAX(volume_sold_liters) AS max_volume_sold_liters,
  ROUND(AVG(volume_sold_liters), 2) AS avg_volume_sold_liters
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is -1344, max is 15000 and avg is 9.11

-- ii) Volume sold liters inconsistency
-- checking if volume_sold_liters is not equl to (bottles_sold × bottle_volume_ml / 1000)
SELECT
  *
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE ROUND(volume_sold_liters, 2) <> ROUND(bottles_sold * bottle_volume_ml / 1000, 2);
-- 577819 rows returned

-- 24) volume_sold_gallons
-- i) Minimum, maximum and average values
SELECT
  MIN(volume_sold_gallons) AS min_volume_sold_gallons,
  MAX(volume_sold_gallons) AS max_volume_sold_gallons,
  ROUND(AVG(volume_sold_gallons), 2) AS avg_volume_sold_gallons
FROM `bigquery-public-data.iowa_liquor_sales.sales`;
-- min is -355.04, max is 3962.58 and avg is 2.4

-- ii) Volume sold gallons inconsistencies
-- checking if volume_sold_gallons is not equal to (volume_sold_liters * 0.264172)
SELECT 
  *
FROM `bigquery-public-data.iowa_liquor_sales.sales`
WHERE ROUND(volume_sold_gallons, 2) != ROUND(volume_sold_liters * 0.264172, 2);
-- 11709221 rows returned

-- OTHER CHECKS
-- Most frequent and recent store name per store number
WITH name_counts AS (
  -- Calculate frequency of each name per ID
  SELECT 
    store_number, 
    store_name,
    COUNT(*) as appearance_count,
    MAX(date) as last_seen_date
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  GROUP BY 1, 2
),
ranked_names AS (
  SELECT 
    store_number,
    store_name,
    -- Rank by Frequency
    ROW_NUMBER() OVER(PARTITION BY store_number ORDER BY appearance_count DESC) as freq_rank,
    -- Rank by Most Recent
    ROW_NUMBER() OVER(PARTITION BY store_number ORDER BY last_seen_date DESC) as recent_rank
  FROM name_counts
)
SELECT 
  f.store_number,
  f.store_name as most_frequent_name,
  r.store_name as most_recent_name,
  CASE WHEN f.store_name = r.store_name THEN 'Match' ELSE 'Mismatch' END as strategy_status
FROM (SELECT * FROM ranked_names WHERE freq_rank = 1) f
JOIN (SELECT * FROM ranked_names WHERE recent_rank = 1) r ON f.store_number = r.store_number;
-- 3431 rows returned

-- Most frequent and recent vendor name per vendor number
WITH name_counts AS (
  -- Calculate frequency of each name per ID
  SELECT 
    vendor_number, 
    vendor_name,
    COUNT(*) as appearance_count,
    MAX(date) as last_seen_date
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  GROUP BY 1, 2
),
ranked_names AS (
  SELECT 
    vendor_number,
    vendor_name,
    -- Rank by Frequency
    ROW_NUMBER() OVER(PARTITION BY vendor_number ORDER BY appearance_count DESC) as freq_rank,
    -- Rank by Most Recent
    ROW_NUMBER() OVER(PARTITION BY vendor_number ORDER BY last_seen_date DESC) as recent_rank
  FROM name_counts
)
SELECT 
  f.vendor_number,
  f.vendor_name as most_frequent_name,
  r.vendor_name as most_recent_name,
  CASE WHEN f.vendor_name = r.vendor_name THEN 'Match' ELSE 'Mismatch' END as strategy_status
FROM (SELECT * FROM ranked_names WHERE freq_rank = 1) f
JOIN (SELECT * FROM ranked_names WHERE recent_rank = 1) r ON f.vendor_number = r.vendor_number;
-- 852 rows returned

-- Most frequent and recent item description per item number
WITH name_counts AS (
  -- Calculate frequency of each name per ID
  SELECT 
    item_number, 
    item_description,
    COUNT(*) as appearance_count,
    MAX(date) as last_seen_date
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  GROUP BY 1, 2
),
ranked_names AS (
  SELECT 
    item_number,
    item_description,
    -- Rank by Frequency
    ROW_NUMBER() OVER(PARTITION BY item_number ORDER BY appearance_count DESC) as freq_rank,
    -- Rank by Most Recent
    ROW_NUMBER() OVER(PARTITION BY item_number ORDER BY last_seen_date DESC) as recent_rank
  FROM name_counts
)
SELECT 
  f.item_number,
  f.item_description as most_frequent_name,
  r.item_description as most_recent_name,
  CASE WHEN f.item_description = r.item_description THEN 'Match' ELSE 'Mismatch' END as strategy_status
FROM (SELECT * FROM ranked_names WHERE freq_rank = 1) f
JOIN (SELECT * FROM ranked_names WHERE recent_rank = 1) r ON f.item_number = r.item_number;
-- 15633 rows returned

-- Most frequent and recent item description per category
WITH item_category_history AS (
  SELECT
    item_number,
    -- Pulling both Code and Name to see the full structural shift
    category,
    category_name,
    date,
    -- Count total times this specific item appeared under this specific category
    COUNT(*) OVER(PARTITION BY item_number, category) as appearance_count,
    -- Rank by date to find the absolute latest category assignment
    ROW_NUMBER() OVER(PARTITION BY item_number ORDER BY date DESC) as recency_rank
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE item_number IS NOT NULL 
    AND category IS NOT NULL
),

most_frequent_category AS (
  SELECT 
    item_number,
    category AS most_frequent_code,
    category_name AS most_frequent_name,
    ROW_NUMBER() OVER(PARTITION BY item_number ORDER BY appearance_count DESC, category DESC) as frequency_rank
  FROM item_category_history
),

most_recent_category AS (
  SELECT 
    item_number,
    category AS most_recent_code,
    category_name AS most_recent_name
  FROM item_category_history
  WHERE recency_rank = 1
),

distinct_item_counts AS (
  SELECT 
    item_number,
    COUNT(DISTINCT category) as total_distinct_categories
  FROM item_category_history
  GROUP BY item_number
)

SELECT
  f.item_number,
  d.total_distinct_categories,
  f.most_frequent_code,
  f.most_frequent_name,
  r.most_recent_code,
  r.most_recent_name,
  CASE 
    WHEN f.most_frequent_code = r.most_recent_code THEN 'Match'
    ELSE 'Mismatch'
  END as strategy_status
FROM most_frequent_category f
JOIN most_recent_category r ON f.item_number = r.item_number
JOIN distinct_item_counts d ON f.item_number = d.item_number
WHERE f.frequency_rank = 1 
  AND d.total_distinct_categories > 1  -- Filters to show ONLY the items with category mismatches
ORDER BY d.total_distinct_categories DESC, f.item_number;
-- 7182 rows returned

-- Lifespan of category bundled together with item
WITH category_item_timeline AS (
  SELECT
    category,
    category_name,
    item_number,
    item_description,
    MIN(date) as first_seen_in_category,
    MAX(date) as last_seen_in_category,
    COUNT(*) as total_sales_transactions
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE category IS NOT NULL AND item_number IS NOT NULL
  GROUP BY 1, 2, 3, 4
),

category_behavior AS (
  SELECT 
    category,
    COUNT(DISTINCT item_number) as total_distinct_items,
    -- Heuristic: Items that appeared in this category on exactly one day (high likelihood of data entry glitch)
    COUNT(CASE WHEN first_seen_in_category = last_seen_in_category THEN 1 END) as single_day_anomalies,
    -- Lifespan markers for the category itself across the entire dataset
    MIN(first_seen_in_category) as category_birth_date,
    MAX(last_seen_in_category) as category_last_active_date
  FROM category_item_timeline
  GROUP BY 1
)

SELECT 
  t.category,
  t.category_name,
  b.total_distinct_items as total_items_ever_assigned,
  b.single_day_anomalies,
  b.category_birth_date,
  b.category_last_active_date,
  t.item_number,
  t.item_description,
  t.first_seen_in_category,
  t.last_seen_in_category,
  t.total_sales_transactions
FROM category_item_timeline t
JOIN category_behavior b ON t.category = b.category
ORDER BY 
  b.total_distinct_items DESC, 
  t.category, 
  t.first_seen_in_category ASC;
-- 28758 rows returned

-- Most frequent and recent category
WITH category_name_aggregates AS (
  SELECT
    category,
    category_name,
    COUNT(*) as name_occurrence_count,
    MIN(date) as name_first_seen,
    MAX(date) as name_last_seen
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE category IS NOT NULL
  GROUP BY category, category_name
),

category_lifecycle AS (
  SELECT
    category,
    MIN(name_first_seen) as category_birth_date,
    MAX(name_last_seen) as category_last_active_date,
    COUNT(DISTINCT category_name) as total_distinct_names
  FROM category_name_aggregates
  GROUP BY category
),

ranked_names AS (
  SELECT
    category,
    category_name,
    ROW_NUMBER() OVER(
      PARTITION BY category 
      ORDER BY name_occurrence_count DESC, category_name DESC
    ) as frequency_rank,
    ROW_NUMBER() OVER(
      PARTITION BY category 
      ORDER BY name_last_seen DESC, name_occurrence_count DESC, category_name DESC
    ) as recency_rank
  FROM category_name_aggregates
),

most_frequent AS (
  SELECT category, category_name as most_frequent_name
  FROM ranked_names
  WHERE frequency_rank = 1
),

most_recent AS (
  SELECT category, category_name as most_recent_name
  FROM ranked_names
  WHERE recency_rank = 1
)

SELECT
  l.category,
  l.total_distinct_names,
  l.category_birth_date,
  l.category_last_active_date,
  f.most_frequent_name,
  r.most_recent_name,
  CASE 
    WHEN f.most_frequent_name = r.most_recent_name THEN 'Match'
    ELSE 'Mismatch'
  END as naming_status
FROM category_lifecycle l
JOIN most_frequent f ON l.category = f.category
JOIN most_recent r ON l.category = r.category
ORDER BY l.total_distinct_names DESC, l.category;
-- 185 rows returned


