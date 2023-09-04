/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

set statistics time, io on
SELECT
	i.InvoiceID,
	c.CustomerName,
	i.InvoiceDate, 
	SUM(il.Quantity*il.UnitPrice) AS InvoiceTotal,
	(
		SELECT  SUM(il1.Quantity*il1.UnitPrice) AS СumulativeTotal
		FROM Sales.Invoices AS i1
		JOIN Sales.InvoiceLines AS il1
		ON il1.InvoiceID = i1.InvoiceID
		WHERE i1.InvoiceDate >= '20150101'
		AND  i1.InvoiceDate < DATEADD(mm,1,DATEADD(mm,DATEDIFF(mm,0,i.InvoiceDate),0))
	)  AS СumulativeTotal
FROM Sales.Invoices AS i
	JOIN Sales.InvoiceLines AS il
	ON il.InvoiceID = i.InvoiceID
	JOIN Sales.Customers AS c
	ON c.CustomerID = i.CustomerID
WHERE i.InvoiceDate >= '20150101'
GROUP BY i.InvoiceID, c.CustomerName, i.InvoiceDate
ORDER BY i.InvoiceID, c.CustomerName, i.InvoiceDate
set statistics time, io off

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

set statistics time, io on
;WITH InvoiseCTE AS
(
	SELECT
		i.InvoiceID,
		c.CustomerName,
		i.InvoiceDate,
		YEAR(i.InvoiceDate) AS InvoiceYear,
		MONTH(i.InvoiceDate) AS InvoiceMonth,
		SUM(il.Quantity*il.UnitPrice) AS InvoiceTotal
	FROM Sales.Invoices AS i
		JOIN Sales.InvoiceLines AS il
		ON il.InvoiceID = i.InvoiceID
		JOIN Sales.Customers AS c
		ON c.CustomerID = i.CustomerID
	WHERE i.InvoiceDate >= '20150101'
	GROUP BY i.InvoiceID, c.CustomerName, i.InvoiceDate, YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
)
SELECT
	InvoiceID,
	CustomerName,
	InvoiceDate,
	InvoiceTotal,
	SUM(InvoiceTotal) OVER (ORDER BY InvoiceYear, InvoiceMonth) AS  СumulativeTotal
FROM InvoiseCTE
ORDER BY InvoiceID, CustomerName, InvoiceDate
set statistics time, io off

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

SELECT
	InvoiceMonth,
	StockItemID,
	TotalS 
	FROM 
	(
		SELECT  
			MONTH(i.InvoiceDate) AS InvoiceMonth,
			il.StockItemID,
			sum(il.Quantity) AS TotalS,
			ROW_NUMBER() OVER (PARTITION BY MONTH(i.InvoiceDate) ORDER BY sum(il.Quantity) DESC) AS StockMaxCount
		FROM Sales.Invoices  AS i
			JOIN Sales.InvoiceLines AS il
			ON il.InvoiceID = i.InvoiceID
		WHERE i.InvoiceDate >= '20150101' AND i.InvoiceDate < '20160101'
		GROUP BY MONTH(i.InvoiceDate), il.StockItemID
	) AS StockMaxTbl
WHERE StockMaxCount <= 2
ORDER BY InvoiceMonth, TotalS DESC

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT	
	i.StockItemID,
	i.StockItemName,
	i.Brand,
	i.UnitPrice,
	ROW_NUMBER() OVER (PARTITION BY LEFT(i.StockItemName, 1) ORDER BY i.StockItemName) AS ABCRank,
	COUNT(*) OVER () AS TotalItemsCount,
	COUNT(*) OVER (PARTITION BY LEFT(i.StockItemName, 1)) AS ABCItemsCount,
	LEAD(StockItemID) OVER (ORDER BY i.StockItemName) AS NextStockItemId,
	LAG(StockItemID) OVER (ORDER BY i.StockItemName) AS PreviousStockItemId,
	LAG(StockItemName, 2, 'No Items') OVER (ORDER BY i.StockItemName) AS PreviousStockItemId,
	NTILE(30) OVER (ORDER BY i.TypicalWeightPerUnit) AS WeightDistributionGroup
FROM Warehouse.StockItems AS i

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT
	PersonID,
	FullName,
	CustomerID,
	CustomerName,
	InvoiceDate,
	InvoiceSum
FROM 
	(
		SELECT 
			p.PersonID,
			p.FullName,
			c.CustomerID,
			c.CustomerName,
			i.InvoiceDate,
			(	SELECT SUM(il.Quantity*il.UnitPrice) AS InvoiceSum
				FROM Sales.InvoiceLines il WHERE il.InvoiceID = i.InvoiceID
			)	AS InvoiceSum,
		ROW_NUMBER() OVER (PARTITION BY p.PersonID ORDER BY i.InvoiceID DESC ) AS InvoiceRank
		FROM  Application.People AS p
			JOIN Sales.Invoices AS i 
			ON  i.SalespersonPersonID = p.PersonID
			JOIN Sales.Customers AS c 
			ON c.CustomerID = i.CustomerID
		WHERE p.isSalesperson = 1
	) AS InvTbl
WHERE InvoiceRank = 1
ORDER BY PersonID

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
SELECT
	CustomerID,
	CustomerName,
	StockItemID,
	UnitPrice,
	InvoiceDate,
	CustInvoiceRank
FROM 
	(
		SELECT 
			c.CustomerID,
			c.CustomerName,
			il.StockItemID,
			il.UnitPrice,
			i.InvoiceDate,
			ROW_NUMBER() OVER (PARTITION BY c.CustomerID ORDER BY il.UnitPrice DESC ) AS CustInvoiceRank
		FROM Sales.Customers AS c
			JOIN Sales.Invoices AS i 
			ON i.CustomerID = c.CustomerID
			JOIN Sales.InvoiceLines AS il 
			ON il.InvoiceID = i.InvoiceID
	) AS CustomerInvoices
WHERE CustInvoiceRank <=2
ORDER BY CustomerID

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 