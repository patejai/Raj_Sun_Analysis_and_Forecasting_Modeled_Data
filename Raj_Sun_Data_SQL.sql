-- Step 1: Ensure you're using the correct database
USE LiquorStoreAnalytics;

-- Step 2: Create or update the Customers table (if not already done)
CREATE TABLE IF NOT EXISTS Customers (
    CustomerID VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    ContactInfo VARCHAR(100),
    CustomerSince DATE
);

-- Step 3: Create the CustomerFeedback table to collect feedback data
CREATE TABLE IF NOT EXISTS CustomerFeedback (
    FeedbackID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID VARCHAR(10),
    FeedbackText TEXT,
    FeedbackDate DATE,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- (Skip the index creation if already done)
-- Step 4: Create the index on FeedbackDate in the CustomerFeedback table
CREATE INDEX idx_feedback_date ON CustomerFeedback(FeedbackDate);

SELECT * FROM LiquorStoreSales LIMIT 10;
SELECT Category, SUM(TotalAmount) AS TotalSales
FROM LiquorStoreSales
GROUP BY Category;
WITH CustomerSpending AS (
    SELECT 
        CustomerID, 
        SUM(TotalAmount) AS TotalSpent, 
        COUNT(DISTINCT Date) AS PurchaseCount, 
        MIN(Date) AS FirstPurchase, 
        MAX(Date) AS LastPurchase,
        DATEDIFF(MAX(Date), MIN(Date)) AS CustomerLifespan
    FROM LiquorStoreSales
    GROUP BY CustomerID
),
CustomerCLTV AS (
    SELECT 
        CustomerID, 
        TotalSpent, 
        CASE 
            WHEN CustomerLifespan = 0 THEN TotalSpent 
            ELSE TotalSpent / CustomerLifespan * 365 
        END AS AnnualCLTV
    FROM CustomerSpending
)
SELECT 
    CustomerID, 
    TotalSpent AS LifetimeSpend, 
    AnnualCLTV AS CustomerLifetimeValue
FROM CustomerCLTV
ORDER BY CustomerLifetimeValue DESC;

WITH RFMScores AS (
    SELECT 
        CustomerID,
        MAX(Date) AS LastPurchaseDate,
        COUNT(TransactionID) AS Frequency,
        SUM(TotalAmount) AS MonetaryValue,
        RANK() OVER (ORDER BY MAX(Date) DESC) AS RecencyRank,
        RANK() OVER (ORDER BY COUNT(TransactionID) DESC) AS FrequencyRank,
        RANK() OVER (ORDER BY SUM(TotalAmount) DESC) AS MonetaryRank
    FROM 
        LiquorStoreSales
    GROUP BY 
        CustomerID
)
SELECT 
    CustomerID, 
    RecencyRank, 
    FrequencyRank, 
    MonetaryRank,
    RecencyRank + FrequencyRank + MonetaryRank AS RFMScore
FROM 
    RFMScores
ORDER BY 
    RFMScore ASC;
WITH TopProducts AS (
    SELECT ItemPurchased, SUM(TotalAmount) AS ProductSales
    FROM LiquorStoreSales
    GROUP BY ItemPurchased
    ORDER BY ProductSales DESC
    LIMIT 5
)
SELECT ItemPurchased, ProductSales, 
       (ProductSales / (SELECT SUM(TotalAmount) FROM LiquorStoreSales) * 100) AS RevenueContribution
FROM TopProducts;

