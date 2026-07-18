-- CREATING DIMENSION TABLE AND CROSS-WALK TABLES TO TRACK CODE AND NAME CHANGES 
-- THIS IS FOR STORE, VENDOR, CATEGORY AND ITEM COLUMNS

-- DIMENSION TABLES
-- Category Dimension Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.dt_category` AS
WITH category_lifespans AS (
  SELECT
    category AS category_code,
    -- Handle NULL names immediately by assigning a temporary traceable placeholder
    COALESCE(category_name, 'UNKNOWN / SYSTEM OVERHAUL') AS category_name,
    MIN(date) AS valid_from,
    MAX(date) AS valid_to
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE category IS NOT NULL
  GROUP BY category, category_name
),
ordered_lifespans AS (
  SELECT
    category_code,
    category_name,
    valid_from,
    valid_to,
    ROW_NUMBER() OVER(PARTITION BY category_code ORDER BY valid_from DESC) as rn
  FROM category_lifespans
)
SELECT 
  -- Generate a clean Surrogate Key for the future joins
  TO_HEX(MD5(CONCAT(category_code, '_', CAST(valid_from AS STRING)))) AS category_sk,
  category_code,
  UPPER(category_name) AS category_name,
  valid_from,
  
  -- The reigning record (rn=1) always gets the open-ended future date placeholder
  IF(rn = 1, DATE('2099-12-31'), valid_to) AS valid_to,
  
  -- If it's the most recent sequence row, it IS current.
  IF(rn = 1, TRUE, FALSE) AS is_current
FROM ordered_lifespans;
-- dt_category has 229 rows

-- Item Dimension Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.dt_item` AS
WITH item_history AS (
  SELECT
    item_number,
    -- Handle missing item descriptions defensively
    COALESCE(item_description, 'UNKNOWN PRODUCT / UNMAPPED ARTIFACT') AS item_description,
    COALESCE(pack, 0) AS pack,
    COALESCE(bottle_volume_ml, 0) AS bottle_volume_ml,
    MIN(date) AS valid_from,
    MAX(date) AS valid_to
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE item_number IS NOT NULL
  GROUP BY item_number, item_description, pack, bottle_volume_ml
),
item_sequenced AS (
  SELECT
    item_number,
    item_description,
    pack,
    bottle_volume_ml,
    valid_from,
    valid_to,
    ROW_NUMBER() OVER(PARTITION BY item_number ORDER BY valid_from DESC) as rn
  FROM item_history
)
SELECT
  TO_HEX(MD5(CONCAT(item_number, '_', CAST(valid_from AS STRING)))) AS item_sk,
  item_number,
  UPPER(item_description) AS item_description,
  pack,
  bottle_volume_ml,
  valid_from,
  
  -- The reigning record (rn=1) always gets the open-ended future date placeholder
  IF(rn = 1, DATE('2099-12-31'), valid_to) AS valid_to,
  
  -- If it's the most recent sequence row, it IS current.
  IF(rn = 1, TRUE, FALSE) AS is_current
FROM item_sequenced;
-- dt_item contains 18849 rows

-- Vendor Dimension Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.dt_vendor` AS
WITH vendor_history AS (
  SELECT
    -- Safely cast to INT64 to convert '101.0' or '101' into a uniform 101
    CAST(SAFE_CAST(vendor_number AS FLOAT64) AS INT64) AS vendor_number,
    -- Handle missing corporate names
    COALESCE(vendor_name, 'UNREGISTERED SUPPLIER / PRIVATE ENTITY') AS vendor_name,
    MIN(date) AS valid_from,
    MAX(date) AS valid_to
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE vendor_number IS NOT NULL
  GROUP BY vendor_number, vendor_name
),
vendor_sequenced AS (
  SELECT
    vendor_number,
    vendor_name,
    valid_from,
    valid_to,
    ROW_NUMBER() OVER(PARTITION BY vendor_number ORDER BY valid_from DESC) as rn
  FROM vendor_history
)
SELECT
  TO_HEX(MD5(CONCAT(vendor_number, '_', CAST(valid_from AS STRING)))) AS vendor_sk,
  vendor_number,
  UPPER(vendor_name) AS vendor_name,
  valid_from,
  
  -- The reigning record (rn=1) always gets the open-ended future date placeholder
  IF(rn = 1, DATE('2099-12-31'), valid_to) AS valid_to,
  
  -- If it's the most recent sequence row, it IS current.
  IF(rn = 1, TRUE, FALSE) AS is_current
FROM vendor_sequenced;
-- dt_vendor contains 669 rows

-- Store Dimension Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.dt_store` AS
WITH store_history AS (
  SELECT
    store_number,
    COALESCE(store_name, 'ESTABLISHMENT PENDING REBRAND') AS store_name,
    COALESCE(address, 'ADDRESS UNRECORDED') AS address,
    COALESCE(city, 'CITY UNMAPPED') AS city,
    COALESCE(zip_code, '00000') AS zip_code,
    COALESCE(county, 'COUNTY UNMAPPED') AS county,
    MIN(date) AS valid_from,
    MAX(date) AS valid_to
  FROM `bigquery-public-data.iowa_liquor_sales.sales`
  WHERE store_number IS NOT NULL
  GROUP BY store_number, store_name, address, city, zip_code, county
),
store_sequenced AS (
  SELECT
    store_number,
    store_name,
    address,
    city,
    zip_code,
    county,
    valid_from,
    valid_to,
    ROW_NUMBER() OVER(PARTITION BY store_number ORDER BY valid_from DESC) as rn
  FROM store_history
)
SELECT
  TO_HEX(MD5(CONCAT(store_number, '_', CAST(valid_from AS STRING)))) AS store_sk,
  store_number,
  UPPER(store_name) AS store_name,
  UPPER(address) AS address,
  UPPER(city) AS city,
  zip_code,
  UPPER(county) AS county,
  valid_from,
  
  -- The reigning record (rn=1) always gets the open-ended future date placeholder
  IF(rn = 1, DATE('2099-12-31'), valid_to) AS valid_to,
  
  -- If it's the most recent sequence row, it IS current. Period.
  IF(rn = 1, TRUE, FALSE) AS is_current

FROM store_sequenced;
-- dt_store contains 7830 rows

-- CROSS-WALK TABLES
-- Vendor Cross-walk Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.cwt_vendor` AS
WITH modern_vendor AS (
  SELECT DISTINCT
    vendor_number,
    FIRST_VALUE(vendor_name) OVER(PARTITION BY vendor_number ORDER BY valid_to DESC) AS modern_name
  FROM `iowa_liquor_biz.dt_vendor`
)
SELECT DISTINCT
  hist.vendor_number AS historical_vendor_number,
  hist.vendor_name AS historical_vendor_name,
  anchor.vendor_number AS modern_vendor_number,
  anchor.modern_name AS modern_vendor_name
FROM `iowa_liquor_biz.dt_vendor` hist
JOIN modern_vendor anchor 
  ON hist.vendor_number = anchor.vendor_number;
-- cwt_vendor contains 669 rows 

-- Store Cross-walk Table 
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.cwt_store` AS
WITH modern_store AS (
  SELECT DISTINCT
    store_number,
    FIRST_VALUE(store_name) OVER(PARTITION BY store_number ORDER BY valid_to DESC) AS modern_name,
    FIRST_VALUE(city) OVER(PARTITION BY store_number ORDER BY valid_to DESC) AS modern_city,
    FIRST_VALUE(county) OVER(PARTITION BY store_number ORDER BY valid_to DESC) AS modern_county
  FROM `iowa_liquor_biz.dt_store`
)
SELECT DISTINCT
  hist.store_number AS historical_store_number,
  hist.store_name AS historical_store_name,
  hist.city AS historical_city,          
  hist.county AS historical_county,
  anchor.store_number AS modern_store_number,
  anchor.modern_name AS modern_store_name,
  anchor.modern_city AS modern_city,
  anchor.modern_county AS modern_county
FROM `iowa_liquor_biz.dt_store` hist
JOIN modern_store anchor 
  ON hist.store_number = anchor.store_number;
-- cwt_store contains 4238 rows

-- Item Cross-walk Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.cwt_item` AS
WITH modern_item AS (
  SELECT DISTINCT
    item_number,
    FIRST_VALUE(item_description) OVER(PARTITION BY item_number ORDER BY valid_to DESC) AS modern_description,
    FIRST_VALUE(bottle_volume_ml) OVER(PARTITION BY item_number ORDER BY valid_to DESC) AS modern_volume
  FROM `iowa_liquor_biz.dt_item`
)
SELECT DISTINCT
  hist.item_number AS historical_item_number,
  hist.item_description AS historical_item_description,
  anchor.item_number AS modern_item_number,
  anchor.modern_description AS modern_item_description,
  anchor.modern_volume AS modern_bottle_volume_ml
FROM `iowa_liquor_biz.dt_item` hist
JOIN modern_item anchor 
  ON hist.item_number = anchor.item_number;
-- cwt_item contains 18364 rows 

-- Category Cross-walk Table
CREATE OR REPLACE TABLE `tibachap.iowa_liquor_biz.cwt_category` AS
WITH modern_anchor AS (
  SELECT DISTINCT
    category_code,
    FIRST_VALUE(category_name) OVER(PARTITION BY category_code ORDER BY valid_to DESC) AS modern_name
  FROM `iowa_liquor_biz.dt_category`
)
SELECT DISTINCT
  hist.category_code AS historical_code,
  hist.category_name AS historical_name,
  anchor.category_code AS modern_code,
  anchor.modern_name AS modern_name
FROM `iowa_liquor_biz.dt_category` hist
JOIN modern_anchor anchor 
  ON hist.category_code = anchor.category_code;
-- cwt_category contains 229 rows
