CREATE PROCEDURE [ELT].[InsertTransformInstance_L1]
	--PK/FK
	@L1TransformID int = null,
	@IngestInstanceID int=null,
	@IngestID int,

	--Databricks Notebook
	@ComputeName varchar(100) = null,
	@ComputePath varchar(200) = null,
	
	--Custom
	@CustomParameters varchar(max) = null,

	--Input File
	@InputRawFileSystem varchar(50) = null,
    @InputRawFileFolder varchar(200) = null,
    @InputRawFile varchar(200) = null,
    @InputRawFileDelimiter char(1) = null,
	@InputFileHeaderFlag bit = null,

	--Input Table
	@InputRawTable varchar(200) = null,
	@DataFromTimestamp dateTime2 = null,
	@DataToTimestamp datetime2 = null,
	
	--Curated File 
	@OutputL1CurateFileSystem varchar(50) = null,
    @OutputL1CuratedFolder varchar(200) = null,
    @OutputL1CuratedFile varchar(200) = null,
    @OutputL1CuratedFileDelimiter char(1) = null,
    @OutputL1CuratedFileFormat varchar(10) = null,
    @OutputL1CuratedFileWriteMode varchar(20) = null,
    
	--SQL
	@OutputDWStagingTable varchar(200) = null,
	@LookupColumns varchar(4000) = null,
    @OutputDWTable varchar(200) = null,
    @OutputDWTableWriteMode varchar(20) = null,
    @IngestCount int = null,

	--ADF Pipeline IDs
	@IngestADFPipelineRunID  uniqueidentifier = null




AS
BEGIN


DECLARE @localdate as datetime	= CONVERT(datetime,CONVERT(datetimeoffset, getdate()) at time zone 'AUS Eastern Standard Time')

DECLARE @ExistsCount int = 0;

	--Check if Transformation records already exists for the same transformation e.g it's a reload
	--Separate branches for file-based vs table-based inputs keep predicates as simple equalities (SARGable)
	IF @InputRawFile IS NOT NULL
	BEGIN
		--File-based input path
		SELECT @ExistsCount = COUNT(1)
		FROM [ELT].[L1TransformInstance]
		WHERE
			[IngestID] = @IngestID
			AND L1TransformID = @L1TransformID
			AND InputRawFileSystem = @InputRawFileSystem
			AND InputRawFileFolder = @InputRawFileFolder
			AND InputRawFile = @InputRawFile
	END
	ELSE IF @InputRawTable IS NOT NULL
	BEGIN
		--Table-based input path (e.g. Fabric Mirroring ELT pattern)
		SELECT @ExistsCount = COUNT(1)
		FROM [ELT].[L1TransformInstance]
		WHERE
			[IngestID] = @IngestID
			AND L1TransformID = @L1TransformID
			AND InputRawTable = @InputRawTable
			AND DataFromTimestamp = @DataFromTimestamp
			AND DataToTimestamp = @DataToTimestamp
	END

	IF @ExistsCount = 0
	BEGIN
	--If this is a new transformation
		INSERT INTO [ELT].[L1TransformInstance]
			(
				[L1TransformID]
				,[IngestInstanceID]
				,[IngestID]
				,[ComputeName]
				,[ComputePath]
				,[CustomParameters]
				,[InputRawFileSystem]
				,[InputRawFileFolder]
				,[InputRawFile]
				,[InputRawFileDelimiter]
				,[InputFileHeaderFlag]
				,[InputRawTable]
				,[DataFromTimestamp]
				,[DataToTimestamp]
				,[OutputL1CurateFileSystem]
				,[OutputL1CuratedFolder]
				,[OutputL1CuratedFile]
				,[OutputL1CuratedFileDelimiter]
				,[OutputL1CuratedFileFormat]
				,[OutputL1CuratedFileWriteMode]
				,[OutputDWStagingTable]
				,[LookupColumns]
				,[OutputDWTable]
				,[OutputDWTableWriteMode]
				,[RetryCount]
				,[ActiveFlag]
				,[IngestCount]
				,[IngestADFPipelineRunID]
				,[CreatedBy]
				,[CreatedTimestamp]
			   
			)
		VALUES
			(
				@L1TransformID
				,@IngestInstanceID
				,@IngestID
				,@ComputeName
				,@ComputePath
				,@CustomParameters
				,@InputRawFileSystem
				,@InputRawFileFolder
				,@InputRawFile
				,@InputRawFileDelimiter
				,@InputFileHeaderFlag
				,@InputRawTable
				,@DataFromTimestamp
				,@DataToTimestamp
				,@OutputL1CurateFileSystem
				,@OutputL1CuratedFolder
				,@OutputL1CuratedFile
				,@OutputL1CuratedFileDelimiter
				,@OutputL1CuratedFileFormat
				,@OutputL1CuratedFileWriteMode
				,@OutputDWStagingTable
				,@LookupColumns
				,@OutputDWTable
				,@OutputDWTableWriteMode
				,0
				,1
				,@IngestCount
				,@IngestADFPipelineRunID
				,SUSER_SNAME()
				,@localdate
		)
	END
	ELSE
	BEGIN
		--If this is an existing Transformation, just update one record in case there are duplicates
		IF @InputRawFile IS NOT NULL
		BEGIN
			--File-based input path
			UPDATE TOP (1) [ELT].[L1TransformInstance]
			SET 
				[IngestCount] = null
				,[L1TransformInsertCount] = null
				,[L1TransformUpdateCount] = null
				,[L1TransformDeleteCount] = null
				,L1TransformStartTimestamp = null
				,[L1TransformEndTimestamp] = null
				,[L1TransformStatus] = null
				,[RetryCount] = 0
				,[ActiveFlag] = 1
				,[ReRunL1TransformFlag] = 1
				,[IngestADFPipelineRunID] = @IngestADFPipelineRunID
				,[L1TransformADFPipelineRunID] = null
				,[ModifiedBy] = suser_sname()
				,[ModifiedTimestamp] = @localdate
				
		WHERE 
			[IngestID] = @IngestID
			AND L1TransformID = @L1TransformID
			AND (InputRawFileSystem = @InputRawFileSystem OR (InputRawFileSystem IS NULL AND @InputRawFileSystem IS NULL))
			AND (InputRawFileFolder = @InputRawFileFolder OR (InputRawFileFolder IS NULL AND @InputRawFileFolder IS NULL))
			AND (InputRawFile = @InputRawFile OR (InputRawFile IS NULL AND @InputRawFile IS NULL))
			AND (InputRawTable = @InputRawTable OR (InputRawTable IS NULL AND @InputRawTable IS NULL))
			AND (DataFromTimestamp = @DataFromTimestamp OR (DataFromTimestamp IS NULL AND @DataFromTimestamp IS NULL))
			AND (DataToTimestamp = @DataToTimestamp OR (DataToTimestamp IS NULL AND @DataToTimestamp IS NULL))
		END
	END
END

GO

