CREATE TABLE [gold].[customertransactions_monthly_snapshot] (
    [TransactionTypeID]   INT             NULL,
    [TransactionTypeName] VARCHAR (8000)  NULL,
    [PaymentMethodID]     INT             NULL,
    [PaymentMethodName]   VARCHAR (8000)  NULL,
    [TransactionMonth]    DATE            NULL,
    [AmountExcludingTax]  DECIMAL (38, 2) NULL,
    [TaxAmount]           DECIMAL (38, 2) NULL,
    [TransactionAmount]   DECIMAL (38, 2) NULL,
    [OutstandingBalance]  DECIMAL (38, 2) NULL
);


GO