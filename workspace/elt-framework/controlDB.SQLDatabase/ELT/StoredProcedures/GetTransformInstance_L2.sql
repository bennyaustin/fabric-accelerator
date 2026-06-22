CREATE PROCEDURE [ELT].[GetTransformInstance_L2]
	@SourceSystemName varchar(20),
	@StreamName varchar(100) = '%',
	@MaxTransformInstance int = 10,
	@L2TransformInstanceId INT = NULL, --To fetch all transform instances set Parameter as NULL otherwise provide a specific instance id
	@DelayL2TransformationFlag INT= NULL, --Pass @DelayL2TransformationFlag=0 to fetch all instances that needs to be transformed in the current pipeline (usually the ingestion pipeline). Pass =1 to fetch @DelayL2TransformationFlagh all transformations that are scheduled for a later time.
	@InputType varchar(15)	= '%',
	@L2TransformID INT=NULL --To Fetch all transformations for a specific stream pass NULL otherwise provide TransformId prersent in L2Transsformdefinition
AS
begin
	--Limit Number of Transform Instances to prevent queuing at DWH
		SELECT TOP 
			(@MaxTransformInstance) 
			L2TI.[L2TransformInstanceID]
			, L2TI.[L2TransformID]
			, L2TI.[IngestID]
			, L2TI.[L1TransformID]
			, L2TI.[ComputePath]
			, L2TI.[ComputeName]
			, L2TI.[CustomParameters]
			, L2TD.[InputType]
			, L2TI.[InputFileSystem]
			, L2TI.[InputFileFolder]
			, L2TI.[InputFile]
			, L2TI.[InputFileDelimiter]
			, L2TI.[InputFileHeaderFlag]
			, L2TI.[InputDWTable]
			, L2TI.[WatermarkColName]
			, L2TI.[DataFromTimestamp]
			, L2TI.[DataToTimestamp]
			, L2TI.[DataFromNumber]
			, L2TI.[DataToNumber]
			, L2TI.[OutputL2CurateFileSystem]
			, L2TI.[OutputL2CuratedFolder]
			, L2TI.[OutputL2CuratedFile]
			, L2TI.[OutputL2CuratedFileDelimiter]
			, L2TI.[OutputL2CuratedFileFormat]
			, L2TI.[OutputL2CuratedFileWriteMode]
			, L2TI.[OutputDWStagingTable]
			, L2TI.[LookupColumns]
			, L2TI.[OutputDWTable]
			, L2TI.[OutputDWTableWriteMode]
			, L2TI.[ReRunL2TransformFlag]
			, L2TD.[MaxRetries]
	
		FROM 
			[ELT].[L2TransformInstance] as L2TI
				LEFT JOIN [ELT].[L2TransformDefinition] as L2TD
					ON L2TI.[L2TransformID] = L2TD.[L2TransformID]
				LEFT JOIN [ELT].[IngestDefinition] as ID
					ON id.[IngestID]= L2TD.[IngestID]			
			WHERE 
				ID.[SourceSystemName] =@SourceSystemName
				AND ID.[StreamName] like COALESCE(@StreamName,id.[StreamName])
				AND (ID.ActiveFlag = 1 AND L2TD.ActiveFlag = 1)
				AND (L2TI.[ActiveFlag]=1 OR L2TI.[ReRunL2TransformFlag]=1)
				AND L2TI.[L2TransformInstanceID] = COALESCE(@L2TransformInstanceId, L2TI.[L2TransformInstanceID])
				AND (L2TI.[L2TransformStatus] IS NULL OR L2TI.[L2TransformStatus] NOT IN ('Running','DWUpload'))  --Fetch new instances and ignore instances that are currently running
			    AND ID.[DelayL2TransformationFlag] = COALESCE(@DelayL2TransformationFlag,ID.[DelayL2TransformationFlag])
				AND ISNULL(L2TI.RetryCount,0) <= L2TD.MaxRetries
				AND L2TD.[InputType] like COALESCE(@InputType,L2TD.[InputType])				
				AND  L2TI.[L2TransformID] = COALESCE(@L2TransformID,L2TI.[L2TransformID])
			ORDER BY L2TD.RunSequence ASC, L2TI.[L2TransformInstanceID] ASC
END

GO

