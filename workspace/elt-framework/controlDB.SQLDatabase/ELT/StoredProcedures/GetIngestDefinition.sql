CREATE PROCEDURE [ELT].[GetIngestDefinition]
	@SourceSystemName varchar(20),
	@StreamName VARCHAR(100) = '%', --Default =All Streams
	@MaxIngestInstance INT = 10
	
AS
BEGIN
	
		DECLARE @localdate as datetime	= CONVERT(datetime,CONVERT(datetimeoffset, getdate()) at time zone 'AUS Eastern Standard Time');

with 
	cte
as

(	--Normal Run
			SELECT 
				 [IngestID]
				,[SourceSystemName]
				,[StreamName]
				,[Backend]
				,[EntityName]
				,[WatermarkColName]
				
				--Delta Dates
				,[LastDeltaDate]
				,[DataFromTimestamp] = 
								CASE 
									WHEN ([EntityName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL) THEN [LastDeltaDate]
									ELSE CAST('1900-01-01' AS DateTime)
								END
				,[DataToTimestamp] = 
							CASE 
								WHEN ([EntityName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL AND [MaxIntervalMinutes] IS NOT NULL AND datediff_big(minute,[LastDeltaDate],@localdate) > [MaxIntervalMinutes]) THEN DateAdd(minute,[MaxIntervalMinutes],[LastDeltaDate])
								WHEN ([EntityName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL AND [MaxIntervalMinutes] IS NOT NULL AND datediff_big(minute,[LastDeltaDate],@localdate) <= [MaxIntervalMinutes]) THEN CONVERT(VARCHAR(30),@localdate,120)
								ELSE CONVERT(VARCHAR(30),@localdate,120) 
							END

				--Delta Numbers
				,[LastDeltaNumber]
				,[DataFromNumber] = 
							CASE 
								WHEN ([EntityName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL) THEN [LastDeltaNumber]
					  END
				,[DataToNumber] = 
								CASE 
									WHEN ([EntityName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL) THEN ([LastDeltaNumber] + [MaxIntervalNumber])
					   END

				,[DataFormat]
				,[SourceStructure]
				,[MaxIntervalMinutes]
				,[MaxIntervalNumber]
				,[DataMapping]
				,[RunSequence]
				,[ActiveFlag]
				,[L1TransformationReqdFlag]
				,[L2TransformationReqdFlag]
				,[DelayL1TransformationFlag]
				,[DelayL2TransformationFlag]
				,[DestinationRawFileSystem]
		
			--Derived Fields
				,[DestinationRawFolder] = 
					REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([DestinationRawFolder] COLLATE SQL_Latin1_General_CP1_CS_AS
					,'YYYY',CAST(Year(COALESCE([LastDeltaDate],@localdate)) as varchar(4)))
					,'MM',Right('0'+ CAST(Month(COALESCE([LastDeltaDate],@localdate)) AS varchar(2)),2))
					,'DD',Right('0'+Cast(Day(COALESCE([LastDeltaDate],@localdate)) as varchar(2)),2))
					,'HH',Right('0'+ CAST(DatePart(hh,COALESCE([LastDeltaDate],@localdate)) as varchar(2)),2))
					,'MI',Right('0'+ CAST(DatePart(mi,COALESCE([LastDeltaDate],@localdate)) as varchar(2)),2))
					,'SS',Right('0'+ CAST(DatePart(ss,COALESCE([LastDeltaDate],@localdate)) as varchar(2)),2))
			
				,[DestinationRawFile] = 
					REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([DestinationRawFile] COLLATE SQL_Latin1_General_CP1_CS_AS
					,'YYYY',CAST(Year(COALESCE([LastDeltaDate],@localdate)) AS varchar(4)))
					,'MM',Right('0'+ CAST(Month(COALESCE([LastDeltaDate],@localdate)) AS varchar(2)),2))
					,'DD',Right('0'+Cast(Day(COALESCE([LastDeltaDate],@localdate)) as varchar(2)),2))
					,'HH',Right('0'+ CAST(DatePart(hh,COALESCE([LastDeltaDate],@localdate)) AS varchar(2)),2))
					,'MI',Right('0'+ CAST(DatePart(mi,COALESCE([LastDeltaDate],@localdate)) AS varchar(2)),2))
					,'SS',Right('0'+ CAST(DatePart(ss,COALESCE([LastDeltaDate],@localdate)) AS varchar(2)),2))
				
				,[DestinationRawTable]


			--Query
				,SourceSQL = 
					CASE
					-- Customized for simple Purview ATLAS API
					   WHEN Backend IN ('ATLAS REST API','AZURE REST API') THEN EntityName 

					 --DEFAULT ANSI SQL for Delta Table
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL
							THEN 
								CASE 
									WHEN datediff_big(minute,[LastDeltaDate],@localdate) > [MaxIntervalMinutes]
										THEN 
											'SELECT * FROM ' + [EntityName] + ' WHERE ' 
											+ [WatermarkColName] + ' > ' + ''''+CONVERT(VARCHAR(30),[LastDeltaDate],121) +''''+ ' AND ' + [WatermarkColName] + '<=' +  ''''+ CONVERT(VARCHAR(30), DATEADD(minute,[MaxIntervalMinutes],[LastDeltaDate]),121) +''''
									ELSE 
										'SELECT * FROM ' + [EntityName] + ' WHERE ' 
										+ [WatermarkColName] + ' > ' + ''''+ CONVERT(VARCHAR(30),[LastDeltaDate],121) +''''+ ' AND ' + [WatermarkColName] + '<='  + ''''+ CONVERT(VARCHAR(30), @localdate,120) +''''
								END
					 --DEFAULT ANSI SQL for Full Table
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NULL
							THEN 
								'SELECT * FROM ' + [EntityName]
					--Running Number
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL
							THEN 'SELECT * FROM ' + [EntityName] + ' WHERE ' 
												+ [WatermarkColName] + ' > ' + ''''+CONVERT(VARCHAR,[LastDeltaNumber]) +'''' + [WatermarkColName] + ' <= ' + ''''+CONVERT(VARCHAR,([LastDeltaNumber] + [MaxIntervalNumber])) +''''
						ELSE NULL
					 END
			
			--Stats Query
				,StatSQL = 
					
					CASE 
						-- Customized for simple Purview ATLAS API
					   WHEN Backend IN ('ATLAS REST API','AZURE REST API') THEN EntityName 

						--DEFAULT ANSI SQL For Delta Table
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL
								THEN 
									CASE 
										WHEN datediff_big(minute,[LastDeltaDate],@localdate) > [MaxIntervalMinutes] 
											THEN 
												'SELECT COALESCE(MIN('+[WatermarkColName]+'),'''+CONVERT(varchar(30),LastDeltaDate,121)+''') AS DataFromTimestamp, COALESCE(MAX('+[WatermarkColName]+'),'''+CONVERT(varchar(30), DATEADD(minute,[MaxIntervalMinutes],[LastDeltaDate]),121)+''') AS DataToTimestamp, count(1) as SourceCount FROM ' + [EntityName] + ' WHERE ' 
												+ [WatermarkColName] + ' > ' + ''''+CONVERT(varchar(30),LastDeltaDate,121)+''''+ ' AND ' + [WatermarkColName] + ' <= ' + ''''+CONVERT(varchar(30), DATEADD(minute,[MaxIntervalMinutes],[LastDeltaDate]),121)+''''
										ELSE 
										'SELECT COALESCE(MIN('+[WatermarkColName]+'),'''+CONVERT(varchar(30),[LastDeltaDate],121)+''') AS DataFromTimestamp, COALESCE(MAX('+[WatermarkColName]+'),'''+CONVERT(varchar(30),(@localdate),120)+''') AS DataToTimestamp, count(1) as SourceCount FROM ' + [EntityName] + ' WHERE ' 
											+ [WatermarkColName] + ' > ' + ''''+CONVERT(varchar(30),[LastDeltaDate],121) +''''+ ' AND ' + [WatermarkColName] + ' <= ' + ''''+ CONVERT(varchar(30),(@localdate),120)+''''
										END
						--Common No Delta
							WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NULL
								THEN 'SELECT ''1900-01-01 00:00:00'' AS DataFromTimestamp, '''+CONVERT(VARCHAR(30),ELT.uf_GetAestDateTime(),120)+''' AS DataToTimestamp,  COUNT(*) AS SourceCount FROM ' + [EntityName]
						--Running Number
							WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL
								THEN 'SELECT COALESCE(MIN('+[WatermarkColName]+'),'+CONVERT(VARCHAR,[LastDeltaNumber])+') AS DataFromTimestamp,' + ' COALESCE(MAX('+[WatermarkColName]+'),'+CONVERT(VARCHAR,([LastDeltaNumber] + [MaxIntervalNumber]))+') AS DataToTimestamp,'+ 'COUNT(*) AS SourceCount FROM ' + [EntityName]
													+ [WatermarkColName] + ' > ' + ''''+CONVERT(VARCHAR,[LastDeltaNumber])+'''' + ' AND ' + [WatermarkColName] + ' <= ' + ''''+CONVERT(VARCHAR,([LastDeltaNumber] + [MaxIntervalNumber]))+''''
							ELSE NULL
					 END

				, CAST(0 AS BIT) AS [ReloadFlag]
				, NULL AS [ADFPipelineRunID]
			FROM 
				[ELT].[IngestDefinition]
			WHERE 
				[SourceSystemName]=@SourceSystemName
				AND [StreamName] LIKE COALESCE(@StreamName, [StreamName])
				AND [ActiveFlag]=1

--ReRun
UNION
		SELECT 
				[ID].[IngestID]
				,[SourceSystemName]
				,[StreamName]
				,[Backend]
				,[EntityName]
				,[WatermarkColName]
				,[LastDeltaDate]
				,II.[DataFromTimestamp]
				,II.[DataToTimestamp]
				,ID.[LastDeltaNumber]
				,II.[DataFromNumber]
				,II.[DataToNumber]
				,[DataFormat]
				,[SourceStructure]
				,ID.[MaxIntervalMinutes]
				,ID.[MaxIntervalNumber]
				,ID.[DataMapping]
				,ID.[RunSequence]
				,[ActiveFlag]
				,[L1TransformationReqdFlag]
				,[L2TransformationReqdFlag]
				,[DelayL1TransformationFlag]
				,[DelayL2TransformationFlag]
				,II.[DestinationRawFileSystem]
				,II.[DestinationRawFolder]
				,II.[DestinationRawFile] 	
				,II.[DestinationRawTable]
			
				--Derived Fields
				,SourceSQL = 
					CASE
						-- Customized for simple Purview ATLAS API
					    WHEN Backend IN ('ATLAS REST API','AZURE REST API') THEN EntityName 
						--DEFAULT ANSI SQL for Delta Table
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL 
							THEN 'SELECT * FROM ' + [EntityName] + ' WHERE ' 
									+ [WatermarkColName] + ' > ' + ''''+ CONVERT(varchar(30),II.[DataFromTimestamp],121)+''''+ ' AND ' + [WatermarkColName] + ' <= ' + ''''+ CONVERT(varchar(30),II.[DataToTimestamp],121)+''''
						--Common No Delta
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NULL
							THEN 'SELECT * FROM ' + [EntityName]
						--Running Number
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL
								THEN 'SELECT * FROM ' + [EntityName] + ' WHERE ' 
												+ [WatermarkColName] + ' > ' + ''''+CONVERT(VARCHAR,II.[DataFromNumber])+'''' + ' AND ' + [WatermarkColName] + ' <= ' + ''''+CONVERT(VARCHAR,II.[DataToNumber])+''''
						
						ELSE NULL
					END

				,StatSQL = 
					CASE 
					-- Customized for simple Purview ATLAS API
					   WHEN Backend IN ('ATLAS REST API','AZURE REST API') THEN EntityName 

					--DEFAULT ANSI SQL for Delta Table
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaDate] IS NOT NULL THEN
				'SELECT COALESCE(MIN('+[WatermarkColName]+'),'''+CONVERT(varchar(30),II.DataFromTimestamp,121)+''') AS DataFromTimestamp, COALESCE(MAX('+[WatermarkColName]+'),'''+CONVERT(varchar(30),II.[DataToTimestamp],121)+''') AS DataToTimestamp, count(1) as SourceCount FROM ' 
									+ [EntityName] + ' WHERE ' + [WatermarkColName] + '>' + ''''+CONVERT(varchar(30),II.DataFromTimestamp,121)+''''+ ' AND ' + [WatermarkColName] + '<='+ ''''+CONVERT(varchar(30),II.[DataToTimestamp],121)+''''
					--Common No Delta
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NULL AND [LastDeltaDate] IS NOT NULL 
							THEN 'SELECT MIN('+[WatermarkColName]+') AS DataFromTimestamp,' + ' MAX('+[WatermarkColName]+') AS DataToTimestamp,'+ 'COUNT(*) AS SourceCount FROM ' + [EntityName]
					--Common No Delta
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NULL
							THEN 'SELECT SELECT ''1900-01-01 00:00:00'' AS DataFromTimestamp, '''+CONVERT(VARCHAR(30),ELT.uf_GetAestDateTime(),120)+''' AS DataToTimestamp, COUNT(*) AS SourceCount FROM ' + [EntityName]
					--Running Number
						WHEN [EntityName] IS NOT NULL AND [WatermarkColName] IS NOT NULL AND [LastDeltaNumber] IS NOT NULL
							THEN 'SELECT COALESCE(MIN('+[WatermarkColName]+'),'+CONVERT(VARCHAR,II.[DataFromNumber])+') AS DataFromTimestamp,' + ' COALESCE(MAX('+[WatermarkColName]+'),'+CONVERT(VARCHAR,II.[DataToNumber])+') AS DataToTimestamp,'+ 'COUNT(*) AS SourceCount FROM ' + [EntityName]
					END
				, II.[ReloadFlag]
				, II.[ADFIngestPipelineRunID]
			FROM 
				[ELT].[IngestDefinition] ID
					INNER JOIN [ELT].[IngestInstance] AS II
						ON II.[IngestID]= ID.[IngestID] 
						AND II.[ReloadFlag]=1
						AND (II.[IngestStatus] is NULL OR II.[IngestStatus] != 'Running')  --Fetch new instances and ignore instances that are currently running
			WHERE 
				ID.[SourceSystemName]=@SourceSystemName
				AND ID.[StreamName] LIKE COALESCE(@StreamName, [StreamName])
				AND ID.[ActiveFlag]=1 
				AND ISNULL(II.RetryCount,0) <= ID.MaxRetries
				
	)
	SELECT 
		TOP (@MaxIngestInstance) *  
	FROM CTE
	ORDER BY 
		[RunSequence] ASC, [DataFromTimestamp] DESC, [DataToTimestamp] DESC

END

GO

