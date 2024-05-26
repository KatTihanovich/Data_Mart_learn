--1) Create a fact table FactSupplierPurchases
CREATE TABLE FactSupplierPurchases (
    PurchaseID SERIAL PRIMARY KEY,
    SupplierID INT,
    TotalPurchaseAmount DECIMAL,
    PurchaseDate DATE,
    NumberOfProducts INT,
    FOREIGN KEY (SupplierID) REFERENCES DimSupplier(SupplierID)
);

--Populate the FactSupplierPurchases table with data
INSERT INTO FactSupplierPurchases (SupplierID, TotalPurchaseAmount, PurchaseDate, NumberOfProducts)
SELECT 
    p.SupplierID, 
    SUM(od.UnitPrice * od.Qty - od.discount) AS TotalPurchaseAmount, 
    o.OrderDate AS PurchaseDate, 
    COUNT(DISTINCT od.ProductID) AS NumberOfProducts
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
JOIN staging_orders o USING(OrderId)
GROUP BY p.SupplierID, o.OrderDate;

-- Supplier Spending Analysis
SELECT
    s.CompanyName,
    SUM(fsp.TotalPurchaseAmount) AS TotalSpend,
    EXTRACT(YEAR FROM fsp.PurchaseDate) AS Year,
    EXTRACT(MONTH FROM fsp.PurchaseDate) AS Month
FROM FactSupplierPurchases fsp
JOIN DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName, Year, Month
ORDER BY TotalSpend DESC;

-- Product Cost Breakdown by Supplier
SELECT
    s.CompanyName,
    p.ProductName,
    AVG(od.UnitPrice) AS AverageUnitPrice,
    SUM(od.qty) AS TotalQuantityPurchased,
    SUM(od.UnitPrice * od.qty) AS TotalSpend
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC;

-- Top Five Products by Total Purchases per Supplier
SELECT
    s.CompanyName,
    p.ProductName,
    SUM(od.UnitPrice * od.qty) AS TotalSpend
FROM staging_order_details od
JOIN staging_products p ON od.ProductID = p.ProductID
JOIN DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC
LIMIT 5;

--Supplier Performance Report doesn't work, because it's not enough data 
SELECT
    s.CompanyName,
    AVG(fsp.DeliveryLeadTime) AS AverageLeadTime,
    SUM(fsp.OrderAccuracy) / COUNT(fsp.PurchaseID) AS AverageOrderAccuracy,
    COUNT(fsp.PurchaseID) AS TotalOrders
FROM FactSupplierPurchases fsp
JOIN DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName
ORDER BY AverageLeadTime, AverageOrderAccuracy DESC;

--Supplier Reliability Score Report doesn't work, because it's not enough data
SELECT
    s.CompanyName,
    (COUNT(fsp.PurchaseID) FILTER (WHERE fsp.OnTimeDelivery = TRUE) / COUNT(fsp.PurchaseID)::FLOAT) * 100 AS ReliabilityScore
FROM FactSupplierPurchases fsp
JOIN DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName
ORDER BY ReliabilityScore DESC;