CREATE TABLE [gold].[Mirror_CustomerTransactions_monthly_snapshot] (

	[TransactionTypeName] varchar(8000) NOT NULL, 
	[PaymentMethodName] varchar(8000) NOT NULL, 
	[TransactionMonth] date NULL, 
	[AmountExcludingTax] decimal(38,2) NULL, 
	[TaxAmount] decimal(38,2) NULL, 
	[TransactionAmount] decimal(38,2) NULL, 
	[OutstandingBalance] decimal(38,2) NULL
);