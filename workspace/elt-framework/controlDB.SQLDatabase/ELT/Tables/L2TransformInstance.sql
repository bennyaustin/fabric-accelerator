CREATE TABLE [ELT].[L2TransformInstance] (
    [L2TransformInstanceID]        INT              IDENTITY (1, 1) NOT NULL,
    [L2TransformID]                INT              NULL,
    [IngestID]                     INT              NULL,
    [L1TransformID]                INT              NULL,
    [ComputePath]                  VARCHAR (200)    NULL,
    [ComputeName]                  VARCHAR (100)    NULL,
    [CustomParameters]             VARCHAR (MAX)    NULL,
    [InputFileSystem]              VARCHAR (50)     NULL,
    [InputFileFolder]              VARCHAR (200)    NULL,
    [InputFile]                    VARCHAR (200)    NULL,
    [InputFileDelimiter]           CHAR (1)         NULL,
    [InputFileHeaderFlag]          BIT              NULL,
    [InputDWTable]                 VARCHAR (200)    NULL,
    [WatermarkColName]             VARCHAR (50)     NULL,
    [DataFromTimestamp]            DATETIME2 (7)    NULL,
    [DataToTimestamp]              DATETIME2 (7)    NULL,
    [DataFromNumber]               INT              NULL,
    [DataToNumber]                 INT              NULL,
    [OutputL2CurateFileSystem]     VARCHAR (50)     NULL,
    [OutputL2CuratedFolder]        VARCHAR (200)    NULL,
    [OutputL2CuratedFile]          VARCHAR (200)    NULL,
    [OutputL2CuratedFileDelimiter] CHAR (1)         NULL,
    [OutputL2CuratedFileFormat]    VARCHAR (10)     NULL,
    [OutputL2CuratedFileWriteMode] VARCHAR (20)     NULL,
    [OutputDWStagingTable]         VARCHAR (200)    NULL,
    [LookupColumns]                VARCHAR (4000)   NULL,
    [OutputDWTable]                VARCHAR (200)    NULL,
    [OutputDWTableWriteMode]       VARCHAR (20)     NULL,
    [InputCount]                   INT              NULL,
    [L2TransformInsertCount]       INT              NULL,
    [L2TransformUpdateCount]       INT              NULL,
    [L2TransformDeleteCount]       INT              NULL,
    [L2TransformStartTimestamp]    DATETIME         NULL,
    [L2TransformEndTimestamp]      DATETIME         NULL,
    [L2TransformStatus]            VARCHAR (20)     NULL,
    [RetryCount]                   INT              NULL,
    [ActiveFlag]                   BIT              NOT NULL,
    [ReRunL2TransformFlag]         BIT              NULL,
    [IngestADFPipelineRunID]       UNIQUEIDENTIFIER NULL,
    [L1TransformADFPipelineRunID]  UNIQUEIDENTIFIER NULL,
    [L2TransformADFPipelineRunID]  UNIQUEIDENTIFIER NULL,
    [CreatedBy]                    NVARCHAR (128)   NOT NULL,
    [CreatedTimestamp]             DATETIME         NOT NULL,
    [ModifiedBy]                   NVARCHAR (128)   NULL,
    [ModifiedTimestamp]            DATETIME         NULL,
    [L2SnapshotGroupID]            INT              NULL,
    [L2SnapshotInstanceID]         INT              NULL,
    CONSTRAINT [PK_L2TransformInstance] PRIMARY KEY CLUSTERED ([L2TransformInstanceID] ASC),
    CONSTRAINT [CC_L2TransformInstance_L2TransformStatus] CHECK ([L2TransformStatus]='ReRunFailure' OR [L2TransformStatus]='ReRunSuccess' OR [L2TransformStatus]='Running' OR [L2TransformStatus]='DWUpload' OR [L2TransformStatus]='Failure' OR [L2TransformStatus]='Success'),
    CONSTRAINT [CC_L2TransformInstance_OutputDWTableWriteMode] CHECK ([OutputDWTableWriteMode]='append' OR [OutputDWTableWriteMode]='overwrite' OR [OutputDWTableWriteMode]='ignore' OR [OutputDWTableWriteMode]='error' OR [OutputDWTableWriteMode]='errorifexists'),
    CONSTRAINT [CC_L2TransformInstance_OutputL2CuratedFileWriteMode] CHECK ([OutputL2CuratedFileWriteMode]='append' OR [OutputL2CuratedFileWriteMode]='overwrite' OR [OutputL2CuratedFileWriteMode]='ignore' OR [OutputL2CuratedFileWriteMode]='error' OR [OutputL2CuratedFileWriteMode]='errorifexists'),
    CONSTRAINT [FK_L2TransformInstance_IngestID] FOREIGN KEY ([IngestID]) REFERENCES [ELT].[IngestDefinition] ([IngestID]),
    CONSTRAINT [FK_L2TransformInstance_L1TransformID] FOREIGN KEY ([L1TransformID]) REFERENCES [ELT].[L1TransformDefinition] ([L1TransformID]),
    CONSTRAINT [FK_L2TransformInstance_L2TransformID] FOREIGN KEY ([L2TransformID]) REFERENCES [ELT].[L2TransformDefinition] ([L2TransformID])
);


GO

CREATE NONCLUSTERED INDEX [UI_L2TransformInstance]
    ON [ELT].[L2TransformInstance]([InputFileSystem] ASC, [InputFileFolder] ASC, [InputFile] ASC, [InputDWTable] ASC, [OutputL2CurateFileSystem] ASC, [OutputL2CuratedFolder] ASC, [OutputL2CuratedFile] ASC, [OutputDWTable] ASC);


GO

