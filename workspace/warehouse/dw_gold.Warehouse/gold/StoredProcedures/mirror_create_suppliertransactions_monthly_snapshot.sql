CREATE PROCEDURE [gold].[mirror_create_suppliertransactions_monthly_snapshot]
	(@L2TransformInstanceID INT NULL = NULL
	, @L2TransformID INT NULL = NULL
	, @IngestID INT NULL = NULL
	, @L1TransformID INT NULL = NULL
	, @CustomParameters VARCHAR(max) NULL = NULL
	, @InputType VARCHAR(15) NULL = NULL
	, @InputFileSystem VARCHAR(50) NULL = NULL
	, @InputFileFolder VARCHAR(200) NULL = NULL
	, @InputFile VARCHAR(200) NULL = NULL
	, @InputFileDelimiter CHAR(1)  NULL = NULL
	, @InputFileHeaderFlag BIT NULL = NULL
	, @InputDWTable VARCHAR(200) NULL = NULL
	, @WatermarkColName VARCHAR(50) NULL = NULL
	, @DataFromTimestamp DATETIME NULL = NULL
	, @DataToTimestamp DATETIME NULL = NULL
	, @DataFromNumber INT NULL = NULL
	, @DataToNumber INT NULL = NULL
	, @OutputL2CurateFileSystem VARCHAR(50) NULL = NULL
	, @OutputL2CuratedFolder VARCHAR(200) NULL = NULL
	, @OutputL2CuratedFile VARCHAR(200) NULL = NULL
	, @OutputL2CuratedFileDelimiter CHAR(1) NULL = NULL
	, @OutputL2CuratedFileFormat VARCHAR(10) NULL = NULL
	, @OutputL2CuratedFileWriteMode VARCHAR(20) NULL = NULL
	, @OutputDWStagingTable VARCHAR(200) NULL = NULL
	, @LookupColumns VARCHAR(20) NULL = NULL
	, @OutputDWTable VARCHAR(200) NULL = NULL
	, @OutputDWTableWriteMode VARCHAR(20) NULL = NULL
)
AS
BEGIN

    IF EXISTS (select 1 from [INFORMATION_SCHEMA].[TABLES] WHERE TABLE_TYPE ='BASE TABLE' AND TABLE_SCHEMA ='gold' AND TABLE_NAME ='Mirror_SupplierTransactions_monthly_snapshot')
        DROP TABLE [gold].[Mirror_SupplierTransactions_monthly_snapshot]

    CREATE TABLE [gold].[Mirror_SupplierTransactions_monthly_snapshot] AS
    SELECT
        spt.[SupplierID],
        tt.[TransactionTypeName],
        DATEFROMPARTS(YEAR(spt.[TransactionDate]), MONTH(spt.[TransactionDate]), 1) AS [TransactionDate],
        SUM(spt.[AmountExcludingTax]) AS [POAmount],
        SUM(spt.[TaxAmount]) AS [TaxAmount],
        COUNT(1) AS [POCount]
    FROM [lh_silver].[dbo].[silver_mirror_purchasing_suppliertransactions] spt
        INNER JOIN [lh_silver].[dbo].[silver_application_transactiontypes] tt
            ON tt.[TransactionTypeID] = spt.[TransactionTypeID]
    GROUP BY
        spt.[SupplierID],
        tt.[TransactionTypeName],
        DATEFROMPARTS(YEAR(spt.[TransactionDate]), MONTH(spt.[TransactionDate]), 1);
END
