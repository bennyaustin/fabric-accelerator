CREATE TABLE [gold].[Mirror_CustomerTransactions_monthly_snapshot] (
    [TransactionTypeName] VARCHAR (8000)  NOT NULL,
    [PaymentMethodName]   VARCHAR (8000)  NOT NULL,
    [TransactionMonth]    DATE            NULL,
    [AmountExcludingTax]  DECIMAL (38, 2) NULL,
    [TaxAmount]           DECIMAL (38, 2) NULL,
    [TransactionAmount]   DECIMAL (38, 2) NULL,
    [OutstandingBalance]  DECIMAL (38, 2) NULL
);


GO