# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "9698f505-ed87-41d0-9462-c21742a18276",
# META       "default_lakehouse_name": "lh_silver",
# META       "default_lakehouse_workspace_id": "ec8c533b-0c7b-4cbf-b081-b02bcd4894da"
# META     }
# META   }
# META }

# CELL ********************

%run /DeltaLakeFunctions

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ### Iterate through all tables in lakehouse and run OPTIMIZE and VACCUM commands

# CELL ********************

df = spark.sql("show tables")
tableList = df.select("tableName").rdd.flatMap(lambda x:x).collect()
# print (tables)
for table in tableList:
    print ("optimizing",table)
    optimizeDelta(table)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
