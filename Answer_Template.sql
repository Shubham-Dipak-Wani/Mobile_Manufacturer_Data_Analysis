--SQL Advance Case Study
select * from DIM_CUSTOMER
select * from DIM_DATE
select * from DIM_LOCATION
select * from DIM_MANUFACTURER
select * from DIM_MODEL
select * from FACT_TRANSACTIONS

--Q1--BEGIN 

-- List all the states in which we have customers who have bought cellphones from 2005 till today.
select Distinct[State] 
from fact_transactions as f
inner join
dim_location as l
on f.IDLocation = l.IDLocation
where Year(f.date) between 2005 and 
      Year(getdate())

--Q1--END


--Q2--BEGIN

--What state in the US is buying the most 'Samsung' cell phones? 
select top 1 [State], sum(quantity) as Quantity_No
from fact_transactions as f
inner join
dim_location as l
on f.IDLocation = l.IDLocation
inner join
dim_model as M
on f.IDModel = m.IDModel
inner join 
dim_manufacturer as mf
on mf.IDManufacturer = m.IDManufacturer
where  l.Country = 'US' and  mf.Manufacturer_Name = 'Samsung'
group by [State]
order by sum(quantity) desc

--Q2--END


--Q3--BEGIN      

--Show the number of transactions for each model per zip code per state. 
select [State], ZipCode, model_name,
count(f.IDModel) as Number_of_transactions
from fact_transactions as f
inner join
dim_model as m
on f.IDModel = m.IDModel
inner join 
dim_location as l
on l.IDLocation = f.IDLocation
group by [State] , ZipCode, model_name
order by [State]

--Q3--END


--Q4--BEGIN

-- Show the cheapest cellphone (Output should contain the price also)select top 1 f.IDModel , m.Model_Name, a.Manufacturer_Name, Unit_price
from fact_transactions as f
inner join 
dim_model as m
on m.IDModel = f.IDModel
inner join 
dim_manufacturer as a
on a.IDManufacturer = m.IDManufacturer
order by Unit_price asc

--Q4--END


--Q5--BEGIN

--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.
select model_name, manufacturer_name, avg(unit_price) as Average_price
from dim_model as Mo
inner join 
dim_manufacturer as M
on m.IDManufacturer = mo.IDManufacturer
where 
manufacturer_name in (
                          select top 5 manufacturer_name
						  from fact_transactions as f
						  inner join 
						  dim_model as mo
						  on mo.IDModel = f.IDModel
						  inner join
						  dim_manufacturer as M
						  on m.IDManufacturer = mo.IDManufacturer
						  group by Manufacturer_Name
						  order by sum(Quantity) desc,
						           sum(totalprice) desc
						           
					  )
group by model_name, Manufacturer_Name
order by avg(unit_price) desc

--Q5--END


--Q6--BEGIN

--List the names of the customers and the average amount spent in 2009, where the average is higher than 500.
select Customer_Name,
Avg(TotalPrice) as Average_Amount_Spent
from dim_customer as C
inner join
fact_transactions as F
on f.IDCustomer = c.IDCustomer
where Year(F.Date) = 2009
group by Customer_Name
having Avg(TotalPrice) > 500
order by Average_Amount_Spent

--Q6--END
	

--Q7--BEGIN  

--List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010.
select Model_Name
from fact_transactions as F
inner join
dim_model as M
on F.IDModel = M.IDModel
group by f.Date, Model_Name
having Sum(Quantity) >=(select top 5 sum(Quantity) from fact_transactions where Year(F.Date)  = 2008 order by sum(Quantity) desc) and
       Sum(Quantity) >=(select top 5 sum(Quantity) from fact_transactions where Year(F.Date)  = 2009 order by sum(Quantity) desc) and
	   Sum(Quantity) >=(select top 5 sum(Quantity) from fact_transactions where Year(F.Date)  = 2010 order by sum(Quantity) desc)

--Q7--END	


--Q8--BEGIN

--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
select * from
(
select top 1 Manufacturer_name as Manufacturer_name_with_2nd_top_sales_2009 from
(       
         select top 2 Manufacturer_Name,sum(totalprice) as Top_Sales from FACT_TRANSACTIONS as f
         inner join dim_model as MO
         on Mo.IDModel = F.IDModel
         inner join dim_manufacturer as M
         on M.IDManufacturer = Mo.IDManufacturer
         where year(F.date) = 2009
         group by Manufacturer_Name
         order by sum(totalprice) desc
)        as Y
order by Top_Sales asc
)        as table1

cross join

(
select top 1 Manufacturer_name as Manufacturer_name_with_2nd_top_sales_2010 from
(       
         select top 2 Manufacturer_Name,sum(totalprice) as Top_Sales from FACT_TRANSACTIONS as f
         inner join dim_model as MO
         on Mo.IDModel = F.IDModel
         inner join dim_manufacturer as M
         on M.IDManufacturer = Mo.IDManufacturer
         where year(F.date) = 2010
         group by Manufacturer_Name
         order by sum(totalprice) desc
)        as Y
order by Top_Sales asc
)        as table2

--Q8--END


--Q9--BEGIN
	
--Show the manufacturers that sold cellphones in 2010 but did not in 2009.
select Manufacturer_Name, m.IDManufacturer
from fact_transactions as F
inner join
dim_model as Mo
On mo.IDModel = f.IDModel
inner join
dim_manufacturer as M
on M.IDManufacturer = mo.IDManufacturer
where year(date) = 2010 

except

select manufacturer_name, m.IDManufacturer
from fact_transactions as F
inner join
dim_model as Mo
On mo.IDModel = f.IDModel
inner join
dim_manufacturer as M
on M.IDManufacturer = mo.IDManufacturer
where year(date) = 2009

--Q9--END


--Q10--BEGIN
	
-- Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
select Customer_Name , Average_quantity, _Year_, Average_spend, Prev_avg_spend,
case 
    when Prev_avg_spend  = 0 
	then Null
	else ( (Average_spend - Prev_avg_spend)/(Prev_avg_spend) )*100
end as '%YOY change'
from
(
      select customer_name, average_spend,
	  lag(Average_spend,1,0) over (partition by customer_name order by _Year_) as Prev_avg_spend, 
	  average_quantity, _Year_ 
	  from
	  ( 
	  select c.customer_name,
	  avg(f.totalprice) as Average_spend,
      avg(f.Quantity) as average_quantity,
      year(f.date) as _Year_ 
	  from fact_transactions as F
	  left join
	  dim_customer as C
	  on f.IDCustomer = c.IDCustomer
	  where f.IDCustomer in
	   (
          select top 10 IDCustomer
	      from fact_transactions
		  group by IDCustomer
	      order by sum(totalprice) desc
	   )
	   group by Customer_Name, year(f.date)
	   ) as X
) as Y
   
--Q10--END
-----------------------------------------------------------END Of Case Study 2 Mobile Manufacturer---------------------------------------------------------------------------------------------------------------
