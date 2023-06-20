
-- MARKET BASKET ANALYSIS

--1. SELECT THE ORDERS HAVING AT LEAST TWO DIFFERENT PRODUCTS

select 
	SalesOrderID,
	count(ProductID) as Number_of_products
from Sales.SalesOrderDetail
group by SalesOrderID
having count(ProductID) >= 2


--2. LIST OUT THE SALESORDERNUMBER AND PRODUCTKEY OF ORDERS HAVING AT LEAST TWO PRODUCT KEYS

select 
	Order_List.SalesOrderID,
	sd.ProductID
from 
(select 
	SalesOrderID,
	count(ProductID) as Number_of_products
from Sales.SalesOrderDetail
group by SalesOrderID
having count(ProductID) >= 2) as Order_List
join Sales.SalesOrderDetail as sd on Order_List.SalesOrderID = sd.SalesOrderID


select 
	sd1.SalesOrderID,
	sd1.ProductID
from Sales.SalesOrderDetail as sd1
inner join Sales.SalesOrderDetail as sd2
on sd1.SalesOrderID = sd2.SalesOrderID
and sd1.ProductID < sd2.ProductID






--3. CREATE COMBINATIONS OF TWO PRODUCTS IN THE SAME ORDER

with info as
(
select 
	Order_List.SalesOrderID,
	sd.ProductID
from 
(select 
	SalesOrderID,
	count(ProductID) as Number_of_products
from Sales.SalesOrderDetail
group by SalesOrderID
having count(ProductID) >= 2) as Order_List
join Sales.SalesOrderDetail as sd on Order_List.SalesOrderID = sd.SalesOrderID)

select 
	info1.SalesOrderID,
	info1.ProductID as Product1,
	info2.ProductID as Product2
from info as info1
join info as info2  on info1.SalesOrderID = info2.SalesOrderID
where info1.ProductID != info2.ProductID
and info1.ProductID < info2.ProductID
order by info1.SalesOrderID


--4. CALCULATE THE FREQUENCY OF A PAIR OF TWO PRODUCTS

with info as
(
select 
	Order_List.SalesOrderID,
	sd.ProductID
from 
(select 
	SalesOrderID,
	count(ProductID) as Number_of_products
from Sales.SalesOrderDetail
group by SalesOrderID
having count(ProductID) >= 2) as Order_List
join Sales.SalesOrderDetail as sd on Order_List.SalesOrderID = sd.SalesOrderID)

select 
	
	info1.ProductID as Product1,
	info2.ProductID as Product2,
	count(*) as Frequency
from info as info1
join info as info2  on info1.SalesOrderID = info2.SalesOrderID
where info1.ProductID != info2.ProductID
and info1.ProductID < info2.ProductID
group by info1.ProductID,info2.ProductID
order by count(*) desc




