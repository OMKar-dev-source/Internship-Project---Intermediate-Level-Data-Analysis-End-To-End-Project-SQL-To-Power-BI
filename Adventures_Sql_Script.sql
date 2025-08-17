Select * from calender_table;
Select * from categories;
Select * from customers;
Select * from products;
Select * from returns;
Select * from sales_combined;
Select * from terriortories;
select * from sub_categories;
use  adventures;
Rename table calender_table to Calender;
Alter table customers change column customerkey Customerkey iNT Not Null PRIMARY KEY;


/* Connected table through foreign and Primary key */

Alter table Sales_Combined Add Constraint foreign key (Customerkey) references customers(customerkey);
Alter table terriotories Add Constraint Primary key (SalesTerritorykey);
Alter table Returns Add constraint foreign key (Territorykey) references Terriotories(SalesTerritorykey);
Alter table products Add constraint Primary key (ProductKey);
Alter table Sales_Combined Add Constraint Foreign key (ProductKey) references products(productkey);
Alter table Categories Add Constraint Primary key (ProductCategorykey);
Alter table sub_categories Add constraint primary key (ProductSubCategorykey);
Alter table sub_categories Add Constraint foreign key (productcategorykey) references categories(productcategorykey);
Alter table products Add Constraint Foreign key (productsubcategorykey) references sub_categories(ProductSubcategorykey);
Alter table returns Add Constraint foreign key (Productkey) references products(productkey);
Alter table sales_combined Add constraint foreign key (Territorykey) references Terriotories(SalesTerritorykey);


                                                    /* Revenue Related Queries */
/* 1. Total Revenue Generated */

Select Sum(Orderquantity * Product_Price) as Revenue
from sales_combined;

/* 2. Top-Selling Products by Revenue */

Select p.ProductName, Sum(p.ProductPrice *sc.orderquantity) as revenue
From products p join sales_combined sc on p.productkey = sc.productkey 
group by p.ProductName 
order by Revenue Desc
limit 5;

/* 3. Top Territories by Sales */

SELECT Continent, TotalRevenue
FROM (
    SELECT t.Continent, SUM(p.ProductPrice * s.OrderQuantity) AS TotalRevenue
    FROM Sales_Combined s
    JOIN Products p ON s.ProductKey = p.ProductKey
    JOIN Terriotories t ON s.TerritoryKey = t.SalesTerritoryKey
    GROUP BY t.Continent
) AS RevenueTable
ORDER BY TotalRevenue DESC;

/* 4. Top 20 Product's Average Revenue and quantity ordered per product */

Select p.productname, Sum(sl.orderquantity) as Totalorders, Avg(Sl.orderquantity * sl.Product_Price) as Revenue
from products p join sales_combined sl on sl.productkey = p.productkey
group by p.productname
order by Revenue desc
limit 20;

/* 5. Top 1 Revenue Generated Country */

Select t.country, Sum(sl.orderquantity * sl.Product_Price) as Revenue
from sales_combined sl join terriotories t on t.SalesTerritorykey = sl.Territorykey
group by t.country 
order by Revenue Desc
limit 1;

/* 6. Average Order Value (AOV) per Sub-category Segment */

SELECT 
sc.subcategoryname,
Avg(sl.orderquantity * sl.product_price) as AvgTotalSpent
FROM Sales_Combined sl
JOIN Products p ON sl.ProductKey = p.ProductKey
join sub_categories sc on sc.productsubcategorykey = p.productsubcategorykey
GROUP BY sc.subcategoryname
ORDER BY AvgTotalSpent DESC;

/* 7. Average Order Value (AOV) per Category Segment */

Select C.CategoryName,
Avg(sl.orderquantity * sl.product_price) as AvgTotal
From sales_combined sl join products p on sl.productkey = p.productkey
join sub_categories s on s.productsubcategorykey = p.productsubcategorykey
join categories c on c.productcategorykey = s.productcategorykey
group by c.categoryname
order by AvgTotal Desc;

/* 8. Countries with most Customers */ 

Select t.Country, Count(Distinct c.Customerkey) AS Customers 
From customers c join sales_combined sl on c.customerkey = sl.customerkey
join terriotories t on sl.territorykey = t.Salesterritorykey 
group by t.country
order by t.country desc;

/* 9. Product Sales Rank Change Between Two Years */

WITH YearRank AS (
SELECT p.ProductName,
YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) AS Year,
SUM(s.OrderQuantity * p.ProductPrice) AS TotalSales,
CAST(RANK() OVER (PARTITION BY YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) 
ORDER BY SUM(s.OrderQuantity * p.ProductPrice) DESC) AS SIGNED) AS RankPos
FROM Sales_Combined s
JOIN Products p ON s.ProductKey = p.ProductKey
GROUP BY p.ProductName, YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')))
SELECT curr.ProductName,
curr.RankPos AS RankCurrent,
prev.RankPos AS RankPrevious,
(CAST(prev.RankPos AS SIGNED) - CAST(curr.RankPos AS SIGNED)) AS RankChange
FROM YearRank curr
JOIN YearRank prev 
ON curr.ProductName = prev.ProductName 
AND prev.Year = 2015 
AND curr.Year = 2016
ORDER BY RankChange DESC;


                                                /* Profit Related queries */

/* 10. Total Profit Generated */

Select Sum((p.productprice - p.productcost) * sc.orderquantity) as Total_Profit
from sales_combined sc join products p on sc.productkey = p.productkey;

/* 11. Categori-wise Profit */

Select c.CategoryName, Sum((p.productprice - p.productcost) * s.orderquantity) as Total_Profit
from sales_combined s join products p on s.productkey = p.productkey 
join sub_categories sc on sc.productsubcategorykey = p.productsubcategorykey
join categories c on c.productcategorykey = sc.productcategorykey
group by c.categoryname 
order by Total_Profit DESC;

/* 12. Sub-Categori-wise Profit */

Select sc.SubcategoryName, Sum((p.productprice - p.productcost) * s.orderquantity) as Total_Profit
from sales_combined s join products p on s.productkey = p.productkey 
join sub_categories sc on sc.productsubcategorykey = p.productsubcategorykey
group by sc.subcategoryname 
order by Total_Profit DESC
limit 5;

/* 13. Year - Wise Profit */

SELECT YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) AS OrderYear,
SUM((p.ProductPrice - p.ProductCost) * s.OrderQuantity) AS TotalProfit
FROM sales_combined s JOIN products p ON s.ProductKey = p.ProductKey
GROUP BY YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y'))
ORDER BY OrderYear;

/* 14. Monthly Profit for Specific Year (e.g., 2015) */

SELECT cal.Month, 
SUM((p.ProductPrice - p.ProductCost) * s.OrderQuantity) AS MonthlyProfit
FROM Sales_Combined s
JOIN Products p ON s.ProductKey = p.ProductKey
JOIN Calender cal ON s.OrderDate = cal.Date
WHERE YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) = 2015
GROUP BY cal.Month
ORDER BY cal.Month;

                                             /* Product Returns Related Query */
                                             
/* 15. Total Amount of Products Returned */

Select Sum(returnquantity * Product_Price) from returns;

/* 16. Total Amount Returned Categoriwise */

Select c.categoryname, Sum(r.returnquantity * Product_Price) as Amount_Returned
from returns r join products p on p.productkey = r.productkey 
join sub_categories sc on sc.productsubcategorykey = p.productsubcategorykey 
join categories c on c.productcategorykey = sc.productcategorykey
group by c.categoryname 
order by Amount_Returned Desc;

/* 17. Total Amount Returned Sub-Categoriwise */

Select sc.SubCategoryName, p.ProductName, sum(r.returnquantity * r.product_price) as Amount_Returned, Sum(r.returnquantity) as ReturnedQuantity
from returns r join products p on r.productkey = p.productkey 
join sub_categories sc on p.productsubcategorykey = sc.productsubcategorykey
group by sc.subcategoryname,p.productname
order by Amount_Returned desc;

/* 18. The products that were buyed but not Returned at all */

SELECT DISTINCT p.ProductName
FROM Products p
JOIN Sales_Combined s ON p.ProductKey = s.ProductKey
WHERE s.productkey NOT IN (SELECT productkey FROM Returns);

/* 19. Most Returned Products with Quantity */

SELECT p.ProductName,Sum(r.returnQuantity) AS ReturnedQty
FROM Returns r
JOIN Products p ON r.ProductKey = p.ProductKey
GROUP BY p.ProductName
ORDER BY ReturnedQty DESC;


                                        /* Growth or trend Related Queries */

/* 20. Monthly Sales Trend Question: How do sales quantities vary month by month? */

SELECT c.Month,SUM(s.OrderQuantity) AS TotalOrders
FROM sales_combined s JOIN calender c ON s.OrderDate = c.Date
WHERE YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) = 2015
GROUP BY c.Month
ORDER BY c.Month;

/* 21. Year-over-Year Sales Growth by Product Category */

WITH YearlySales AS (
SELECT 
cat.CategoryName,
YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) AS Year,
SUM(s.OrderQuantity * p.ProductPrice) AS TotalSales
FROM Sales_Combined s
JOIN Products p ON s.ProductKey = p.ProductKey
JOIN Sub_Categories sc ON p.ProductSubcategoryKey = sc.ProductSubCategoryKey
JOIN Categories cat ON sc.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY cat.CategoryName, YEAR(STR_TO_DATE(s.OrderDate, '%d-%m-%Y'))
)
SELECT 
CategoryName,
Year,
TotalSales,
LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Year) AS PrevYearSales,
ROUND(
(TotalSales - LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Year)) 
/ LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Year) * 100, 2) AS GrowthPercent
FROM YearlySales;

/* 22. Quarter o Quarter Sales Growth by Product Category */

WITH YearlySales AS (
SELECT 
cat.CategoryName,
quarter(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) AS Quarters,
SUM(s.OrderQuantity * p.ProductPrice) AS TotalSales
FROM Sales_Combined s
JOIN Products p ON s.ProductKey = p.ProductKey
JOIN Sub_Categories sc ON p.ProductSubcategoryKey = sc.ProductSubCategoryKey
JOIN Categories cat ON sc.ProductCategoryKey = cat.ProductCategoryKey
GROUP BY cat.CategoryName, Quarter(STR_TO_DATE(s.OrderDate, '%d-%m-%Y'))
)
SELECT 
CategoryName,
Quarters,
TotalSales,
LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Quarters) AS PrevYearSales,
ROUND(
(TotalSales - LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Quarters)) 
/ LAG(TotalSales) OVER (PARTITION BY CategoryName ORDER BY Quarters) * 100, 2) AS GrowthPercent
FROM YearlySales;

/* 23. Top 5 Year-over-Year Sales Growth by Product Sub-Category */

WITH YearlySales AS (
SELECT 
sc.SubcategoryName,
year(STR_TO_DATE(s.OrderDate, '%d-%m-%Y')) AS Year,
SUM(s.OrderQuantity * p.ProductPrice) AS TotalSales
FROM Sales_Combined s
JOIN Products p ON s.ProductKey = p.ProductKey
JOIN Sub_Categories sc ON p.ProductSubcategoryKey = sc.ProductSubCategoryKey
GROUP BY sc.SubcategoryName, Year(STR_TO_DATE(s.OrderDate, '%d-%m-%Y'))
)
SELECT 
SubcategoryName,
Year,
TotalSales,
LAG(TotalSales) OVER (PARTITION BY SubcategoryName ORDER BY Year) AS PrevYearSales,
ROUND(
(TotalSales - LAG(TotalSales) OVER (PARTITION BY SubcategoryName ORDER BY year)) 
/ LAG(TotalSales) OVER (PARTITION BY subcategoryName ORDER BY Year) * 100, 2) AS GrowthPercent
FROM YearlySales
order by growthpercent desc
limit 5;

/* 24. Repeat Customers (More than 1 Purchase) */

SELECT c.Full_Name, COUNT(DISTINCT s.OrderNumber) AS Orders
FROM Customers c
JOIN Sales_Combined s ON c.CustomerKey = s.CustomerKey
GROUP BY c.Full_Name
HAVING COUNT(DISTINCT s.OrderNumber) > 5
ORDER BY Orders DESC;

/* 25. Total Customers from various Countries */

Select t.Country, count( Distinct C.Full_Name) As Total_Customers
from customers c join sales_combined sc on sc.customerkey = c.customerkey
join terriotories t on t.salesterritorykey = sc.territorykey
group by t.country
order by Total_Customers Desc;


                                              /* Orders Related Queries */

/* 26. Total Orders Placed */

Select sum(orderquantity) from sales_combined;

/* 27. Total Orders placed Categoriwise */

Select c.categoryname, Sum(sc.orderquantity) as OrderedQuantity
from sales_combined sc join products p on sc.productkey = p.productkey
join sub_categories sb on sb.productsubcategorykey = p.productsubcategorykey
join categories c on c.productcategorykey = sb.productsubcategorykey
group by c.categoryname 
order by Orderedquantity desc; 

/* 28. Total Orders Placed Sub-Categoriwise */

Select sb.subcategoryname, Sum(sc.orderquantity) as OrderedQuantity
from sales_combined sc join products p on sc.productkey = p.productkey
join sub_categories sb on sb.productsubcategorykey = p.productsubcategorykey
group by sb.subcategoryname 
order by Orderedquantity desc;

/*29. Most ordered product subcategory and Category */

WITH ProductOrders AS (
    SELECT 
        c.CategoryName,
        sc.SubCategoryName,
        p.ProductName,
        SUM(s.OrderQuantity) AS TotalOrders,
        ROW_NUMBER() OVER (
            PARTITION BY c.CategoryName, sc.SubCategoryName 
            ORDER BY SUM(s.OrderQuantity) DESC
        ) AS rn
    FROM sales_combined s
    JOIN products p 
        ON s.ProductKey = p.ProductKey
    JOIN sub_categories sc 
        ON p.ProductSubcategoryKey = sc.ProductSubcategoryKey
    JOIN categories c 
        ON sc.ProductCategoryKey = c.ProductCategoryKey
    GROUP BY c.CategoryName, sc.SubCategoryName, p.ProductName
)
SELECT 
    CategoryName,
    SubCategoryName,
    ProductName,
    TotalOrders
FROM ProductOrders
WHERE rn = 1
ORDER BY CategoryName,SubCategoryName;