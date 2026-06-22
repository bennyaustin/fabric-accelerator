CREATE TABLE [ELT].[L2TransformDefinition] (
    [L2TransformID]                INT            IDENTITY (1, 1) NOT NULL,
    [IngestID]                     INT            NULL,
    [L1TransformID]                INT            NULL,
    [ComputePath]                  VARCHAR (200)  NULL,
    [ComputeName]                  VARCHAR (100)  NULL,
    [CustomParameters]             VARCHAR (MAX)  NULL,
    [InputType]                    VARCHAR (15)   NULL,
    [InputFileSystem]              VARCHAR (50)   NULL,
    [InputFileFolder]              VARCHAR (200)  NULL,
    [InputFile]                    VARCHAR (200)  NULL,
    [InputFileDelimiter]           CHAR (1)       NULL,
    [InputFileHeaderFlag]          BIT            NULL,
    [InputDWTable]                 VARCHAR (200)  NULL,
    [WatermarkColName]             VARCHAR (50)   NULL,
    [LastDeltaDate]                DATETIME2 (7)  NULL,
    [LastDeltaNumber]              INT            NULL,
    [MaxIntervalMinutes]           INT            NULL,
    [MaxIntervalNumber]            INT            NULL,
    [MaxRetries]                   INT            CONSTRAINT [DC_L2TransformDefinition_MaxRetries] DEFAULT ((3)) NULL,
    [OutputL2CurateFileSystem]     VARCHAR (50)   NULL,
    [OutputL2CuratedFolder]        VARCHAR (200)  NULL,
    [OutputL2CuratedFile]          VARCHAR (200)  NULL,
    [OutputL2CuratedFileDelimiter] CHAR (1)       NULL,
    [OutputL2CuratedFileFormat]    VARCHAR (10)   NULL,
    [OutputL2CuratedFileWriteMode] VARCHAR (20)   NULL,
    [OutputDWStagingTable]         VARCHAR (200)  NULL,
    [LookupColumns]                VARCHAR (4000) NULL,
    [OutputDWTable]                VARCHAR (200)  NULL,
    [OutputDWTableWriteMode]       VARCHAR (20)   NULL,
    [ActiveFlag]                   BIT            NOT NULL,
    [RunSequence]                  INT            CONSTRAINT [DC_L2TransformDefinition_RunSequence] DEFAULT ((100)) NOT NULL,
    [CreatedBy]                    NVARCHAR (128) CONSTRAINT [DC_L2TransformDefinition_CreatedBy] DEFAULT (suser_sname()) NOT NULL,
    [CreatedTimestamp]             DATETIME       CONSTRAINT [DC_L2TransformDefinition_CreatedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NOT NULL,
    [ModifiedBy]                   NVARCHAR (128) CONSTRAINT [DC_L2TransformDefinition_ModifiedBy] DEFAULT (suser_sname()) NULL,
    [ModifiedTimestamp]            DATETIME       CONSTRAINT [DC_L2TransformDefinition_ModifiedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NULL,
    CONSTRAINT [PK_L2TransformDefinition] PRIMARY KEY CLUSTERED ([L2TransformID] ASC),
    CONSTRAINT [CC_L2TransformDefinition_CustomParameters] CHECK (isjson([CustomParameters])=(1)),
    CONSTRAINT [CC_L2TransformDefinition_InputType] CHECK ([InputType]='Raw' OR [InputType]='Curated' OR [InputType]='Datawarehouse'),
    CONSTRAINT [CC_L2TransformDefinition_MaxIntervalMinutes] CHECK ([MaxIntervalMinutes] IS NULL OR [MaxIntervalMinutes]>(0)),
    CONSTRAINT [CC_L2TransformDefinition_MaxIntervalNumber] CHECK ([MaxIntervalNumber] IS NULL OR [MaxIntervalNumber]>(0)),
    CONSTRAINT [CC_L2TransformDefinition_OutputDWTableWriteMode] CHECK ([OutputDWTableWriteMode]='append' OR [OutputDWTableWriteMode]='overwrite' OR [OutputDWTableWriteMode]='ignore' OR [OutputDWTableWriteMode]='error' OR [OutputDWTableWriteMode]='errorifexists'),
    CONSTRAINT [CC_L2TransformDefinition_OutputL2CuratedFileWriteMode] CHECK ([OutputL2CuratedFileWriteMode]='append' OR [OutputL2CuratedFileWriteMode]='overwrite' OR [OutputL2CuratedFileWriteMode]='ignore' OR [OutputL2CuratedFileWriteMode]='error' OR [OutputL2CuratedFileWriteMode]='errorifexists'),
    CONSTRAINT [FK_L2TransformDefinition_IngestID] FOREIGN KEY ([IngestID]) REFERENCES [ELT].[IngestDefinition] ([IngestID])
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_L2TransformDefinition]
    ON [ELT].[L2TransformDefinition]([InputFileSystem] ASC, [InputFileFolder] ASC, [InputFile] ASC, [InputDWTable] ASC, [OutputL2CurateFileSystem] ASC, [OutputL2CuratedFolder] ASC, [OutputL2CuratedFile] ASC, [OutputDWTable] ASC);


GO

