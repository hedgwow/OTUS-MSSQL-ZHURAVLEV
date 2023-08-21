/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "03 - Подзапросы, CTE, временные таблицы".
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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT 
	p.PersonID,
	p.FullName
FROM [Application].People AS p
WHERE (IsSalesperson = 1) AND NOT EXISTS (
		SELECT *
		FROM Sales.Invoices AS i
		WHERE ( i.SalespersonPersonID = p.PersonID)
		AND (i.InvoiceDate = '2015-07-04')
		)
/*  */
;WITH SalersCTE AS (
	SELECT
		SalespersonPersonID
	FROM Sales.Invoices
	WHERE InvoiceDate = '2015-07-04')
SELECT 
	p.PersonID,
	p.FullName
FROM [Application].People AS p
WHERE (IsSalesperson = 1) AND (p.PersonID NOT IN (SELECT SalespersonPersonID FROM SalersCTE))

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT 
	si.StockItemID,
	si.StockItemName,
	si.UnitPrice
FROM Warehouse.StockItems AS si
WHERE si.UnitPrice =ANY (SELECT
		MIN(UnitPrice)
	FROM Warehouse.StockItems)

/*  */

;WITH MinPriceCTE (MinPrice) AS (
	SELECT 
		MIN(UnitPrice)
	FROM Warehouse.StockItems )
SELECT 
	si.StockItemID,
	si.StockItemName,
	si.UnitPrice
FROM Warehouse.StockItems AS si
WHERE si.UnitPrice = (SELECT MinPrice FROM MinPriceCTE)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT TOP 5
	sc.CustomerName,
	ct.TransactionAmount

FROM Sales.CustomerTransactions AS ct
	JOIN Sales.Customers AS sc
	ON ct.CustomerID = sc.CustomerID
ORDER BY ct.TransactionAmount DESC

/*  */

;WITH Top5TransactionsCTE AS
(
	SELECT TOP 5 
		ct.CustomerID,
		ct.TransactionAmount
	FROM Sales.CustomerTransactions AS ct
	ORDER BY ct.TransactionAmount DESC
)
SELECT
	sc.CustomerName,
	t.TransactionAmount
FROM Top5TransactionsCTE AS t
	JOIN Sales.Customers AS sc
	ON t.CustomerID = sc.CustomerID

/*  */

SELECT
	sc.CustomerName,
	t.TransactionAmount
FROM Sales.Customers AS sc
	JOIN
	( SELECT TOP 5
		ct.CustomerID,
		ct.TransactionAmount
	FROM Sales.CustomerTransactions AS ct
	ORDER BY ct.TransactionAmount DESC) AS t
	ON sc.CustomerID = t.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT 
	c.CityID,
	c.CityName,
	p.FullName AS PackedByPersonID
FROM [Application].Cities AS c
	JOIN Sales.Customers AS sc
	ON c.CityID = sc.DeliveryCityID
	JOIN Sales.Invoices AS si
	ON sc.CustomerID = si.CustomerID
	JOIN [Application].People AS p
	ON si.PackedByPersonID = p.PersonID
	JOIN Sales.OrderLines AS ol
	ON si.OrderID = ol.OrderID
	JOIN Warehouse.StockItems AS wsi
	ON ol.StockItemID = wsi.StockItemID
WHERE wsi.UnitPrice IN (SELECT TOP 3 UnitPrice FROM Warehouse.StockItems ORDER BY UnitPrice DESC)
ORDER BY PackedByPersonID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
напишите здесь свое решение
