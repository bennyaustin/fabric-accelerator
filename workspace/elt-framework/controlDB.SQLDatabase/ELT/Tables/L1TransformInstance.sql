CREATE TABLE [ELT].[L1TransformInstance] (
    [L1TransformInstanceID]        INT              IDENTITY (1, 1) NOT NULL,
    [L1TransformID]                INT              NOT NULL,
    [IngestInstanceID]             INT              NULL,
    [IngestID]                     INT              NOT NULL,
    [ComputeName]                  VARCHAR (100)    NULL,
    [ComputePath]                  VARCHAR (200)    NULL,
    [CustomParameters]             VARCHAR (MAX)    NULL,
    [InputRawFileSystem]           VARCHAR (50)     NULL,
    [InputRawFileFolder]           VARCHAR (200)    NULL,
    [InputRawFile]                 VARCHAR (200)    NULL,
    [InputRawFileDelimiter]        CHAR (1)         NULL,
    [InputFileHeaderFlag]          BIT              NULL,
    [OutputL1CurateFileSystem]     VARCHAR (50)     NOT NULL,
    [OutputL1CuratedFolder]        VARCHAR (200)    NOT NULL,
    [OutputL1CuratedFile]          VARCHAR (200)    NOT NULL,
    [OutputL1CuratedFileDelimiter] CHAR (1)         NULL,
    [OutputL1CuratedFileFormat]    VARCHAR (10)     NULL,
    [OutputL1CuratedFileWriteMode] VARCHAR (20)     NULL,
    [OutputDWStagingTable]         VARCHAR (200)    NULL,
    [LookupColumns]                VARCHAR (4000)   NULL,
    [OutputDWTable]                VARCHAR (200)    NULL,
    [OutputDWTableWriteMode]       VARCHAR (20)     NULL,
    [IngestCount]                  INT              NULL,
    [L1TransformInsertCount]       INT              NULL,
    [L1TransformUpdateCount]       INT              NULL,
    [L1TransformDeleteCount]       INT              NULL,
    [L1TransformStartTimestamp]    DATETIME         NULL,
    [L1TransformEndTimestamp]      DATETIME         NULL,
    [L1TransformStatus]            VARCHAR (20)     NULL,
    [RetryCount]                   INT              NULL,
    [ActiveFlag]                   BIT              NOT NULL,
    [ReRunL1TransformFlag]         BIT              NULL,
    [IngestADFPipelineRunID]       UNIQUEIDENTIFIER NULL,
    [L1TransformADFPipelineRunID]  UNIQUEIDENTIFIER NULL,
    [CreatedBy]                    NVARCHAR (128)   NOT NULL,
    [CreatedTimestamp]             DATETIME         NOT NULL,
    [ModifiedBy]                   NVARCHAR (128)   NULL,
    [ModifiedTimestamp]            DATETIME         NULL,
    [InputRawTable]                VARCHAR (200)    NULL,
    [DataFromTimestamp]            DATETIME2 (7)    NULL,
    [DataToTimestamp]              DATETIME2 (7)    NULL,
    CONSTRAINT [PK_L1TransformInstance] PRIMARY KEY CLUSTERED ([L1TransformInstanceID] ASC),
    CONSTRAINT [CC_L1TransformInstance_InputSource] CHECK ([InputRawFileSystem] IS NOT NULL AND [InputRawFileFolder] IS NOT NULL AND [InputRawFile] IS NOT NULL AND [InputRawTable] IS NULL OR [InputRawTable] IS NOT NULL AND [InputRawFileSystem] IS NULL AND [InputRawFileFolder] IS NULL AND [InputRawFile] IS NULL),
    CONSTRAINT [CC_L1TransformInstance_L1TransformStatus] CHECK ([L1TransformStatus]='ReRunFailure' OR [L1TransformStatus]='ReRunSuccess' OR [L1TransformStatus]='Running' OR [L1TransformStatus]='DWUpload' OR [L1TransformStatus]='Failure' OR [L1TransformStatus]='Success'),
    CONSTRAINT [CC_L1TransformInstance_OutputDWTableWriteMode] CHECK ([OutputDWTableWriteMode]='append' OR [OutputDWTableWriteMode]='overwrite' OR [OutputDWTableWriteMode]='error' OR [OutputDWTableWriteMode]='errorifexists' OR [OutputDWTableWriteMode]='ignore'),
    CONSTRAINT [CC_L1TransformInstance_OutputL1CuratedFileWriteMode] CHECK ([OutputL1CuratedFileWriteMode]='append' OR [OutputL1CuratedFileWriteMode]='overwrite' OR [OutputL1CuratedFileWriteMode]='ignore' OR [OutputL1CuratedFileWriteMode]='error' OR [OutputL1CuratedFileWriteMode]='errorifexists'),
    CONSTRAINT [FK_L1TransformInstance_IngestID] FOREIGN KEY ([IngestID]) REFERENCES [ELT].[IngestDefinition] ([IngestID]),
    CONSTRAINT [FK_L1TransformInstance_L1TransformID] FOREIGN KEY ([L1TransformID]) REFERENCES [ELT].[L1TransformDefinition] ([L1TransformID])
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_L1TransformInstance]
    ON [ELT].[L1TransformInstance]([InputRawFileSystem] ASC, [InputRawFileFolder] ASC, [InputRawFile] ASC, [InputRawTable] ASC, [DataFromTimestamp] ASC, [DataToTimestamp] ASC, [OutputL1CurateFileSystem] ASC, [OutputL1CuratedFolder] ASC, [OutputL1CuratedFile] ASC, [OutputDWTable] ASC);


GO

