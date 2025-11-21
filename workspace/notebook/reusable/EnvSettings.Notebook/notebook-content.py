# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# MARKDOWN ********************

# # Environment Variables
# Use this notebook to set environment specific variables that can be referenced in other spark notebooks. These variables need to set once in each environment

# CELL ********************

# Fabric Workspace ID for the Bronze medallion layer
bronzeWorkspaceId = "a51521f1-f017-4766-b3c2-4ac2c456dfcc"

# Bronze Lakehouse name. Set to None if not applicable.
bronzeLakehouseName = "lh_bronze"

# Bronze data warehouse name. Set to None if not applicable.
bronzeDatawarehouseName = None

# Fabric Workspace ID for the Silver medallion layer. Use the same ID if all medallion layers are in the same workspace.
silverWorkspaceId = "a51521f1-f017-4766-b3c2-4ac2c456dfcc"

# Silver Lakehouse name. Set to None if not applicable.
silverLakehouseName = "lh_silver"

# Silver data warehouse name. Set to None if not applicable.
silverDatawarehouseName = None

# Fabric Workspace ID for the Gold medallion layer. Use the same ID if all medallion layers are in the same workspace.
goldWorkspaceId = "a51521f1-f017-4766-b3c2-4ac2c456dfcc"

# Gold Lakehouse name. Set to None if not applicable.
goldLakehouseName = None

# Gold data warehouse name. Set to None if not applicable.
goldDatawarehouseName = "dw_gold"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
