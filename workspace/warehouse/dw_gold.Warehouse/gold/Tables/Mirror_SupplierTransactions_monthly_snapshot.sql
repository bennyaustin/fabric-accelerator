CREATE TABLE [gold].[Mirror_SupplierTransactions_monthly_snapshot] (
    [SupplierID]          INT             NOT NULL,
    [TransactionTypeName] VARCHAR (8000)  NOT NULL,
    [TransactionDate]     DATE            NULL,
    [POAmount]            DECIMAL (38, 2) NULL,
    [TaxAmount]           DECIMAL (38, 2) NULL,
    [POCount]             INT             NULL
);


GO