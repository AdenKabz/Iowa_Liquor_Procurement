# CREATING STORE MARKET RANKS TABLE (2016-2025)
import pandas as pd
import numpy as np

print("🔄 Generating 2016–2025 Store Procurement Ranks...")

# Using a dictionary for in-memory aggregation of chunks
store_data = {}
chunk_size = 250000

# Explicitly cast all ID columns to str to completely eliminate DtypeWarnings
id_dtypes = {
    'store_number': str,
    'item_number': str,
    'category_code': str,
    'vendor_number': str,
    'county_number': str
}

# Stream the core sales file
for chunk in pd.read_csv("final_daily_sales_core.csv", chunksize=chunk_size, dtype=id_dtypes):
    
    # Clean and parse dates for the target study window
    chunk["transaction_date"] = pd.to_datetime(chunk["transaction_date"])
    filtered_chunk = chunk[(chunk["transaction_date"].dt.year >= 2016) & (chunk["transaction_date"].dt.year <= 2025)].copy()
    
    if filtered_chunk.empty:
        continue
        
    # Standardize store IDs (removing trailing floats from messy entries)
    filtered_chunk["store_number"] = filtered_chunk["store_number"].str.replace(r'\.0$', '', regex=True).str.strip()
    
    # Calculate pure procurement spend (what the B2B store paid the state)
    filtered_chunk["store_spend"] = filtered_chunk["total_bottles_sold"] * filtered_chunk["avg_state_bottle_retail"]
    
    # Accumulate metrics per store
    for _, row in filtered_chunk.iterrows():
        st = row["store_number"]
        b_sold = row["total_bottles_sold"]
        
        if st not in store_data:
            store_data[st] = {"total_bottles_sold": 0, "total_procurement_spend": 0.0}
            
        store_data[st]["total_bottles_sold"] += b_sold
        store_data[st]["total_procurement_spend"] += row["store_spend"]

# Convert aggregated dictionary to DataFrame
df_store_ranks = pd.DataFrame.from_dict(store_data, orient='index').reset_index().rename(columns={'index': 'store_number'})

# Calculate Percentile Rank (0.0 = Top Spender / Major Chain, 1.0 = Lowest Spender)
df_store_ranks['store_procurement_rank'] = df_store_ranks['total_procurement_spend'].rank(ascending=False, method='min')
df_store_ranks['store_procurement_rank'] = (df_store_ranks['store_procurement_rank'] - 1) / (len(df_store_ranks) - 1)

# Round numeric values for clean saving
df_store_ranks['total_procurement_spend'] = df_store_ranks['total_procurement_spend'].round(2)

# Save out the clean lookup table
df_store_ranks.to_csv("STORE MARKET RANKS.csv", index=False)

print(f"💾 Success! Saved STORE MARKET RANKS.csv ({len(df_store_ranks):,} unique stores identified).")
print("✨ Ready to move on to the updated main data cleaning script.")
# 3080 unique stores were returned

# CREATING THE SALES FACT TABLE (2016-2025)
import os
import numpy as np
import pandas as pd

print("🚀 Starting Master Cleaning Script (2016-2025 Strict Procurement Timeline)...")

def clean_id_column(series):
    return series.astype(str).str.replace(r'\.0$', '', regex=True).str.strip()

print("📋 Loading matching dimensional schemas and refreshed store procurement ranks...")

# Strict string dtypes definition to stop chunking DtypeWarnings in their tracks
id_dtypes = {
    'item_number': str,
    'category_code': str,
    'store_number': str,
    'vendor_number': str,
    'county_number': str
}

# 1. Load Cross-walk / Mapping Tables
df_cwt_item = pd.read_csv("cwt_item.csv")
df_cwt_item["historical_item_number"] = clean_id_column(df_cwt_item["historical_item_number"])
df_cwt_item = df_cwt_item.drop_duplicates(subset=["historical_item_number"], keep="first")

df_cwt_category = pd.read_csv("cwt_category.csv")
df_cwt_category["historical_code"] = clean_id_column(df_cwt_category["historical_code"])
df_cwt_category["modern_code"] = clean_id_column(df_cwt_category["modern_code"])
df_cwt_category = df_cwt_category.drop_duplicates(subset=["historical_code"], keep="first")

df_cwt_vendor = pd.read_csv("cwt_vendor.csv")
df_cwt_vendor["historical_vendor_number"] = clean_id_column(df_cwt_vendor["historical_vendor_number"])
df_cwt_vendor = df_cwt_vendor.drop_duplicates(subset=["historical_vendor_number"], keep="first")

df_cwt_store = pd.read_csv("cwt_store.csv")
df_cwt_store["historical_store_number"] = clean_id_column(df_cwt_store["historical_store_number"])
df_cwt_store = df_cwt_store.drop_duplicates(subset=["historical_store_number"], keep="first")

# 2. Load Refreshed 2016-2025 Store Procurement Ranks
df_store_ranks = pd.read_csv("STORE MARKET RANKS.csv")
df_store_ranks["store_number"] = clean_id_column(df_store_ranks["store_number"])
store_rank_map = df_store_ranks.set_index("store_number")["store_procurement_rank"].to_dict()

# 3. Load Date-Effective (SCD Type 2) Dimension Tables
df_dt_category = pd.read_csv("dt_category.csv")
df_dt_vendor = pd.read_csv("dt_vendor.csv")
df_dt_store = pd.read_csv("dt_store.csv")
df_dt_item = pd.read_csv("dt_item.csv")

for df in [df_dt_category, df_dt_vendor, df_dt_store, df_dt_item]:
    df["valid_from"] = pd.to_datetime(df["valid_from"])
    df["valid_to"] = pd.to_datetime(df["valid_to"])

df_dt_category["category_code"] = clean_id_column(df_dt_category["category_code"])
df_dt_store["store_number"] = clean_id_column(df_dt_store["store_number"])
df_dt_item["item_number"] = clean_id_column(df_dt_item["item_number"])
df_dt_vendor["vendor_number"] = clean_id_column(df_dt_vendor["vendor_number"])

# Clean key types safely to handle hexadecimal text conversion mapping beautifully
df_dt_category["category_sk"] = df_dt_category["category_sk"].astype(str).str.strip().str.lower()
df_dt_vendor["vendor_sk"] = df_dt_vendor["vendor_sk"].astype(str).str.strip().str.lower()
df_dt_store["store_sk"] = df_dt_store["store_sk"].astype(str).str.strip().str.lower()
df_dt_item["item_sk"] = df_dt_item["item_sk"].astype(str).str.strip().str.lower()

# Chunking configurations for handling massive datasets smoothly
base_output_name = "cleaned_data_final_part"
chunk_size = 200000        
rows_per_file = 2000000    

file_number = 1
rows_written_to_current_file = 0
df_accumulator = []

# Final structural schema columns
final_columns = [
    "transaction_date", "calendar_year", "calendar_month", "day_of_week", "calendar_season",
    "category_sk", "vendor_sk", "store_sk", "item_sk",
    "pack", "bottle_volume_ml", "bottles_sold", "state_bottle_cost", "state_bottle_retail",
    "sales_dollars", "volume_sold_liters", "total_cases_sold", "price_per_liter", 
    "product_premium_tier", "is_split_case", "order_size_category", "is_major_chain",
    "store_location", "county_number"
]

def get_temporal_sk(chunk_df, dim_df, chunk_key, dim_key, sk_column):
    merged = chunk_df[[chunk_key, 'transaction_date']].reset_index().merge(
        dim_df[[dim_key, 'valid_from', 'valid_to', sk_column]], 
        left_on=chunk_key, right_on=dim_key, how='left'
    )
    valid_mask = (merged['transaction_date'] >= merged['valid_from']) & (merged['transaction_date'] <= merged['valid_to'])
    matched = merged[valid_mask].set_index('index')[sk_column]
    matched = matched[~matched.index.duplicated(keep='first')]
    return matched

print(f"⏳ Streaming transactional lines and transforming metrics...")

# Stream and map chunks
for df_sales in pd.read_csv("final_daily_sales_core.csv", chunksize=chunk_size, dtype=id_dtypes):
    
    df_sales["transaction_date"] = pd.to_datetime(df_sales["transaction_date"])
    
    # Core constraint: Enforce strict 2016-2025 timeline boundaries
    df_sales = df_sales[(df_sales["transaction_date"].dt.year >= 2016) & (df_sales["transaction_date"].dt.year <= 2025)].copy()
    
    if df_sales.empty:
        continue
    
    # Standardize textual IDs
    df_sales["category_code_str"] = clean_id_column(df_sales["category_code"])
    df_sales["store_number_str"] = clean_id_column(df_sales["store_number"])
    df_sales["item_number_str"] = clean_id_column(df_sales["item_number"])
    df_sales["vendor_number_str"] = clean_id_column(df_sales["vendor_number"])

    # Resolve cross-walk history mappings
    df_sales = df_sales.merge(df_cwt_item[["historical_item_number", "modern_item_description"]], left_on="item_number_str", right_on="historical_item_number", how="left")
    df_sales = df_sales.merge(df_cwt_category[["historical_code", "modern_code"]], left_on="category_code_str", right_on="historical_code", how="left")
    df_sales["clean_category_code"] = df_sales["modern_code"].fillna(df_sales["category_code_str"]).astype(str)
    
    df_sales = df_sales.merge(df_cwt_store[["historical_store_number", "modern_store_number"]], left_on="store_number_str", right_on="historical_store_number", how="left")
    df_sales["clean_store_number"] = df_sales["modern_store_number"].fillna(df_sales["store_number_str"]).astype(str)
    
    df_sales = df_sales.merge(df_cwt_vendor[["historical_vendor_number", "modern_vendor_number"]], left_on="vendor_number_str", right_on="historical_vendor_number", how="left")
    df_sales["clean_vendor_number"] = df_sales["modern_vendor_number"].fillna(df_sales["vendor_number_str"]).astype(str)

    df_sales.drop(columns=["historical_item_number", "historical_code", "modern_code",
                           "historical_store_number", "modern_store_number", "historical_vendor_number", "modern_vendor_number"], inplace=True, errors="ignore")

    # Temporal Dimension Surrogate Key assignment
    df_sales['category_sk'] = get_temporal_sk(df_sales, df_dt_category, 'clean_category_code', 'category_code', 'category_sk')
    df_sales['vendor_sk'] = get_temporal_sk(df_sales, df_dt_vendor, 'clean_vendor_number', 'vendor_number', 'vendor_sk')
    df_sales['store_sk'] = get_temporal_sk(df_sales, df_dt_store, 'clean_store_number', 'store_number', 'store_sk')
    df_sales['item_sk'] = get_temporal_sk(df_sales, df_dt_item, 'item_number_str', 'item_number', 'item_sk')

    df_sales['category_sk'] = df_sales['category_sk'].fillna('unmapped_category')
    df_sales['vendor_sk'] = df_sales['vendor_sk'].fillna('unmapped_vendor')
    df_sales['store_sk'] = df_sales['store_sk'].fillna('unmapped_store')
    df_sales['item_sk'] = df_sales['item_sk'].fillna('unmapped_item')

    # Date hierarchies
    df_sales['calendar_year'] = df_sales['transaction_date'].dt.year
    df_sales['calendar_month'] = df_sales['transaction_date'].dt.strftime('%b')
    df_sales['day_of_week'] = df_sales['transaction_date'].dt.strftime('%A')
    
    month_to_season = {12: 'WINTER', 1: 'WINTER', 2: 'WINTER', 3: 'SPRING', 4: 'SPRING', 5: 'SPRING',
                       6: 'SUMMER', 7: 'SUMMER', 8: 'SUMMER', 9: 'AUTUMN', 10: 'AUTUMN', 11: 'AUTUMN'}
    df_sales['calendar_season'] = df_sales['transaction_date'].dt.month.map(month_to_season)

    # Pure Procurement Fact calculations
    df_sales['sales_dollars'] = df_sales['total_bottles_sold'] * df_sales['avg_state_bottle_retail']
    df_sales['volume_sold_liters'] = (df_sales['bottle_volume_ml'] * df_sales['total_bottles_sold']) / 1000.0
    df_sales['total_cases_sold'] = df_sales['total_bottles_sold'] / df_sales['pack'].astype(float)
    df_sales['price_per_liter'] = np.where(df_sales['volume_sold_liters'] > 0, df_sales['sales_dollars'] / df_sales['volume_sold_liters'], 0.0)
    
    # Logistics Pick-Friction flags
    df_sales['is_split_case'] = (df_sales['total_bottles_sold'] % df_sales['pack'] != 0)
    
    order_conditions = [
        (df_sales['total_bottles_sold'] < 6),
        (df_sales['total_bottles_sold'] >= 6) & (df_sales['total_cases_sold'] <= 2.0),
        (df_sales['total_cases_sold'] > 2.0) & (df_sales['total_cases_sold'] <= 50.0)
    ]
    df_sales['order_size_category'] = np.select(order_conditions, ['INDIVIDUAL BOTTLE RUN', 'BOUTIQUE FILL', 'COMMERCIAL RESTOCK'], default='MASSIVE ALLOCATION')

    # Assign 2016-2025 Store Procurement Percentile Rank map
    df_sales['store_procurement_rank'] = df_sales['store_number_str'].map(store_rank_map)
    df_sales['is_major_chain'] = df_sales['store_procurement_rank'] <= 0.10

    # Clean standardized pricing tiers
    df_sales['product_premium_tier'] = np.select(
        [df_sales['price_per_liter'] < 15.0, (df_sales['price_per_liter'] >= 15.0) & (df_sales['price_per_liter'] < 30.0), (df_sales['price_per_liter'] >= 30.0) & (df_sales['price_per_liter'] < 50.0)],
        ['ECONOMY', 'STANDARD', 'PREMIUM'], default='ULTRA-PREMIUM'
    )

    df_sales['store_location'] = df_sales['raw_store_location']
    df_sales.rename(columns={'total_bottles_sold': 'bottles_sold', 'avg_state_bottle_cost': 'state_bottle_cost', 'avg_state_bottle_retail': 'state_bottle_retail'}, inplace=True)

    # Scale rounding adjustments
    round_2_cols = ['state_bottle_cost', 'state_bottle_retail', 'sales_dollars', 'total_cases_sold', 'price_per_liter']
    df_sales[round_2_cols] = df_sales[round_2_cols].round(2)
    df_sales['volume_sold_liters'] = df_sales['volume_sold_liters'].round(4)
    df_sales['transaction_date'] = df_sales['transaction_date'].dt.strftime('%Y-%m-%d')

    # Consolidate processed records to output chunks
    df_accumulator.append(df_sales[final_columns])
    rows_written_to_current_file += len(df_sales)

    if rows_written_to_current_file >= rows_per_file:
        df_output = pd.concat(df_accumulator, ignore_index=True)
        output_filename = f"{base_output_name}_{file_number}.csv.gz"
        df_output.to_csv(output_filename, index=False, compression="gzip")
        print(f"💾 Generated Clean Chunk File {file_number}: {output_filename}")
        
        file_number += 1
        df_accumulator = []
        rows_written_to_current_file = 0

# Empty the remaining lines in memory out to a final chunk file
if df_accumulator:
    df_output = pd.concat(df_accumulator, ignore_index=True)
    output_filename = f"{base_output_name}_{file_number}.csv.gz"
    df_output.to_csv(output_filename, index=False, compression="gzip")
    print(f"💾 Generated Final Clean Chunk File {file_number}: {output_filename}")

print("\n✨ Success! All data files successfully rebuilt with rigorous, airtight B2B analytics definitions.")
# 13 .csv.gz files were created

# Note: Null values were preserved to ensure data integrity and no loss of data
