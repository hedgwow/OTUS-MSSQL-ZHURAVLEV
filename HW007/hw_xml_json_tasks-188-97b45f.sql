/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/
DECLARE @OpenXMLDoc XML

SELECT @OpenXMLDoc = BulkColumn
FROM OPENROWSET
(BULK 'E:\OTUS\OTUS-MSSQL-ZHURAVLEV\HW007\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

DECLARE @OpenXMLDocHandle int
EXEC sp_xml_preparedocument @OpenXMLDocHandle OUTPUT, @OpenXMLDoc

MERGE [Warehouse].[StockItems]
USING (
	SELECT *
	FROM OPENXML(@OpenXMLDocHandle, N'/StockItems/Item')
	WITH ( 
		[StockItemName] NVARCHAR(100) '@Name',
		[SupplierID] int 'SupplierID', 
		[UnitPackageID] int 'Package/UnitPackageID',
		[OuterPackageID] int 'Package/OuterPackageID', 
		[QuantityPerOuter] int 'Package/QuantityPerOuter',
		[TypicalWeightPerUnit] DECIMAL(18, 2) 'Package/TypicalWeightPerUnit',
		[LeadTimeDays] int 'LeadTimeDays',
		[IsChillerStock] bit 'IsChillerStock',
		[TaxRate] DECIMAL(18, 3) 'TaxRate',
		[UnitPrice] DECIMAL(18, 2) 'UnitPrice')
) AS StockItemsXML (
		[StockItemName],
		[SupplierID],
		[UnitPackageID],
		[OuterPackageID],
		[QuantityPerOuter],
		[TypicalWeightPerUnit],
		[LeadTimeDays],
		[IsChillerStock],
		[TaxRate],
		[UnitPrice]) ON StockItems.StockItemName = StockItemsXML.StockItemName	
WHEN MATCHED THEN
	UPDATE SET 		
		[StockItemName] = [StockItemsXML].[StockItemName],
		[SupplierID] = [StockItemsXML].[SupplierID],
		[UnitPackageID] = [StockItemsXML].[UnitPackageID],
		[OuterPackageID] = [StockItemsXML].[OuterPackageID],
		[QuantityPerOuter] = [StockItemsXML].[QuantityPerOuter],
		[TypicalWeightPerUnit] = [StockItemsXML].[TypicalWeightPerUnit],
		[LeadTimeDays] = [StockItemsXML].[LeadTimeDays],
		[IsChillerStock] = [StockItemsXML].[IsChillerStock],
		[TaxRate] = [StockItemsXML].[TaxRate],
		[UnitPrice] = [StockItemsXML].[UnitPrice],
		[LastEditedBy] = 9
WHEN NOT MATCHED THEN
	INSERT (
		[StockItemName],
		[SupplierID],
		[UnitPackageID],
		[OuterPackageID],
		[QuantityPerOuter],
		[TypicalWeightPerUnit],
		[LeadTimeDays],
		[IsChillerStock],
		[TaxRate],
		[UnitPrice],
		[LastEditedBy]
	)
	VALUES (
		[StockItemsXML].[StockItemName],
		[StockItemsXML].[SupplierID],
		[StockItemsXML].[UnitPackageID],
		[StockItemsXML].[OuterPackageID],
		[StockItemsXML].[QuantityPerOuter],
		[StockItemsXML].[TypicalWeightPerUnit],
		[StockItemsXML].[LeadTimeDays],
		[StockItemsXML].[IsChillerStock],
		[StockItemsXML].[TaxRate],
		[StockItemsXML].[UnitPrice],
		9
	);


	-------------

DECLARE @XQueryXMLDoc XML

SELECT @XQueryXMLDoc = BulkColumn
FROM OPENROWSET
(BULK 'E:\OTUS\OTUS-MSSQL-ZHURAVLEV\HW007\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

MERGE [Warehouse].[StockItems]
USING (
	SELECT 
		D.Item.value('@Name[1]','NVARCHAR(100)') [StockItemName],
		D.Item.value('SupplierID[1]', 'int') [SupplierID], 
		D.Item.value('Package[1]/UnitPackageID[1]','int') [UnitPackageID],
		D.Item.value('Package[1]/OuterPackageID[1]','int') [OuterPackageID], 
		D.Item.value('Package[1]/QuantityPerOuter[1]','int') [QuantityPerOuter],
		D.Item.value('Package[1]/TypicalWeightPerUnit[1]','DECIMAL(18, 2)') [TypicalWeightPerUnit],
		D.Item.value('LeadTimeDays[1]','int') [LeadTimeDays],
		D.Item.value('IsChillerStock[1]','bit') [IsChillerStock],
		D.Item.value('TaxRate[1]','DECIMAL(18, 3)') [TaxRate],
		D.Item.value('UnitPrice[1]','DECIMAL(18, 2)') [UnitPrice]
	FROM @XQueryXMLDoc.nodes('/StockItems/Item') AS D(Item)		
) AS StockItemsXML (
		[StockItemName],
		[SupplierID],
		[UnitPackageID],
		[OuterPackageID],
		[QuantityPerOuter],
		[TypicalWeightPerUnit],
		[LeadTimeDays],
		[IsChillerStock],
		[TaxRate],
		[UnitPrice]) ON StockItems.StockItemName = StockItemsXML.StockItemName	
WHEN MATCHED THEN
	UPDATE SET 		
		[StockItemName] = [StockItemsXML].[StockItemName],
		[SupplierID] = [StockItemsXML].[SupplierID],
		[UnitPackageID] = [StockItemsXML].[UnitPackageID],
		[OuterPackageID] = [StockItemsXML].[OuterPackageID],
		[QuantityPerOuter] = [StockItemsXML].[QuantityPerOuter],
		[TypicalWeightPerUnit] = [StockItemsXML].[TypicalWeightPerUnit],
		[LeadTimeDays] = [StockItemsXML].[LeadTimeDays],
		[IsChillerStock] = [StockItemsXML].[IsChillerStock],
		[TaxRate] = [StockItemsXML].[TaxRate],
		[UnitPrice] = [StockItemsXML].[UnitPrice],
		[LastEditedBy] = 9
WHEN NOT MATCHED THEN
	INSERT (
		[StockItemName],
		[SupplierID],
		[UnitPackageID],
		[OuterPackageID],
		[QuantityPerOuter],
		[TypicalWeightPerUnit],
		[LeadTimeDays],
		[IsChillerStock],
		[TaxRate],
		[UnitPrice],
		[LastEditedBy]
	)
	VALUES (
		[StockItemsXML].[StockItemName],
		[StockItemsXML].[SupplierID],
		[StockItemsXML].[UnitPackageID],
		[StockItemsXML].[OuterPackageID],
		[StockItemsXML].[QuantityPerOuter],
		[StockItemsXML].[TypicalWeightPerUnit],
		[StockItemsXML].[LeadTimeDays],
		[StockItemsXML].[IsChillerStock],
		[StockItemsXML].[TaxRate],
		[StockItemsXML].[UnitPrice],
		9
	);	

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

SELECT Item.StockItemName AS [@Name],
		Item.SupplierID AS [SupplierID],
		Item.[UnitPackageID] AS [Package/UnitPackageID],
		Item.[OuterPackageID] AS [Package/OuterPackageID],
		Item.[QuantityPerOuter] AS [Package/QuantityPerOuter],
		Item.[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],
		Item.[LeadTimeDays] AS [LeadTimeDays],
		Item.[IsChillerStock] AS [IsChillerStock],
		Item.[TaxRate] AS [TaxRate],
		Item.[UnitPrice] AS [UnitPrice]
FROM Warehouse.StockItems AS Item
FOR  XML PATH('Item'), ROOT('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT	 
	Item.StockItemID,
	Item.StockItemName,
	J.*
FROM Warehouse.StockItems AS Item
CROSS APPLY (
	SELECT *
	FROM OPENJSON(Item.CustomFields)
	WITH (
		CountryOfManufacture nvarchar(50)	'$.CountryOfManufacture',
		FirstTag nvarchar(200)				'$.Tags[0]'
	)
) AS J;

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT
	StockItemID,
    StockItemName   
FROM Warehouse.StockItems
CROSS APPLY OPENJSON(CustomFields, '$.Tags') AS  tags
WHERE  tags.value = 'Vintage'
