CREATE PROCEDURE [gold].[mirror_create_orders_monthly_snapshot]
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
    IF OBJECT_ID('[gold].[Mirror_Orders_monthly_snapshot]', 'U') IS NOT NULL
    BEGIN
        DROP TABLE [gold].[Mirror_Orders_monthly_snapshot];
    END

    CREATE TABLE [gold].[Mirror_Orders_monthly_snapshot] AS
    SELECT
        p.[PersonID] AS [SalespersonPersonID],
        p.[FullName],
        DATEFROMPARTS(YEAR(o.[OrderDate]), MONTH(o.[OrderDate]), 1) AS [OrderMonth],
        COUNT(1) AS [OrderCount]
    FROM
        [lh_silver].[dbo].[silver_mirror_sales_orders] o
        INNER JOIN [lh_silver].[dbo].[silver_mirror_application_people] p
            ON o.[SalespersonPersonID] = p.[PersonID]
            AND p.[IsSalesperson]=1
    GROUP BY
        p.[PersonID],
        p.[FullName],
        DATEFROMPARTS(YEAR(o.[OrderDate]), MONTH(o.[OrderDate]), 1);
END