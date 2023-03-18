/* Cleaning Data using SQL  */

-- Total records = 541909
-- 135080 rows do not have a customer id;

with retail as 
(
	SELECT * 
	FROM [Portfolio Projects].[dbo].[Online Retail]
	where CustomerID is not NULL)
	, quantity_and_price as 
	(
	Select * from retail
	where Quantity > 0 and UnitPrice > 0
	)
-- Duplicate check 
, duplicates as 
(
	Select *, ROW_NUMBER() over (Partition by InvoiceNo,StockCode,Quantity order by InvoiceDate) as flag
	from quantity_and_price
)
	select *
	into #retail_clean_data
	from duplicates
	where flag = 1

-- Removed duplicates and performed data cleaning steps such as eliminating rows where quantity was less than 0 and likewise for the unit price.
-- '#' represents a local temporary table while '##' represents a global temporary table.

Select * from #retail_clean_data 
-- Data ready for cohort analysis with 392,669 rows

-- Cohort Analysis 
-- A cohort is a group of people with something in common
-- Cohort Analysis is an analysis of different cohorts to get a better understanding of behaviours,trends or patterns.
-- Types of Cohort Analysis are : Time-Based, Size-Based, Segment-Based

/* To begin with Cohort Analysis, we need 3 things:
Unique Identifier CustomerID
Cohort Date i.e, First Purchase date of the customer
and Finally the Revenue Data */
 
 -- Extracting the cohort date customer wise
Select CustomerID, MIN(InvoiceDate) as First_Purchase_Date,
DATEFROMPARTS(Year(min(InvoiceDate)),MONTH(min(InvoiceDate)),1) as "Cohort Date"
into #cohort_1
from #retail_clean_data 
group by CustomerID;

-- Creating a Cohort Index 
-- It is an integer representation of the number of the months that has passed since the customers first engagement

Select xyz.*, 
cohort_index = year_diff*12 + month_diff + 1
into #cohort_retention
From(
Select abc.*,
year_diff = Invoice_Year - Cohort_Year,
month_diff = Invoice_Month - Cohort_Month

From
(
Select r.*,c.[Cohort Date],
  YEAR(r.InvoiceDate) as Invoice_Year,
  Month(r.InvoiceDate) as Invoice_Month,
  YEAR(c.[Cohort Date]) as Cohort_Year,
  Month(c.[Cohort Date]) as Cohort_Month
From #retail_clean_data r
left join #cohort_1 c 
	on r.CustomerID = c.CustomerID
) abc
)xyz

Select * from #cohort_retention;


-- Pivoting the data to see the cohort
-- The result shows the cohort analysis table. 

	Select * 
	into #cohort_pivot_data
	from 
	(
	Select distinct CustomerID,cohort_index,[Cohort Date]
	from #cohort_retention
	) cohort
	pivot(
	Count(CustomerID)
	for cohort_index in 
	(	[1],
		[2],
		[3],
		[4],
		[5],
		[6],
		[7],
		[8],
		[9],
		[10],
		[11],
		[12],
		[13]   ) 
	) as pivot_table
	-- order by [Cohort Date]
Select * from #cohort_pivot_data
order by [Cohort Date];


-- Looking at the values as %
	select 
	1.0*[1]/[1] * 100 as [1],
	1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
	from #cohort_pivot_data
	order by [Cohort Date];