--1) Create a fact table FactCustomerSales
CREATE TABLE FactCustomerSales (
    FactCustomerSalesID SERIAL PRIMARY KEY,
    DateID INT,
    CustomerID INT,
    TotalAmount DECIMAL(10,2),
    TotalQuantity INT,
    NumberOfTransactions INT,
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID)
);

--Populate the FactCustomerSales table with data
INSERT INTO FactCustomerSales (DateID, CustomerID, TotalAmount, TotalQuantity, NumberOfTransactions)
SELECT
    d.DateID,
    c.CustomerID,
	SUM(od.UnitPrice * od.Qty) AS TotalAmount,
	SUM(od.Qty) AS TotalQuantity,
    COUNT(DISTINCT o.OrderID) AS NumberOfTransactions
FROM
    staging_orders AS o
JOIN
	staging_order_details AS od ON o.OrderID = od.OrderID
JOIN
    DimDate AS d ON d.Date = o.OrderDate
JOIN
    DimCustomer AS c ON c.CustomerID = CAST(o.CustID AS INT)
GROUP BY
    d.DateID,
    c.CustomerID;

--Customer Segmentation Analysis
SELECT 
    c.CustomerID, 
    c.CompanyName,
    CASE
        WHEN SUM(fcs.TotalAmount) > 10000 THEN 'VIP'
        WHEN SUM(fcs.TotalAmount) BETWEEN 5000 AND 10000 THEN 'Premium'
        ELSE 'Standard'
    END AS CustomerSegment
FROM 
    FactCustomerSales fcs
JOIN DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY SUM(fcs.TotalAmount) DESC;

-- Customer Sales Overview
SELECT 
    c.CustomerID, 
    c.CompanyName, 
    SUM(fcs.TotalAmount) AS TotalSpent,
    SUM(fcs.TotalQuantity) AS TotalItemsPurchased,
    SUM(fcs.NumberOfTransactions) AS TransactionCount
FROM 
    FactCustomerSales fcs
JOIN DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY TotalSpent DESC;

-- Top Five Customers by Total Sales
SELECT 
    c.CompanyName,
    SUM(fcs.TotalAmount) AS TotalSpent
FROM 
    FactCustomerSales fcs
JOIN DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY c.CompanyName
ORDER BY TotalSpent DESC
LIMIT 5;

--Customers by Region
SELECT 
    c.Region,
    COUNT(*) AS NumberOfCustomers,
    SUM(fcs.TotalAmount) AS TotalSpentInRegion
FROM 
    FactCustomerSales fcs
JOIN DimCustomer c ON fcs.CustomerID = c.CustomerID
WHERE region IS NOT NULL
GROUP BY c.Region
ORDER BY NumberOfCustomers DESC;