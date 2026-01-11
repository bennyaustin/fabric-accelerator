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

# # writeFile()
# Writes a data file to Lakehouse

# CELL ********************

def writeFile(df, medallionLayer, container, folder, file, mode="overwrite", colSeparator=",", headerFlag=True):
  # ##########################################################################################################################  
  # Function: writeFile
  # Writes a spark dataframe to the Lakehouse in the specified format
  # 
  # Parameters:
  # df = The Spark Dataframe to write
  # medallionLayer = Medallion layer of data platform. Valid values are bronze, silver or gold.
  # container = Container of Lakehouse. Default value 'Files'
  # folder = Folder within container where data file will be written.
  # file = File name including extension. E.g 'Sales_Orders.parquet'
  # mode = Write mode. Default 'overwrite'. Options: 'append', 'ignore', 'error', 'overwrite'.
  # colSeparator = Column separator for text files. Default value ","
  # headerFlag = boolean flag to indicate whether to write the header for text files. Default value True
  # 
  # Returns:
  # None
  # ##########################################################################################################################    
    validMedallionLayer = ["bronze", "silver", "gold"]
    assert medallionLayer in validMedallionLayer, "Invalid medallion layer. Valid values are bronze, silver or gold"
    assert df is not None, "Dataframe (df) not provided"
    assert container is not None, "container not provided"   
    assert folder is not None, "folder not provided"
    assert file is not None, "file not provided"

    # Construct the full ABFS path
    abfsPath = getAbfsPath(medallionLayer)
    relativePath = container + '/' + folder + '/' + file
    filePath = abfsPath + '/' + relativePath

    # Determine format based on file extension and write
    if ".csv" in file or ".txt" in file:
        df.write.mode(mode).csv(path=filePath, sep=colSeparator, header=headerFlag)
    elif ".parquet" in file:
        df.write.mode(mode).parquet(filePath)
    elif ".json" in file:
        df.write.mode(mode).json(filePath)
    elif ".orc" in file:
        df.write.mode(mode).orc(filePath)
    elif ".delta" in file: 
        # Added Delta support as it is standard for Medallion Architectures
        df.write.mode(mode).format("delta").save(filePath)
    else:
        # Default fallback (usually Parquet or CSV depending on config, but explicit is safer)
        print(f"Warning: Unknown file extension for '{file}'. Defaulting to Parquet.")
        df.write.mode(mode).parquet(filePath)

    print(f"Successfully wrote data to: {filePath}")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# # writeFilePandas()
# Writes a data file to Lakehouse but using Pandas Dataframe

# CELL ********************

import pandas as pd

def writeFilePandas(df, medallionLayer, container, folder, file, mode="w", colSeparator=",", headerFlag=True, storage_options=None):
  # ##########################################################################################################################  
  # Function: writeFilePandas
  # Writes a Pandas dataframe to the Lakehouse in the specified format
  # 
  # Parameters:
  # df = The Pandas Dataframe to write
  # medallionLayer = Medallion layer. Valid values: bronze, silver, gold.
  # container = Container of Lakehouse.
  # folder = Folder within container.
  # file = File name including extension. E.g 'Sales_Orders.parquet'
  # mode = Write mode. Default 'w' (overwrite). Use 'a' for append (Text/CSV only).
  # colSeparator = Column separator for text files. Default ","
  # headerFlag = boolean flag for header in text files. Default True
  # storage_options = Dict for Azure auth (e.g., {'account_key': '...'} or {'sas_token': '...'}).
  # 
  # Returns:
  # None
  # ##########################################################################################################################    
    validMedallionLayer = ["bronze", "silver", "gold"]
    assert medallionLayer in validMedallionLayer, "Invalid medallion layer. Valid values are bronze, silver or gold"
    assert df is not None, "Dataframe (df) not provided"
    assert not df.empty, "Dataframe is empty"
    assert container is not None, "container not provided"   
    assert folder is not None, "folder not provided"
    assert file is not None, "file not provided"

    # Construct the full ABFS path
    # Note: Ensure getAbfsPath is available in your scope
    abfsPath = getAbfsPath(medallionLayer)
    relativePath = container + '/' + folder + '/' + file
    filePath = abfsPath + '/' + relativePath

    # Handle 'overwrite' vs 'append' mode translation from Spark to Pandas
    # Pandas uses 'w' for write/overwrite and 'a' for append
    pandas_mode = 'a' if mode == 'append' else 'w'
    
    # Header logic for append mode (usually don't want header if appending)
    write_header = headerFlag
    if pandas_mode == 'a':
        write_header = False 

    try:
        if ".csv" in file or ".txt" in file:
            df.to_csv(filePath, sep=colSeparator, index=False, header=write_header, mode=pandas_mode, storage_options=storage_options)
            
        elif ".parquet" in file:
            # Pandas/PyArrow generally overwrites Parquet files. 'Append' is not natively supported for single files.
            df.to_parquet(filePath, index=False, storage_options=storage_options)
            
        elif ".json" in file:
            # orient='records' is standard for data interoperability
            df.to_json(filePath, orient='records', lines=True, storage_options=storage_options)
            
        elif ".orc" in file:
            # Requires pyarrow to be installed
            df.to_orc(filePath, index=False, storage_options=storage_options)
            
        else:
            print(f"Warning: Unknown extension '{file}'. Defaulting to Parquet.")
            df.to_parquet(filePath, index=False, storage_options=storage_options)

        print(f"Successfully wrote Pandas data to: {filePath}")

    except Exception as e:
        print(f"Error writing file: {e}")
        # Logic to suggest installing adlfs if the protocol is not understood
        if "Protocol not known" in str(e) and "abfss" in filePath:
            print("Tip: Ensure the library 'adlfs' is installed to write to Azure Data Lake paths with Pandas.")

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
  # Also removes unused files beyond default retention period
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
    deltaTable.optimize().executeCompaction()
    deltaTable.vacuum()
    return

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }