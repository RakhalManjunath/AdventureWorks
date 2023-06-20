--What are the most popular products among customers?


select p.Name,count(s.productID) as product_count
from sales.SalesOrderDetail s
join Production.Product p on s.ProductID = p.ProductID
group by p.Name
order by product_count desc


--Which geographic regions generate the most sales?


select concat(st.name,',',' ',st.CountryRegionCode) region, sum(sd.LineTotal) Total_Sales
from Sales.SalesTerritory as st
join Sales.SalesOrderHeader sh on st.TerritoryID = sh.TerritoryID
join sales.SalesOrderDetail sd on sh.SalesOrderID = sd.SalesOrderID
group by Name,CountryRegionCode
order by 2 desc


--How has sales volume changed over time?
--Total Sales by year

select YEAR(OrderDate) as Year,ROUND(sum(TotalDue),2) as Total_sales
from Sales.SalesOrderHeader
group by year(OrderDate)
order by Year asc

--Total sales by month

select DATENAME(MONTH,OrderDate) as Month,round(sum(TotalDue),2) as Total_sales
from Sales.SalesOrderHeader
group by DATENAME(MONTH,OrderDate)
order by Total_sales desc

--How does customer behavior vary by geographic region?



select 
	concat(st.name,',',' ',st.CountryRegionCode) as region,
	count(distinct(sod.SalesOrderID)) as no_of_orders,
	sum(sod.LineTotal)/1000 as TotalSales_in_mil

from Sales.SalesTerritory st
join Sales.SalesOrderHeader sh  on st.TerritoryID = sh.TerritoryID
join Sales.SalesOrderDetail sod on sh.SalesOrderID = sod.SalesOrderID

group by st.Name,CountryRegionCode
order by no_of_orders,TotalSales_in_mil desc


--Which salespeople are the most successful?


select 
	BusinessEntityID as Sales_Person_Id,
	SalesQuota,
	sum(SalesYTD) as TotalSales_YTD,
	sum(SalesYTD)/SalesQuota as Sales_Quota_Ratio,
	rank() over(order by sum(SalesYTD) desc) as rank
from Sales.SalesPerson
where SalesQuota != 0
group by BusinessEntityID,SalesQuota
order by TotalSales_YTD desc, Sales_Quota_Ratio desc

--What are the most profitable products?
--Top 20

select
	distinct top 20 (Name),
	round((ListPrice-StandardCost)/ListPrice,2) as profit_margin
from Production.Product
where
	Product.DiscontinuedDate is null
	and ListPrice != 0
	and StandardCost != 0
order by profit_margin desc


-- by product category

select 
	distinct(pc.Name) as product_category,
	round((ListPrice-StandardCost)/ListPrice,2)*100 as profit_margin_PCT

from AdventureWorks2022.Production.ProductCategory as pc
join AdventureWorks2022.Production.ProductSubcategory as psc on pc.ProductCategoryID = psc.ProductCategoryID
join AdventureWorks2022.Production.Product as p on psc.ProductSubcategoryID = p.ProductSubcategoryID
where 
	DiscontinuedDate is null
	and ListPrice != 0
	and StandardCost != 0
order by profit_margin_PCT desc


-- How does product popularity by geographic region?

select grouped_region,product_name, product_count, rank 
from
	(select 
		st.[Group] as grouped_region,
		p.Name as product_name,
		count(sod.ProductID) as product_count,
		rank() over(partition by st.[Group] order by  count(sod.ProductID) desc ) as Rank
	from Sales.SalesTerritory as st
	join Sales.SalesOrderHeader as soh  on st.TerritoryID=soh.TerritoryID
	join Sales.SalesOrderDetail as sod on soh.SalesOrderID=sod.SalesOrderID
	join Production.Product as p on sod.ProductID=p.ProductID
	group by st.[Group], p.Name) as sub
where rank=1


--Which suppliers are the most reliable?

with sub1 as
(select 
	BusinessEntityID,Name,
	count(case when ph.ShipDate <= pd.DueDate then 1 end) as on_time_del_count,
	count(case when RejectedQty > 0 then 1 end ) as rejection_count
from Purchasing.PurchaseOrderDetail as pd
join Purchasing.PurchaseOrderHeader as ph on pd.PurchaseOrderID=ph.PurchaseOrderID
join Purchasing.Vendor as v on ph.VendorID=v.BusinessEntityID
group by BusinessEntityID,Name),

Total_Supplies_Made as
(select 
	BusinessEntityID,
	Name, 
	count(pd.ProductID) as Total_Supplies_Count
from Purchasing.PurchaseOrderDetail as pd
join Purchasing.PurchaseOrderHeader ph  on pd.PurchaseOrderID = ph.PurchaseOrderID
join Purchasing.Vendor v  on ph.VendorID = v.BusinessEntityID
group by BusinessEntityID,Name)



select 
	s.Name, 
	round((on_time_del_count/tsm.Total_Supplies_Count),2) as on_time_delivery_PCT,
	round((rejection_count/tsm.Total_Supplies_Count),2) as rejection_PCT
from sub1 as s
join Total_Supplies_Made as tsm on s.BusinessEntityID = tsm.BusinessEntityID
order by on_time_delivery_PCT


--How does supplier performance vary by product category?


select 
	pc.Name as Category_Name, 
	v.Name as Vendor_Name,
	--round(count(case when(pd.RejectedQty > 0 then 1 end)/count(*),2) as Rejection_rate
	round(count(case when pd.RejectedQty > 0 then 1 end)/count(*),2) as Rejection_Rate
from Purchasing.PurchaseOrderDetail as pd
join Production.Product p on pd.ProductID = p.ProductID
join Production.ProductSubcategory as psc on p.ProductSubcategoryID = psc.ProductSubcategoryID
join Production.ProductCategory as pc on psc.ProductCategoryID = pc.ProductCategoryID
join Purchasing.PurchaseOrderHeader poh on pd.PurchaseOrderID = poh.PurchaseOrderID
join Purchasing.Vendor v on poh.VendorID = v.BusinessEntityID
group by pc.Name,v.Name
order by Category_Name,Rejection_Rate


--Are there any correlations between supplier characteristics and performance?

select
	v.Name,
	v.CreditRating,
	v.PreferredVendorStatus,
	v.ActiveFlag,
	round(count(case when pd.RejectedQty > 0 then 1 end)/count(*),2) as Return_Rate,
	count(case when ph.ShipDate<=pd.DueDate then 1 end)/count(*) as Delivery_on_time_rate
from Purchasing.Vendor as v
join Purchasing.PurchaseOrderHeader ph on v.BusinessEntityID = ph.VendorID
join Purchasing.PurchaseOrderDetail pd on ph.PurchaseOrderID = pd.PurchaseOrderID
group by v.CreditRating,v.PreferredVendorStatus,v.ActiveFlag,v.Name
order by Return_Rate desc, Delivery_on_time_rate desc



--Which products have the longest production times?

with cte as 
(select 
	distinct (p.name) as Product_name,
	wo.StartDate,
	wo.EndDate,
	wo.DueDate,
	(wo.DueDate - wo.StartDate) as Actual_Production_time,
	case 
	when wo.EndDate<=wo.StartDate then 'On Time'
	else 'Delayed'
	end as Status
from Production.WorkOrder as wo
join Production.Product as p on wo.ProductID = p.ProductID)
--order by p.name,Actual_Production_time desc)

select distinct Product_name, Actual_Production_time
from cte
order by Product_name,Actual_Production_time desc



