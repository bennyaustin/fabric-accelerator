# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "cc80a0ab-603d-4df9-bdfc-c35a7e8ab095",
# META       "default_lakehouse_name": "lh_silver",
# META       "default_lakehouse_workspace_id": "2836d0c5-10d4-49c7-89d1-0b244cb04b34"
# META     }
# META   }
# META }

# MARKDOWN ********************

# # Notebook for Unit Testing DeltaLakeFunctions

# CELL ********************

%run /DeltaLakeFunctions 

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readFile("bronze","Files","raw-bronze/wwi/Sales/Orders/2013-01","Sales_Orders_2013-01-01_000000.parquet")
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

upsertDelta(df,"sales_orders","OrderID|CustomerID","LastEditedWhen")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

insertDelta (df, "sales_orders", "append")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

optimizeDelta("silver_sales_customertransactions")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readMedallionLHTable("silver","Tables/dbo/silver_warehouse_colors")
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readMedallionLHTable("silver","Tables/dbo/silver_warehouse_colors","ColorName == 'Salmon'")
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readMedallionLHTable("silver","Tables/dbo/silver_warehouse_colors","ColorName == 'Salmon'",["ColorID","ColorName"])
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readMedallionLHTable("silver","Tables/dbo/silver_warehouse_colors",None,["ColorID","ColorName"])
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readMedallionLHTable("silver","Tables/dbo/silver_warehouse_colors","ColorName == 'Salmon'",None)
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readLHTable("lh_fabricEvents","Tables/jobs/pipelineJobs","582b9e24-0962-4fd0-aee5-647d9c200685", filterCond=None, colList=None)
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readLHTable("lh_fabricEvents","Tables/jobs/pipelineJobs","582b9e24-0962-4fd0-aee5-647d9c200685", "EventProcessedUtcTime >'2025-02-07 20:42:19.269818'", colList=None)
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readLHTable("lh_fabricEvents","Tables/jobs/pipelineJobs","582b9e24-0962-4fd0-aee5-647d9c200685", "EventProcessedUtcTime >'2025-02-07 20:42:19.269818'", ["id","data","EventProcessedUtcTime"])
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readLHTable("lh_fabricEvents","Tables/jobs/pipelineJobs","582b9e24-0962-4fd0-aee5-647d9c200685", "EventProcessedUtcTime >'2025-02-07 20:42:19.269818'", None)
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df = readLHTable("lh_fabricEvents","Tables/jobs/pipelineJobs","582b9e24-0962-4fd0-aee5-647d9c200685", None, ["id","data","EventProcessedUtcTime"])
display(df)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

hwm = getHighWaterMark("lh_fabricEvents","Tables/jobs/pipelineJobs","EventProcessedUtcTime", "2025-02-07 14:00:00.0000000", "2025-02-08 14:00:00.0000000", "582b9e24-0962-4fd0-aee5-647d9c200685")
print(hwm)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
