--Skip creation and insertion because there is factsales table already

--All tables were created in the first task and aggregate Sales by Month and Category
SELECT d.Month, d.Year, c.CategoryName, SUM(fs.TotalAmount) AS TotalSales
FROM FactSales fs
JOIN DimDate d ON fs.DateID = d.DateID
JOIN DimCategory c ON fs.CategoryID = c.CategoryID
GROUP BY d.Month, d.Year, c.CategoryName
ORDER BY d.Year, d.Month, TotalSales DESC;

-- Top-Selling Products per Quarter
SELECT d.Quarter, d.Year, p.ProductName, SUM(fs.QuantitySold) AS TotalQuantitySold
FROM FactSales fs
JOIN DimDate d ON fs.DateID = d.DateID
JOIN DimProduct p ON fs.ProductID = p.ProductID
GROUP BY d.Quarter, d.Year, p.ProductName
ORDER BY d.Year, d.Quarter, TotalQuantitySold DESC
LIMIT 5;

-- Sales Performance by Employee
SELECT e.FirstName, e.LastName, COUNT(fs.SalesID) AS NumberOfSales, SUM(fs.TotalAmount) AS TotalSales
FROM FactSales fs
JOIN DimEmployee e ON fs.EmployeeID = e.EmployeeID
GROUP BY e.FirstName, e.LastName
ORDER BY TotalSales DESC;


-- Customer Sales Overview
SELECT cu.CompanyName, SUM(fs.TotalAmount) AS TotalSpent, COUNT(DISTINCT fs.SalesID) AS TransactionsCount
FROM FactSales fs
JOIN DimCustomer cu ON fs.CustomerID = cu.CustomerID
GROUP BY cu.CompanyName
ORDER BY TotalSpent DESC;

--Monthly Sales Growth Rate
WITH MonthlySales AS (
    SELECT
        d.Year,
        d.Month,
        SUM(fs.TotalAmount) AS TotalSales
    FROM FactSales fs
    JOIN DimDate d ON fs.DateID = d.DateID
    GROUP BY d.Year, d.Month
),
MonthlyGrowth AS (
    SELECT
        Year,
        Month,
        TotalSales,
        LAG(TotalSales) OVER (ORDER BY Year, Month) AS PreviousMonthSales,
        (TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Month)) / LAG(TotalSales) OVER (ORDER BY Year, Month) AS GrowthRate
    FROM MonthlySales
)
SELECT * FROM MonthlyGrowth;