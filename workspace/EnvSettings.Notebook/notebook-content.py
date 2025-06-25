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
bronzeWorkspaceId = "2836d0c5-10d4-49c7-89d1-0b244cb04b34"

# Bronze Lakehouse name. Set to None if not applicable.
bronzeLakehouseName = "lh_bronze"

# Bronze data warehouse name. Set to None if not applicable.
bronzeDatawarehouseName = None

# Fabric Workspace ID for the Silver medallion layer. Use the same ID if all medallion layers are in the same workspace.
silverWorkspaceId = "2836d0c5-10d4-49c7-89d1-0b244cb04b34"

# Silver Lakehouse name. Set to None if not applicable.
silverLakehouseName = "lh_silver"

# Silver data warehouse name. Set to None if not applicable.
silverDatawarehouseName = None

# Fabric Workspace ID for the Gold medallion layer. Use the same ID if all medallion layers are in the same workspace.
goldWorkspaceId = "2836d0c5-10d4-49c7-89d1-0b244cb04b34"

# Gold Lakehouse name. Set to None if not applicable.
goldLakehouseName = None

# Gold data warehouse name. Set to None if not applicable.
goldDatawarehouseName = "dw_gold"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
