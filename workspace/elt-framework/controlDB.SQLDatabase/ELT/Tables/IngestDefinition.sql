CREATE TABLE [ELT].[IngestDefinition] (
    [IngestID]                  INT            IDENTITY (1, 1) NOT NULL,
    [SourceSystemName]          VARCHAR (50)   NOT NULL,
    [StreamName]                VARCHAR (100)  NULL,
    [SourceSystemDescription]   VARCHAR (200)  NULL,
    [Backend]                   VARCHAR (30)   NULL,
    [DataFormat]                VARCHAR (10)   NULL,
    [EntityName]                VARCHAR (100)  NULL,
    [WatermarkColName]          VARCHAR (50)   NULL,
    [DeltaFormat]               VARCHAR (30)   NULL,
    [LastDeltaDate]             DATETIME2 (7)  NULL,
    [LastDeltaNumber]           INT            NULL,
    [LastDeltaString]           VARCHAR (50)   NULL,
    [MaxIntervalMinutes]        INT            NULL,
    [MaxIntervalNumber]         INT            NULL,
    [DataMapping]               VARCHAR (MAX)  NULL,
    [SourceFileDropFileSystem]  VARCHAR (50)   NULL,
    [SourceFileDropFolder]      VARCHAR (200)  NULL,
    [SourceFileDropFile]        VARCHAR (200)  NULL,
    [SourceFileDelimiter]       CHAR (1)       NULL,
    [SourceFileHeaderFlag]      BIT            NULL,
    [SourceStructure]           VARCHAR (MAX)  NULL,
    [DestinationRawFileSystem]  VARCHAR (50)   NULL,
    [DestinationRawFolder]      VARCHAR (200)  NULL,
    [DestinationRawFile]        VARCHAR (200)  NULL,
    [RunSequence]               INT            CONSTRAINT [DC_IngestDefinition_RunSequence] DEFAULT ((100)) NULL,
    [MaxRetries]                INT            CONSTRAINT [DC_IngestDefinition_MaxRetries] DEFAULT ((3)) NULL,
    [ActiveFlag]                BIT            NOT NULL,
    [L1TransformationReqdFlag]  BIT            NOT NULL,
    [L2TransformationReqdFlag]  BIT            NOT NULL,
    [DelayL1TransformationFlag] BIT            CONSTRAINT [DC_IngestDefinition_DelayL1TransformationFlag] DEFAULT ((1)) NOT NULL,
    [DelayL2TransformationFlag] BIT            CONSTRAINT [DC_IngestDefinition_DelayL2TransformationFlag] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                 NVARCHAR (128) CONSTRAINT [DC_IngestDefinition_CreatedBy] DEFAULT (suser_sname()) NOT NULL,
    [CreatedTimestamp]          DATETIME       CONSTRAINT [DC_IngestDefinition_CreatedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NOT NULL,
    [ModifiedBy]                NVARCHAR (128) CONSTRAINT [DC_IngestDefinition_ModifiedBy] DEFAULT (suser_sname()) NULL,
    [ModifiedTimestamp]         DATETIME       CONSTRAINT [DC_IngestDefinition_ModifiedTimestamp] DEFAULT (CONVERT([datetime],(CONVERT([datetimeoffset],getdate()) AT TIME ZONE 'AUS Eastern Standard Time'))) NULL,
    [DestinationRawTable]       VARCHAR (200)  NULL,
    CONSTRAINT [PK_IngestDefinition] PRIMARY KEY CLUSTERED ([IngestID] ASC),
    CONSTRAINT [CC_IngestDefinition_DataMapping] CHECK (isjson([DataMapping])=(1)),
    CONSTRAINT [CC_IngestDefinition_MaxIntervalMinutes] CHECK ([MaxIntervalMinutes] IS NULL OR [MaxIntervalMinutes]>(0)),
    CONSTRAINT [CC_IngestDefinition_MaxIntervalNumber] CHECK ([MaxIntervalNumber] IS NULL OR [MaxIntervalNumber]>(0)),
    CONSTRAINT [CC_IngestDefinition_SourceStructure] CHECK (isjson([SourceStructure])=(1))
);


GO

CREATE UNIQUE NONCLUSTERED INDEX [UI_IngestDefinition]
    ON [ELT].[IngestDefinition]([SourceSystemName] ASC, [StreamName] ASC);


GO

