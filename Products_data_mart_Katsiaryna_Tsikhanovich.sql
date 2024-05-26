--Create a fact table FactProductSales
CREATE TABLE FactProductSales (
    FactSalesID SERIAL PRIMARY KEY,
    DateID INT,
    ProductID INT,
    QuantitySold INT,
    TotalSales DECIMAL(10,2),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);


--Populate the FactProductSales table with data
INSERT INTO FactProductSales (DateID, ProductID, QuantitySold, TotalSales)
SELECT 
    (SELECT DateID FROM DimDate WHERE Date = s.OrderDate) AS DateID,
    p.ProductID, 
    sod.qty, 
    (sod.qty * sod.UnitPrice) AS TotalSales
FROM staging_order_details sod
JOIN staging_orders s ON sod.OrderID = s.OrderID
JOIN staging_products p ON sod.ProductID = p.ProductID;

-- Top-Selling Products
SELECT 
    p.ProductName,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC
LIMIT 5;


-- Products Below Reorder Level doesn't work, because it's not enough data
SELECT 
    p.ProductName, 
    p.UnitsInStock, 
    p.ReorderLevel
FROM 
    DimProduct p
WHERE 
    p.UnitsInStock < p.ReorderLevel;

-- Sales Trends by Product Category
SELECT 
    c.CategoryName, 
    EXTRACT(YEAR FROM d.Date) AS Year,
    EXTRACT(MONTH FROM d.Date) AS Month,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
JOIN DimCategory c ON p.CategoryID = c.CategoryID
JOIN DimDate d ON fps.DateID = d.DateID
GROUP BY c.CategoryName, Year, Month, d.Date
ORDER BY Year, Month, TotalRevenue DESC;

-- Inventory Valuation
SELECT 
    p.ProductName,
    p.UnitsInStock,
    p.UnitPrice,
    (p.UnitsInStock * p.UnitPrice) AS InventoryValue
FROM 
    DimProduct p
ORDER BY InventoryValue DESC;

-- Supplier Performance Based on Product Sales
SELECT 
    s.CompanyName,
    COUNT(DISTINCT fps.FactSalesID) AS NumberOfSalesTransactions,
    SUM(fps.QuantitySold) AS TotalProductsSold,
    SUM(fps.TotalSales) AS TotalRevenueGenerated
FROM 
    FactProductSales fps
JOIN DimProduct p ON fps.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName
ORDER BY TotalRevenueGenerated DESC;