# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse_name": "",
# META       "default_lakehouse_workspace_id": ""
# META     }
# META   }
# META }

# CELL ********************

%run /EnvSettings

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# ### Spark session configuration
# This cell sets Spark session settings to enable _Verti-Parquet_ and _Optimize on Write_.

# CELL ********************

from delta.tables import *
from pyspark.sql.functions import *
import json
from pyspark.sql import DataFrame
import datetime

spark.conf.set("spark.sql.parquet.vorder.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.enabled", "true")
spark.conf.set("spark.microsoft.delta.optimizeWrite.binSize", "1073741824")
spark.conf.set('spark.ms.autotune.queryTuning.enabled', 'true')

#Low shuffle for untouched rows during MERGE
spark.conf.set("spark.microsoft.delta.merge.lowShuffle.enabled", "true")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # getAbfsPath()
# Gets the Azure Blob File System (ABFS) path of the OneLake medallion layer as URI abfss://workspaceId@onelake.dfs.fabric.microsoft.com/lakehouseID


# CELL ********************

def getAbfsPath(medallionLayer):
    # ##########################################################################################################################  
    # Function: getAbfsPath
    # Gets the Azure Blob File System (ABFS) path of the OneLake medallion layer 
    # as URI abfss://workspaceId@onelake.dfs.fabric.microsoft.com/lakehouseID
    # 
    # Parameters:
    # medallionLayer =  Medallion layer of data platform. Valid values are bronze, silver or gold.
    # 
    # Returns:
    # The ABFS URI as string

    validMedallionLayer = ["bronze","silver","gold"]
    assert medallionLayer in validMedallionLayer, "Invalid medallion layer. Valid values are bronze, silver or gold"

    AbfsPath =None
    workspaceId = None
    lhName = None

    match medallionLayer:
        case "bronze":
            workspaceId = bronzeWorkspaceId
            lhName = bronzeLakehouseName
        case "silver":
            workspaceId = silverWorkspaceId
            lhName = silverLakehouseName
        case "gold":
            workspaceId = goldWorkspaceId
            lhName = goldLakehouseName

    lh= notebookutils.lakehouse.getWithProperties(lhName,workspaceId)
    abfsPath = lh.properties["abfsPath"]

    return abfsPath

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # readFile()
# Reads a data file from Lakehouse and returns as Spark dataframe


# CELL ********************

def readFile(medallionLayer,container, folder, file, colSeparator=None, headerFlag=None):
  # ##########################################################################################################################  
  # Function: readFile
  # Reads a data file from Lakehouse and returns as spark dataframe
  # 
  # Parameters:
  # medallionLayer =  Medallion layer of data platform. Valid values are bronze, silver or gold.
  # container = Container of Lakehouse. Default value 'Files'
  # folder = Folder within container where data file resides. E.g 'raw-bronze/wwi/Sales/Orders/2013-01'
  # file = File name of data file including and file extension. E.g 'Sales_Orders_2013-01-01_000000.parquet'
  # colSeparator = Column separator for text files. Default value None
  # headerFlag = boolean flag to indicate whether the text file has a header or not. Default value None
  # 
  # Returns:
  # A dataframe of the data file
  # ##########################################################################################################################    
    validMedallionLayer = ["bronze","silver","gold"]
    assert medallionLayer in validMedallionLayer, "Invalid medallion layer. Valid values are bronze, silver or gold"
    assert container is not None, "container not provided"   
    assert folder is not None, "folder not provided"
    assert file is not None, "file not provided"

    abfsPath = getAbfsPath(medallionLayer)
    relativePath =   container + '/' + folder +'/' + file
    filePath = abfsPath + '/' + relativePath

    if ".csv" in file or ".txt" in file:
        df = spark.read.csv(path=filePath, sep=colSeparator, header=headerFlag, inferSchema="true")
    elif ".parquet" in file:
        df = spark.read.parquet(filePath)
    elif ".json" in file:
        df = spark.read.json(filePath, multiLine= True)
    elif ".orc" in file:
        df = spark.read.orc(filePath)
    else:
        df = spark.read.format("csv").load(filePath)
  
    df =df.dropDuplicates()
    return df

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # readMedallionLHTable()
# Retrieves a Lakehouse Table from the medallion layers, allowing for table filtering and specific column selection

# CELL ********************


def readMedallionLHTable(medallionLayer,tableRelativePath, filterCond=None, colList=None):
  # ##########################################################################################################################  
  # Function: readMedallionLHTable
  # Retrieves a Lakehouse Table from the medallion layers, allowing for table filtering and specific column selection
  # 
  # Parameters:
  # medallionLayer =  Medallion layer of data platform. Valid values are bronze, silver or gold.
  # tableRelativePath = Relative path of the LH table in format Tables/Schema/TableName
  # filterCond = A valid filter condition for the table, passed as string. E.g "ColorName == 'Salmon'". Default value is None. 
  #              If filterCond is None, the full table will be returned.
  # colList = Columns to be selected, passed as list. E.g. ["ColorID","ColorName"]. Default value is None.
  #           If colList is None, all columns in the table will be returned.
  # 
  # Returns:
  # A dataframe containing the Lakehouse table.
  # ##########################################################################################################################    
    validMedallionLayer = ["bronze","silver","gold"]
    assert medallionLayer in validMedallionLayer, "Invalid medallion layer. Valid values are bronze, silver or gold"
    abfsPath = getAbfsPath(medallionLayer)
    tablePath = abfsPath + '/' + tableRelativePath

    # check if table exists
    table = DeltaTable.forPath(spark,tablePath)
    assert table is not None, "Lakehouse table does not exist"

    df = spark.read.format("delta").load(tablePath)
    
    # Apply filter condition
    if filterCond is not None:
        df = df.filter(filterCond)

    # Select columns
    if colList is not None:
        df = df.select(colList)

    df =df.dropDuplicates()

    return df

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # readLHTable()
# Retrieves a any Lakehouse Table from OneLake, allowing for table filtering and specific column selection. Use this function to read from any Lakehouse in Onelake outside data platform for e.g. a mirrored database, Fabric SQL etc

# CELL ********************


def readLHTable(LakehouseName,tableRelativePath,WorkspaceID=None, filterCond=None, colList=None):
  # ##########################################################################################################################  
  # Function: readLHTable
  # Retrieves a any Lakehouse Table from OneLake, allowing for table filtering and specific column selection
  # Use this function to read from any Lakehouse in Onelake outside data platform for e.g a mirrored database, Fabric SQL etc
  #  
  # Parameters:
  # LakehouseName =  Name of lakehouse where table is located
  # tableRelativePath = Relative path of the table in format Tables/Schema/TableName
  # WorkspaceID = ID of Fabric Workspace where lakehouse is located. Default is None
  #               If WorkspaceID is None, the default Lakhouse attached to the notebook will be used.  
 
  # filterCond = A valid filter condition for the table, passed as string. E.g "ColorName == 'Salmon'". Default value is None. 
  #              If filterCond is None, the full table will be returned.
  # colList = Columns to be selected, passed as list. E.g. ["ColorID","ColorName"]. Default value is None.
  #           If colList is None, all columns in the table will be returned.
  # 
  # Returns:
  # A dataframe containing the Lakehouse table.
  # ##########################################################################################################################    
    lh = notebookutils.lakehouse.getWithProperties(LakehouseName,WorkspaceID)
    abfsPath = lh.properties["abfsPath"]
    tablePath = abfsPath + '/' + tableRelativePath

    # check if table exists
    table = DeltaTable.forPath(spark,tablePath)
    assert table is not None, "Lakehouse table does not exist"

    df = spark.read.format("delta").load(tablePath)
    
    # Apply filter condition
    if filterCond is not None:
        df = df.filter(filterCond)

    # Select columns
    if colList is not None:
        df = df.select(colList)

    df =df.dropDuplicates()

    return df

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # insertDelta()
# Inserts a dataframe to delta lake table. Creates a table with the schema of dataframe if the table doesn't already exist

# CELL ********************

def insertDelta (df, tableName, writeMode="append"):
  # ##########################################################################################################################  
  # Function: insertDelta
  # Inserts a dataframe to delta lake table. Creates a table with the schema of dataframe if the table doesn't already exist
  # 
  # Parameters:
  # df = Input dataframe
  # tableName = Target tableName in current lakehouse
  # mode = write mode. Valid values are "append", "overwrite". Default value "append"
  # 
  # Returns:
  # Json containing operational metrics.This is useful to get information like number of records inserted/updated.
  # E.g payload
  # {'numOutputRows': '4432', 'numOutputBytes': '87157', 'numFiles': '1'}
  # ##########################################################################################################################  
    validMode =[ "append", "overwrite"]
    assert writeMode in validMode, "Invalid mode specified"

    # Creating a delta table with schema name not supported at the time of writing this code, so replacing schema name with "_". To be commented out when this
    #feature is available
    tableName = tableName.replace(".","_")
    
    #Get delta table reference
    DeltaTable.createIfNotExists(spark).tableName(tableName).addColumns(df.schema).execute()
    deltaTable = DeltaTable.forName(spark,tableName)
    tableName =deltaTable.detail()
    tableName =deltaTable.detail().select("location").first()[0].split("/")[-1] #get last "/" substring from location attribute of delta table
    assert tableName is not None, "Delta table does not exist"
    
    df.write.format("delta").mode(writeMode).saveAsTable(tableName)
    
    stats = deltaTable.history(1).select("OperationMetrics").first()[0]
    print(stats)

    return stats

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # upsertDelta()
# Upserts a dataframe to delta lake table. Inserts record if they don't exist, updates existing if the version is newer than existing

# CELL ********************

def upsertDelta(df,tableName,keyColumns,watermarkColumn=None):
  # ##########################################################################################################################################   
  # Function: upsertDelta
  # Upserts a dataframe to delta lake table. Inserts record if they don't exist, updates existing if the version is newer than existing
  # 
  # Parameters:
  # df = Input dataframe
  # tableName = Target tableName in current lakehouse
  # mode = write mode. Valid values are "append", "overwrite". Default value "append"
  # 
  # Returns:
  # Json containing operational metrics.This is useful to get information like number of records inserted/updated.
  # E.g payload
  #     {'numOutputRows': '4432', 'numTargetRowsInserted': '0', 'numTargetFilesAdded': '1', 
  #     'numTargetFilesRemoved': '1', 'executionTimeMs': '2898', 'unmodifiedRewriteTimeMs': '606',
  #      'numTargetRowsCopied': '0', 'rewriteTimeMs': '921', 'numTargetRowsUpdated': '4432', 'numTargetRowsDeleted': '0',
  #      'scanTimeMs': '1615', 'numSourceRows': '4432', 'numTargetChangeFilesAdded': '0'}
  # ##########################################################################################################################################   

    # Creating a delta table with schema name not supported at the time of writing this code, so replacing schema name with "_". To be commented out when this
    #feature is available
    tableName = tableName.replace(".","_")

    #Get target table reference
    DeltaTable.createIfNotExists(spark).tableName(tableName).addColumns(df.schema).execute()
    target = DeltaTable.forName(spark,tableName)
    assert target is not None, "Target delta lake table does not exist"

    keyColumnsList = keyColumns.split("|")
   
    #Merge Condition
    joinCond=""
    for keyCol in keyColumnsList:
        joinCond = joinCond + "target." + keyCol + " = source." + keyCol +" and "

    remove = "and"
    reverse_remove = remove[::-1]
    joinCond = joinCond[::-1].replace(reverse_remove,"",1)[::-1]

    if watermarkColumn is not None:
        joinCond = joinCond + " and target." + watermarkColumn + " <= source." + watermarkColumn
    
    # Column mappings for insert and update
    mapCols =""
    for col in df.columns:
        mapCols = mapCols + '"' + col + '":' + ' "' + 'source.' + col + '" ,'

    remove = ","
    reverse_remove = remove[::-1]
    mapCols = mapCols[::-1].replace(reverse_remove,"",1)[::-1]

    #Convert Insert and Update Expression in to Dict
    updateStatement = json.loads("{"+mapCols+"}")
    insertStatement = json.loads("{"+mapCols+"}")

    (target.alias("target")
            .merge( df.alias('source'), joinCond)
            .whenMatchedUpdate(set = updateStatement)
            .whenNotMatchedInsert(values = insertStatement)
            .execute()
     )   

    # print(updateStatement)
    stats = target.history(1).select("OperationMetrics").first()[0]
    print(stats)

    return stats

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # getHighWaterMark()
# Retrieves High Watermark from a Lakehouse table for a given date range

# CELL ********************

def getHighWaterMark(lakehouseName,tableRelativePath,watermarkColName, fromRange, toRange, workspaceID=None):
  # ##########################################################################################################################  
  # Function: getHighWaterMark
  # Retrieves High Watermark from a Lakehouse table for a given date range
  #  
  # Parameters:
  # lakehouseName =  Name of lakehouse where table is located
  # tableRelativePath = Relative path of the table in format Tables/Schema/TableName
  # watermarkColName - Name of column used for watermark
  # fromRange - datetime of lower range of data in watermark column
  # toRange - datetime of upper range of data in watermark column
  # WorkspaceID = ID of Fabric Workspace where lakehouse is located. Default is None
  #               If WorkspaceID is None, the default Lakhouse attached to the notebook will be used.  
 
  # 
  # Returns:
  # A max value of the high watermark column for the datetime range
  # ##########################################################################################################################     
    assert watermarkColName is not None,"Watermark column name not provided"
    assert fromRange is not None,"fromRange datetime not provided"
    assert toRange is not None,"toRange datetime not provided"

    filterCond = watermarkColName +">" + "'" + fromRange +"'" + " and " + watermarkColName + "<=" + "'" + toRange + "'"
    df = readLHTable(lakehouseName,tableRelativePath,workspaceID,filterCond,watermarkColName)
    hwm = df.agg({watermarkColName: "max"}).collect()[0][0]

    return hwm

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # optimizeDelta()
# Compacts small files and removed unused files beyond default retention period for a Delta Table

# CELL ********************

def optimizeDelta(tableName):
  # ##########################################################################################################################################   
  # Function: optimizeDelta
  # Function that implements the compaction of small files for Delta Tables https://docs.delta.io/latest/optimizations-oss.html#language-python
  # Also removes unused files beyond default retention period and runs REORG TABLE to further optimize query performance.
  # 
  # Parameters:
  # tableName = Delta lake tableName in current lakehouse
  # 
  # Returns:
  # None
  # ##########################################################################################################################################   
    # Creating a delta table with schema name not supported at the time of writing this code, so replacing schema name with "_". To be commented out when this
    #feature is available
    tableName = tableName.replace(".","_")

    deltaTable = DeltaTable.forName(spark,tableName)
    assert deltaTable is not None, "Delta lake table does not exist"

    # Compact small files
    deltaTable.optimize().executeCompaction()

    # Remove unused files beyond retention period
    deltaTable.vacuum()

    # Run REORG TABLE for additional query performance optimization (Lakehouse SQL optimization)
    spark.sql(f"REORG TABLE {tableName} APPLY (PURGE)")

    return

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # readMirrorDBTable()
# Read from a mirrored DB table using a 4-part name: **_workspaceName.mirrorDBName.schemaName.tableName_**

# CELL ********************

def readMirrorDBTable(
    workspaceName: str,
    mirrorDBName: str,
    schemaName: str,
    tableName: str,
    watermarkColumnName: str = None,
    fromTimeStamp: str = None,
    toTimeStamp: str = None,
) -> DataFrame:

    """
    Read from a mirrored DB table using a 4-part name:
    workspaceName.mirrorDBName.schemaName.tableName

    Required:
        workspaceName, mirrorDBName, schemaName, tableName

    Optional:
        watermarkColumnName, fromTimeStamp, toTimeStamp
        If fromTimeStamp/toTimeStamp are provided, a WHERE clause on watermarkColumnName
        is added with the corresponding range.
    """

    # ---- Validation of required parameters ----
    for param_name, param_value in [
        ("workspaceName", workspaceName),
        ("mirrorDBName", mirrorDBName),
        ("schemaName", schemaName),
        ("tableName", tableName),
    ]:
        if not isinstance(param_value, str) or not param_value.strip():
            raise ValueError(f"Parameter '{param_name}' is required and must be a non-empty string.")

    # # ---- Validation for watermark usage ----
    # if (fromTimeStamp or toTimeStamp) and not watermarkColumnName:
    #     raise ValueError(
    #         "Parameter 'watermarkColumnName' is required when "
    #         "'fromTimeStamp' or 'toTimeStamp' is provided."
    #     )

    # ---- Validation: fromTimeStamp must be earlier than toTimeStamp ----
    if fromTimeStamp and toTimeStamp:
        try:
            from_dt = datetime.datetime.fromisoformat(fromTimeStamp)
            to_dt = datetime.datetime.fromisoformat(toTimeStamp)
        except ValueError:
            raise ValueError(
                "fromTimeStamp and toTimeStamp must be ISO-8601 datetime strings, "
                "e.g. '2013-01-01T00:00:00'."
            )
        if from_dt > to_dt:
            raise ValueError("fromTimeStamp must be earlier than toTimeStamp.")

    # Helper to safely quote identifiers (handles dashes etc.)
    def quote_identifier(identifier: str) -> str:
        # Escape any backticks inside the identifier
        escaped = identifier.replace("`", "``")
        return f"`{escaped}`"

    full_table_name = ".".join([
        quote_identifier(workspaceName),
        quote_identifier(mirrorDBName),
        quote_identifier(schemaName),
        quote_identifier(tableName),
    ])

    where_clauses = []

    if watermarkColumnName:
        col_expr = quote_identifier(watermarkColumnName)

        # Build range conditions if timestamps are provided
        if fromTimeStamp:
            # assuming timestamp literals are passed as strings compatible with Spark (e.g. '2024-01-01T00:00:00')
            where_clauses.append(f"{col_expr} >= TIMESTAMP '{fromTimeStamp}'")
        if toTimeStamp:
            where_clauses.append(f"{col_expr} < TIMESTAMP '{toTimeStamp}'")

    # Base query
    query = f"SELECT * FROM {full_table_name}"

    if where_clauses:
        query += " WHERE " + " AND ".join(where_clauses)

    # Execute via Spark SQL and return DataFrame
    df = spark.sql(query)
    return df

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
