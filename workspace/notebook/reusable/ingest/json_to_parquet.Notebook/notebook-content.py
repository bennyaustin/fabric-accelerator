# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

%run /EnvSettings

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

%run /commonTransforms

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

%run /DeltaLakeFunctions

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Notebook Parameters

# PARAMETERS CELL ********************

# API Config
api_url = None

# this notebook wasn't tested for the APIs needing bearer token.
key_vault_name = None 
secret_name = None 

# JSON Config
json_data_key = None
pagination_next_url_key = None
max_pages = None
stream_Name = None

# OneLake Destination
destination_raw_file_system = None
destination_raw_file_folder = None
destination_raw_file = None
destination_path = getAbfsPath('bronze')

# -------------------------------------------------------------------------
# INCREMENTAL CONFIGURATION
# -------------------------------------------------------------------------

last_watermark = None

# The API parameter name to filter by date (e.g., "updated_after", "since", "from_date")
api_date_param_name = None

# Set to "True" to enable incremental mode
incremental_mode = "True" if api_date_param_name else "False"

# The column inside the JSON data that contains the date value (to calculate the new max)(e.g., "updated_at")
json_date_column = None

# Default start date if this is the very first run (e.g., "2023-01-01T00:00:00Z")
initial_watermark_default = None

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# For Testing Purposes Only
# api_url = "https://api.ukhsa-dashboard.data.gov.uk/themes/climate_and_environment/sub_themes/seasonal_environmental/topics/heat-or-sunburn/geography_types/Nation/geographies/England/metrics/heat-or-sunburn_syndromic_NHS111triagedcalls_countsByDay"
# key_vault_name = "" 
# secret_name = "" 
# json_data_key = "results"
# pagination_next_url_key = "next"
# max_pages = 50
# stream_Name = "heat_or_sunburn"
# destination_raw_file_system = "Files"
# destination_raw_file_folder = "raw_bronze/public/heat_or_sunburn/1900-01"
# destination_raw_file = "heat_or_sunburn_1900-01-01_000000.parquet"
# destination_path = getAbfsPath('bronze')
## "abfss://FabricAccelerator@onelake.dfs.fabric.microsoft.com/bronze_fabric_accelerator.Lakehouse/Files/raw_bronze/public"
# last_watermark = ""
# api_date_param_name = ""
# incremental_mode = "True" if api_date_param_name else "False"
# json_date_column = ""
# initial_watermark_default = "2024-01-01"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Helper Functions & Setup

# CELL ********************

import requests
import pandas as pd
import json
from notebookutils import mssparkutils
from datetime import datetime

def get_nested_value(dic, dot_path):
    if not dot_path: return None
    keys = dot_path.split('.')
    value = dic
    try:
        for key in keys: value = value[key]
        return value
    except: return None

def add_query_param(url, key, value):
    """Safely adds a query parameter to a URL"""
    separator = "&" if "?" in url else "?"
    return f"{url}{separator}{key}={value}"

def get_headers(kv_name, sec_name):
    headers = {"Content-Type": "application/json", "User-Agent": "Fabric-Notebook"}
    if kv_name and sec_name:
        try:
            token = mssparkutils.credentials.getSecret(kv_name, sec_name)
            headers["Authorization"] = f"Bearer {token}"
        except: pass
    return headers

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # Main Execution

# CELL ********************

current_url = api_url 
headers = get_headers(key_vault_name, secret_name)
# batch_id = datetime.now().strftime("%Y-%m-%d_%H%M%S")
page_count = 0
total_records = 0
total_records_written = 0
final_watermark = ""

# Initialize an empty list to hold EVERYTHING
all_records = []

# Track watermark locally
global_max_date_found = None

# Handle Incremental Setup
if incremental_mode == "True":
    print(f"Incremental Mode ON. Fetching data since: {last_watermark}")
    
    # Modify URL with the watermark parameter
    current_url = add_query_param(current_url, api_date_param_name, last_watermark)
    
    # Initialize global max to the current watermark (in case API returns no data)
    global_max_date_found = last_watermark

print(f"Starting Extraction...")

try:
    # LOOP START
    while current_url and page_count < max_pages:
        page_count += 1
        print(f"Processing Page {page_count} | URL: {current_url}")
        
        response = requests.get(current_url, headers=headers)
        if response.status_code == 404: break
        response.raise_for_status()
        
        data = response.json()
        
        # Extract Records
        records = data
        if json_data_key and json_data_key in data:
            records = data[json_data_key]
        
        if isinstance(records, dict): records = [records]
        
        if not records or len(records) == 0:
            print("No records on this page.")
            break

        # Append to list instead of writing
        all_records.extend(records)

        # Next Page Logic
        next_link = get_nested_value(data, pagination_next_url_key)
        if next_link and next_link != current_url:
            current_url = next_link
        else:
            current_url = None
        # LOOP END

        total_records = len(all_records)
        print(f"Extraction finished. Total records collected: {total_records}")

        if total_records > 0:
            # Convert to DataFrame Once, Flatten & Write
            print("Flattening data...")
            pdf = pd.json_normalize(all_records).astype(str)
            total_records_written = len(pdf)
        
            # Clean columns
            pdf.columns = [c.replace(".", "_").replace(" ", "") for c in pdf.columns]     

            # Calculate Watermark (on the full dataset)
            if incremental_mode == "True" and json_date_column:
                # Check if column exists in the flattened data (replace . with _ for check)
                flat_date_col = json_date_column.replace(".", "_")
                if flat_date_col in pdf.columns:
                    # Get max value from pandas series
                    max_val = pdf[flat_date_col].max()
                    if max_val > global_max_date_found:
                        global_max_date_found = max_val

            writeFilePandas(pdf,'bronze',destination_raw_file_system,destination_raw_file_folder,destination_raw_file)

            if incremental_mode == "True" and total_records > 0:
                if global_max_date_found and global_max_date_found != last_watermark:
                    print(f"Updating Watermark to: {global_max_date_found}")
                    # define the value to return. 
                    final_watermark = global_max_date_found
                else:
                    # If no new max date was found, fallback to the previous watermark to stay safe.
                    print("Max date in new data is not newer than existing watermark. No update needed.")
                    final_watermark = last_watermark
    
    print(f"Success. Total Records: {total_records}")
    # mssparkutils.notebook.exit("Success")    

    # Create a dictionary of values you want to pass back
    exit_values = {
        "status": "Success",
        "rows_read": total_records,
        "rows_copied": total_records_written,
        "new_watermark": final_watermark
    }

    # Convert to JSON string
    exit_json = json.dumps(exit_values)

    print(f"Exiting with: {exit_json}")

    # Exit the notebook with the JSON string
    mssparkutils.notebook.exit(exit_json)    

except Exception as e:
    print(f"Error: {e}")
    raise e

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
