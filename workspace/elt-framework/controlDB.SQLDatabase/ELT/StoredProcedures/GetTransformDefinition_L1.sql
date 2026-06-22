CREATE PROCEDURE [ELT].[GetTransformDefinition_L1] 
		@IngestID int, 
		@DeltaDate datetime = null 			
AS
	--declare @IngestID int 
	DECLARE @localdate datetime	= CONVERT(datetime,CONVERT(datetimeoffset, getdate()) AT TIME ZONE 'AUS Eastern Standard Time')
	DECLARE @CuratedDate datetime
	SET @CuratedDate = COALESCE(@DeltaDate,@localdate)


		SELECT 
			--PK/FK
			TD.[L1TransformID]
			, TD.[IngestID]

			
			--Databricks
			, TD.[ComputeName]
			, TD.[ComputePath]
			
			--Custom
			, TD.[CustomParameters]

			 --Raw
			 ,TD.[InputRawFileDelimiter]
			 ,TD.[InputFileHeaderFlag]
			 ,TD.[InputRawTable]
			
			--Curated File
			--Need to test how this performs with a file drop and filedrop reload.
			--Possibly use date drop file was dropped?
			,TD.[OutputL1CurateFileSystem]
			
			,[OutputL1CuratedFolder] = 
					REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TD.[OutputL1CuratedFolder]  COLLATE SQL_Latin1_General_CP1_CS_AS
					,'YYYY',CAST(Year(@CuratedDate) as varchar(4)))
					,'MM',Right('0'+ CAST(Month(@CuratedDate) AS varchar(2)),2))
					,'DD',Right('0'+Cast(Day(@CuratedDate) as varchar(2)),2))
					,'HH',Right('0'+ CAST(DatePart(hh,@CuratedDate) as varchar(2)),2))
					,'MI',Right('0'+ CAST(DatePart(mi,@CuratedDate) as varchar(2)),2))
					,'SS',Right('0'+ CAST(DatePart(ss,@CuratedDate) as varchar(2)),2))

			,[OutputL1CuratedFile] = 
					REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(TD.[OutputL1CuratedFile] COLLATE SQL_Latin1_General_CP1_CS_AS
					,'YYYY',CAST(Year(@CuratedDate) as varchar(4)))
					,'MM',Right('0'+ CAST(Month(@CuratedDate) AS varchar(2)),2))
					,'DD',Right('0'+Cast(Day(@CuratedDate) as varchar(2)),2))
					,'HH',Right('0'+ CAST(DatePart(hh,@CuratedDate) as varchar(2)),2))
					,'MI',Right('0'+ CAST(DatePart(mi,@CuratedDate) as varchar(2)),2))
					,'SS',Right('0'+ CAST(DatePart(ss,@CuratedDate) as varchar(2)),2))

			, TD.[OutputL1CuratedFileDelimiter]
			, TD.[OutputL1CuratedFileFormat]
			, TD.[OutputL1CuratedFileWriteMode]

			--SQL
			, [LookupColumns]
			, TD.[OutputDWStagingTable]
			, TD.[OutputDWTable]
			, TD.[OutputDWTableWriteMode]

			--Max Retries
			, TD.[MaxRetries]
			

		FROM
			[ELT].[L1TransformDefinition] TD
				LEFT JOIN [ELT].[IngestDefinition] ID
					ON TD.[IngestID] = ID.[IngestID]
		WHERE 
			TD.[IngestID] = @IngestID and 
			TD.[ActiveFlag] = 1 
			and ID.[ActiveFlag] = 1 
			and ID.[L1TransformationReqdFlag] =1

GO

