CREATE TABLE [ELT].[L1TransformDefinition] (
    [L1TransformID]                INT            IDENTITY (1, 1) NOT NULL,
    [IngestID]                     INT            NOT NULL,
    [ComputePath]                  VARCHAR (200)  NULL,
    [ComputeName]                  VARCHAR (100)  NULL,
    [CustomParameters]             VARCHAR (MAX)  NULL,
    [InputRawFileSystem]           VARCHAR (50)   NULL,
    [InputRawFileFolder]           VARCHAR (200)  NULL,
    [InputRawFile]                 VARCHAR (200)  NULL,
    [InputRawFileDelimiter]        CHAR (1)       NULL,
    [InputFileHeaderFlag]          BIT            NULL,
    [OutputL1CurateFileSystem]     VARCHAR (50)   NOT NULL,
    [OutputL1CuratedFolder]        VARCHAR (200)  NOT NULL,
    [OutputL1CuratedFile]          VARCHAR (200)  NOT NULL,
    [OutputL1CuratedFileDelimiter] CHAR (1)       NULL,
    [OutputL1CuratedFileFormat]    VARCHAR (10)   NULL,
    [OutputL1CuratedFileWriteMode] VARCHAR (20)   NULL,
    [OutputDWStagingTable]         VARCHAR (200)  NULL,
    [LookupColumns]                VARCHAR (4000) NULL,
    [OutputDWTable]                VARCHAR (200)  NULL,
    [OutputDWTableWriteMode]       VARCHAR (20)   NULL,
    [MaxRetries]                   INT            CONSTRAINT [DC_L1TransformDefinition_MaxRetries] DEFAULT ((3)) NULL,
    [WatermarkColName]             VARCHAR (50)   NULL,
    [ActiveFlag]                   BIT            NOT NULL,
    [CreatedBy]                    NVARCHAR (128) CONSTRAINT [DC_L1TransformDefinition_CreatedBy] DEFAULT (suser_sname()) NOT NULL,
    [CreatedTimestamp]             DATETIME       CONSTRAINT [DC_L1TransformDefinition_CreatedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NOT NULL,
    [ModifiedBy]                   NVARCHAR (128) CONSTRAINT [DC_L1TransformDefinition_ModifiedBy] DEFAULT (suser_sname()) NULL,
    [ModifiedTimestamp]            DATETIME       CONSTRAINT [DC_L1TransformDefinition_ModifiedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NULL,
    [InputRawTable]                VARCHAR (200)  NULL,
    CONSTRAINT [PK_L1TransformDefinition] PRIMARY KEY CLUSTERED ([L1TransformID] ASC),
    CONSTRAINT [CC_L1TransformDefinition_CustomParameters] CHECK (isjson([CustomParameters])=(1)),
    CONSTRAINT [CC_L1TransformDefinition_OutputDWTableWriteMode] CHECK ([OutputDWTableWriteMode]='append' OR [OutputDWTableWriteMode]='overwrite' OR [OutputDWTableWriteMode]='error' OR [OutputDWTableWriteMode]='errorifexists' OR [OutputDWTableWriteMode]='ignore'),
    CONSTRAINT [CC_L1TransformDefinition_OutputL1CuratedFileWriteMode] CHECK ([OutputL1CuratedFileWriteMode]='append' OR [OutputL1CuratedFileWriteMode]='overwrite' OR [OutputL1CuratedFileWriteMode]='ignore' OR [OutputL1CuratedFileWriteMode]='error' OR [OutputL1CuratedFileWriteMode]='errorifexists'),
    CONSTRAINT [FK_L1TransformDefinition_IngestID] FOREIGN KEY ([IngestID]) REFERENCES [ELT].[IngestDefinition] ([IngestID])
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_L1TransformDefinition]
    ON [ELT].[L1TransformDefinition]([InputRawFileSystem] ASC, [InputRawFileFolder] ASC, [InputRawFile] ASC, [InputRawTable] ASC, [OutputL1CurateFileSystem] ASC, [OutputL1CuratedFolder] ASC, [OutputL1CuratedFile] ASC, [OutputDWTable] ASC);


GO

