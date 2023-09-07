/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
USE [WideWorldImporters]
GO

INSERT INTO [Sales].[Customers]
           ([CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[PrimaryContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalPostalCode]
           ,[LastEditedBy])
     VALUES
           ('Logitech', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 555-0100', '(308) 555-0101', 'http://www.logitech.com', 'shop1', '90410', 'PO Box 8975', '90410', 1),
		   ('MSI', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 556-0100', '(308) 556-0101', 'http://www.msi.com', 'shop2', '90411', 'PO Box 8976', '90411', 1),
		   ('Lenovo', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 557-0100', '(308) 557-0101', 'http://www.lenovo.com', 'shop3', '90412', 'PO Box 8977', '90412', 1),
		   ('Nvidia', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 558-0100', '(308) 558-0101', 'http://www.nvidia.com', 'shop4', '90413', 'PO Box 8978', '90413', 1),
		   ('Intel', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 559-0100', '(308) 559-0101', 'http://www.intel.com', 'shop5', '90414', 'PO Box 8979', '90414', 1)
GO

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Sales.Customers
WHERE CustomerName = 'Nvidia'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE  Sales.Customers
SET WebsiteURL = 'http://www.AMD.com'
WHERE CustomerName = 'Intel';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

USE [WideWorldImporters]
GO

MERGE Sales.Customers
USING 
	(
	VALUES ('Nvidia', 1, 3, 1001, 3, 19586, 19586, '2013-01-01', 0, 0, 0, 7, '(308) 558-0100', '(308) 558-0101', 'http://www.nvidia.com', 'shop4', '90413', 'PO Box 8978', '90413', 1) 
	) AS newcustom
	(
			[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[PrimaryContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalPostalCode]
           ,[LastEditedBy]
	)
	ON Customers.CustomerName = newcustom.CustomerName
WHEN MATCHED THEN
	UPDATE SET Customers.WebsiteURL = newcustom.WebsiteURL
WHEN NOT MATCHED THEN
	INSERT 
		(
			[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[PrimaryContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalPostalCode]
           ,[LastEditedBy]
		)
		VALUES 
			(
			[CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[PrimaryContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalPostalCode]
           ,[LastEditedBy]
		);

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME --DESKTOP-HU8L8T2

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" out "E:\OTUS\OTUS-MSSQL-ZHURAVLEV\HW008\Customers.txt" -T -w -t,,, -S DESKTOP-HU8L8T2 ' 

CREATE TABLE [Sales].[Customers_BulkCopy](
	[CustomerID] [int] NOT NULL,
	[CustomerName] [nvarchar](100) NOT NULL,
	[BillToCustomerID] [int] NOT NULL,
	[CustomerCategoryID] [int] NOT NULL,
	[BuyingGroupID] [int] NULL,
	[PrimaryContactPersonID] [int] NOT NULL,
	[AlternateContactPersonID] [int] NULL,
	[DeliveryMethodID] [int] NOT NULL,
	[DeliveryCityID] [int] NOT NULL,
	[PostalCityID] [int] NOT NULL,
	[CreditLimit] [decimal](18, 2) NULL,
	[AccountOpenedDate] [date] NOT NULL,
	[StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
	[IsStatementSent] [bit] NOT NULL,
	[IsOnCreditHold] [bit] NOT NULL,
	[PaymentDays] [int] NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[FaxNumber] [nvarchar](20) NOT NULL,
	[DeliveryRun] [nvarchar](5) NULL,
	[RunPosition] [nvarchar](5) NULL,
	[WebsiteURL] [nvarchar](256) NOT NULL,
	[DeliveryAddressLine1] [nvarchar](60) NOT NULL,
	[DeliveryAddressLine2] [nvarchar](60) NULL,
	[DeliveryPostalCode] [nvarchar](10) NOT NULL,
	[DeliveryLocation] [geography] NULL,
	[PostalAddressLine1] [nvarchar](60) NOT NULL,
	[PostalAddressLine2] [nvarchar](60) NULL,
	[PostalPostalCode] [nvarchar](10) NOT NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7),
	[ValidTo] [datetime2](7)
 CONSTRAINT [PK_Sales_Customers_BulkCopy] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [USERDATA],
 CONSTRAINT [UQ_Sales_Customers_CustomerName_BulkCopy] UNIQUE NONCLUSTERED 
(
	[CustomerName] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
) ON [USERDATA]


BULK INSERT [Sales].[Customers_BulkCopy]
				   FROM "E:\OTUS\OTUS-MSSQL-ZHURAVLEV\HW008\Customers.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						ROWTERMINATOR ='\n',
						FIELDTERMINATOR = ',,,',
						KEEPNULLS,
						TABLOCK        
					  );

SELECT Count(*) from [Sales].[Customers_BulkCopy];


TRUNCATE TABLE [Sales].[Customers_BulkCopy];