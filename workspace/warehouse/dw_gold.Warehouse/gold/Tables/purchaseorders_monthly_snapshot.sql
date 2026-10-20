CREATE TABLE [gold].[purchaseorders_monthly_snapshot] (
    [SupplierID] INT             NULL,
    [POMonth]    DATE            NULL,
    [POAmount]   DECIMAL (38, 2) NULL,
    [TaxAmount]  DECIMAL (38, 2) NULL,
    [POCount]    INT             NULL
);


GO