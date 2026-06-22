CREATE TABLE [ELT].[IngestInstance] (
    [IngestInstanceID]         INT              IDENTITY (1, 1) NOT NULL,
    [IngestID]                 INT              NOT NULL,
    [SourceFileDropFileSystem] VARCHAR (50)     NULL,
    [SourceFileDropFolder]     VARCHAR (200)    NULL,
    [SourceFileDropFile]       VARCHAR (200)    NULL,
    [DestinationRawFileSystem] VARCHAR (50)     NULL,
    [DestinationRawFolder]     VARCHAR (200)    NULL,
    [DestinationRawFile]       VARCHAR (200)    NULL,
    [DataFromTimestamp]        DATETIME2 (7)    NULL,
    [DataToTimestamp]          DATETIME2 (7)    NULL,
    [DataFromNumber]           INT              NULL,
    [DataToNumber]             INT              NULL,
    [SourceCount]              INT              NULL,
    [IngestCount]              INT              NULL,
    [IngestStartTimestamp]     DATETIME         NULL,
    [IngestEndTimestamp]       DATETIME         NULL,
    [IngestStatus]             VARCHAR (20)     NULL,
    [RetryCount]               INT              NULL,
    [ReloadFlag]               BIT              NULL,
    [CreatedBy]                NVARCHAR (128)   NOT NULL,
    [CreatedTimestamp]         DATETIME         NOT NULL,
    [ModifiedBy]               NVARCHAR (128)   NULL,
    [ModifiedTimestamp]        DATETIME         NULL,
    [ADFIngestPipelineRunID]   UNIQUEIDENTIFIER NULL,
    [DestinationRawTable]      VARCHAR (200)    NULL,
    CONSTRAINT [PK_IngestInstance] PRIMARY KEY CLUSTERED ([IngestInstanceID] ASC),
    CONSTRAINT [CC_IngestInstance_IngestStatus] CHECK ([IngestStatus]='ReRunFailure' OR [IngestStatus]='ReRunSuccess' OR [IngestStatus]='Running' OR [IngestStatus]='Failure' OR [IngestStatus]='Success'),
    CONSTRAINT [FK_IngestInstance_IngestID] FOREIGN KEY ([IngestID]) REFERENCES [ELT].[IngestDefinition] ([IngestID])
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_IngestInstance]
    ON [ELT].[IngestInstance]([DestinationRawFileSystem] ASC, [DestinationRawFolder] ASC, [DestinationRawFile] ASC, [DestinationRawTable] ASC);


GO

