CREATE TABLE [gold].[Mirror_Orders_monthly_snapshot] (
    [SalespersonPersonID] INT            NOT NULL,
    [FullName]            VARCHAR (8000) NOT NULL,
    [OrderMonth]          DATE           NULL,
    [OrderCount]          INT            NULL
);


GO