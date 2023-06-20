--Filter the dataset

drop table if exists rfm;
with dataset as(
	select	
		CustomerID,
		sd.SalesOrderID,
		OrderDate,
		LineTotal
	from Sales.SalesOrderDetail as sd
	full join Sales.SalesOrderHeader as sh on sd.SalesOrderID = sh.SalesOrderID
),

Order_Summary as (
select 
	CustomerID,
	SalesOrderID,
	OrderDate,
	sum(LineTotal) as Total_Sales
from dataset
group by CustomerID,SalesOrderID,OrderDate
),

RFM_Calc as (
select 
	t1.CustomerID,
	--t1.SalesOrderID,
	--t1.OrderDate,
	--(select max(OrderDate) from Order_Summary) as Max_Order_Date,
	--(select max(OrderDate) from Order_Summary where CustomerID = t1.CustomerID) as	Max_Customer_Order_Date,
datediff(day,(select max(OrderDate) from Order_Summary where CustomerID = t1.CustomerID),(select max(OrderDate) from Order_Summary)) as Recency,
count(SalesOrderID) as Frequency,
sum(t1.Total_Sales) as Monetary,
ntile(5) over(order by datediff(day,(select max(OrderDate) from Order_Summary where CustomerID = t1.CustomerID),(select max(OrderDate) from Order_Summary))desc) as R,
ntile(5) over(order by count(SalesOrderID) asc) F,
ntile(5) over(order by sum(t1.Total_Sales) asc) M
from Order_Summary t1
group by t1.CustomerID
--order by 1,3 desc
)

select 
	rc.*,R+F+M as RFM_Cell,
	cast(R as varchar) + cast(F as varchar) + cast(M  as varchar)rfm_cell_string
into rfm
from RFM_Calc as rc

select 
	CustomerID,R,F,M,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (124,125	,133	,134	,135,	142,	143,	145,	152,	153,	224,	225,	234,	235,	242,	243,	244,	245,	252,	253,	254,	255) then 'At risk'
		when rfm_cell_string in (213,221,231,241,251,312,321,331) then 'About to Sleep'
		when rfm_cell_string in (122,123,132,211,212,222,223,231,232,233,241,251,322,332) then 'Hibernating customers'
		when rfm_cell_string in (324,325,334,343,434,443,534,535) then 'Need attention'
		when rfm_cell_string in (445,454,455,544,545,554,555) then 'Champions'
		when rfm_cell_string in (311, 411, 412,421,422,511,512) then 'new customers'
		when rfm_cell_string in (313,314,315,413,414,415,424,425,513,514,515,521,522,523,524,525) then 'promising'
		when rfm_cell_string in (335,344,345,354,355,435,444,543) then 'loyal'
		when rfm_cell_string in (323	,333,	341,	342,	351,	352,	353,	423,	431,	432,	433,	441,	442,	451,	452,	453,	531,	532,	533,	541,	542,	551,	552,	553) then 'potential loyalist'
	end rfm_segment

from rfm
