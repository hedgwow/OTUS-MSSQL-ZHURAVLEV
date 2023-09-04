/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT 
	   InvoiceMonth, 
       ISNULL([Gasport, NY], 0) AS [Gasport, NY],
       ISNULL([Jessie, ND], 0) AS [Jessie, ND],	     
       ISNULL([Medicine Lodge, KS], 0) AS [Medicine Lodge, KS],
       ISNULL([Peeples Valley, AZ], 0) AS [Peeples Valley, AZ],
       ISNULL([Sylvanite, MT], 0) AS [Sylvanite, MT]	   	     
FROM 
	(
		SELECT 
			convert(nvarchar(16), DATEADD(mm,DATEDIFF(mm,0,i.InvoiceDate),0), 104) AS InvoiceMonth,
			SUBSTRING(CustomerName,
			CHARINDEX('(', CustomerName)+1,
			(LEN(CustomerName)-CHARINDEX('(', CustomerName))-1) AS CustomerName,
			COUNT(i.InvoiceID) AS InvoiceCount
		FROM Sales.Invoices AS i 
		JOIN Sales.Customers AS c
		ON c.CustomerID = i.CustomerID
		WHERE c.CustomerID IN (2,3,4,5,6) 
		GROUP BY convert(nvarchar(16), DATEADD(mm,DATEDIFF(mm,0,i.InvoiceDate),0), 104), SUBSTRING(CustomerName, CHARINDEX('(', CustomerName)+1, (LEN(CustomerName)-CHARINDEX('(', CustomerName))-1)
	) AS InvoiceDateName
PIVOT 
(
SUM(InvoiceCount)
FOR CustomerName IN ([Gasport, NY], [Jessie, ND], [Medicine Lodge, KS], [Peeples Valley, AZ], [Sylvanite, MT])
) AS ipvt
ORDER BY InvoiceMonth;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

SELECT 
	CustomerName,
	CustomerAddress
FROM 
	(
		SELECT 
			CustomerName,
			DeliveryAddressLine1,
			DeliveryAddressLine2,
			PostalAddressLine1,
			PostalAddressLine2
		FROM Sales.Customers 
		WHERE CustomerName LIKE '%Tailspin Toys%'
	) AS Customer
UNPIVOT (CustomerAddress FOR Address IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2))
AS UNPVT

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT
	CountryID,
	CountryName,
	Code 
	FROM 
		(
			SELECT 
				c.CountryID,
				c.CountryName,
				c.IsoAlpha3Code,
				CAST(c.IsoNumericCode AS nvarchar(3)) AS   IsoNumericCode
			FROM Application.Countries AS c
		) AS Countries 
UNPIVOT (Code FOR AddressName IN (IsoAlpha3Code, IsoNumericCode))
AS UNPVT

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT
	c.CustomerID,
	c.CustomerName,
	i.StockItemID,
	i.UnitPrice,
	i.InvoiceDate
FROM Sales.Customers AS c 
CROSS APPLY (SELECT TOP 2 
				il.StockItemID,
				il.UnitPrice,
				inv.InvoiceDate
             FROM  Sales.Invoices  AS inv
				JOIN Sales.InvoiceLines AS il
				ON  il.InvoiceID = inv.InvoiceID
			 WHERE inv.CustomerID = c.CustomerID 
			 ORDER BY il.UnitPrice DESC) AS i;
