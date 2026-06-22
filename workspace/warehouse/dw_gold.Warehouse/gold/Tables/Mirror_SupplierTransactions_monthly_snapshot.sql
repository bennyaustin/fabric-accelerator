CREATE TABLE [gold].[Mirror_SupplierTransactions_monthly_snapshot] (

	[SupplierID] int NOT NULL, 
	[TransactionTypeName] varchar(8000) NOT NULL, 
	[TransactionDate] date NULL, 
	[POAmount] decimal(38,2) NULL, 
	[TaxAmount] decimal(38,2) NULL, 
	[POCount] int NULL
);