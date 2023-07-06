/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockitemID, StockitemName
FROM  Warehouse.StockItems
WHERE StockitemName LIKE 'Animal%' OR StockitemName LIKE '%urgent%'
ORDER BY StockItemName

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT
	s.SupplierID,
	s.SupplierName
FROM Purchasing.Suppliers AS s
LEFT JOIN Purchasing.PurchaseOrders AS o
	ON o.IsOrderFinalized = s.SupplierID
WHERE o.IsOrderFinalized IS NULL
ORDER BY s.SupplierName

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)


Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
	FORMAT (o.OrderDate, 'dd/MM/yyyy' ) AS OrderDate,
	DATENAME(MONTH, OrderDate) AS OrderMonthName,
	DATENAME(QUARTER, OrderDate) AS OrderQuarter,
	DATEPART(MONTH, OrderDate) AS OrderMonthInt,
	CASE 
		when DATEPART(MONTH, OrderDate) in (1,2,3,4) then 1
		when DATEPART(MONTH, OrderDate) in (5,6,7,8) then 2
		ELSE 3
		END AS ThirdOfTheYear,
	o.OrderID,
	c.CustomerName,
	ol.UnitPrice,
	ol.Quantity
FROM Sales.Orders AS o
LEFT JOIN Sales.Customers AS c
	ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines AS ol 
	ON ol.OrderID = o.OrderID
WHERE 
	( ol.UnitPrice > 100 OR ol.Quantity > 20)
	AND ol.PickingCompletedWhen IS NOT NULL
ORDER BY OrderQuarter, ThirdOfTheYear, OrderDate
/*
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.
*/
SELECT 
	FORMAT (o.OrderDate, 'dd/MM/yyyy' ) AS OrderDate,
	DATENAME(MONTH, OrderDate) AS OrderMonthName,
	DATENAME(QUARTER, OrderDate) AS OrderQuarter,
	DATEPART(MONTH, OrderDate) AS OrderMonthInt,
	CASE 
		when DATEPART(MONTH, OrderDate) in (1,2,3,4) then 1
		when DATEPART(MONTH, OrderDate) in (5,6,7,8) then 2
		ELSE 3
		END AS ThirdOfTheYear,
	o.OrderID,
	c.CustomerName,
	ol.UnitPrice,
	ol.Quantity
FROM Sales.Orders AS o
LEFT JOIN Sales.Customers AS c
	ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines AS ol 
	ON ol.OrderID = o.OrderID
WHERE 
	( ol.UnitPrice > 100 OR ol.Quantity > 20)
	AND ol.PickingCompletedWhen IS NOT NULL
ORDER BY OrderQuarter, ThirdOfTheYear, OrderDate
	offset 1000 rows fetch first 100 rows only
/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
	dm.DeliveryMethodName,
	po.ExpectedDeliveryDate,
	s.SupplierName,
	ppl.FullName AS ContactPerson
FROM Purchasing.Suppliers AS s
	LEFT JOIN Purchasing.PurchaseOrders AS po
	ON s.SupplierID = po.SupplierID
	JOIN Application.DeliveryMethods AS dm
	ON po.DeliveryMethodID = dm.DeliveryMethodID
	JOIN Application.People AS ppl
	ON po.ContactPersonID = ppl.PersonID
WHERE 
	( dm.DeliveryMethodName = 'Air Freight' or dm.DeliveryMethodName = 'Refrigerated Air Freight' )
	AND po.IsOrderFinalized = 1
	AND po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
ORDER BY SupplierName


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 
	si.*,
	c.CustomerName,
	ppl.FullName
FROM 
	Sales.Invoices AS si
	JOIN Sales.Customers AS c
	ON si.CustomerID = c.CustomerID
	JOIN Application.People AS ppl
	ON si.SalespersonPersonID = ppl.PersonID
ORDER BY si.InvoiceID DESC, si.InvoiceDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
	c.CustomerID,
	c.CustomerName,
	c.PhoneNumber
FROM Sales.Orders AS so
	JOIN Sales.OrderLines AS sol
	ON so.OrderID = sol.OrderID
	JOIN Sales.Customers AS c
	ON so.CustomerID = c.CustomerID
WHERE sol.Description LIKE 'Chocolate frogs 250g'
ORDER BY c.CustomerName
