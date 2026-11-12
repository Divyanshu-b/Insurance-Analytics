use insurance_analytics;

/*
1-Total Policy

Definition: Total number of policies in the system (active and inactive).
Purpose: Provides an overall view of policy volume.
*/
SELECT COUNT(Policy_ID) AS Total_Policies 
FROM Policy_Details;

/*
2-Total Customers

Definition: Total count of customers who hold one or more policies.
Purpose: Indicates customer base size and engagement.
*/
SELECT COUNT(DISTINCT Customer_ID) AS Total_Active_Customers 
FROM Policy_Details;

/*
3-Age Bucket Wise Policy Count

Definition: Policies grouped by customer age brackets (e.g., 18-25, 26-35).
Purpose: Analyzes policy distribution across different age groups.
*/

WITH CategorizedData AS (
    SELECT 
        CASE 
            WHEN c.Age BETWEEN 18 AND 25 THEN '18-25'
            WHEN c.Age BETWEEN 26 AND 35 THEN '26-35'
            WHEN c.Age BETWEEN 36 AND 45 THEN '36-45'
            WHEN c.Age BETWEEN 46 AND 55 THEN '46-55'
            WHEN c.Age BETWEEN 56 AND 65 THEN '56-65'
            ELSE '66-85'
        END AS Age_Bucket,
        p.Policy_ID
    FROM Policy_Details p
    JOIN Customer_Information c ON p.Customer_ID = c.Customer_ID
)
SELECT 
    IFNULL(Age_Bucket, 'Grand Total') AS Age_Bucket,
    COUNT(Policy_ID) AS Policy_Count
FROM CategorizedData
GROUP BY Age_Bucket WITH ROLLUP
ORDER BY GROUPING(Age_Bucket) ASC, Policy_Count ASC;


/*
4-Gender Wise Policy Count

Definition: Number of policies categorized by gender (male, female, other).
Purpose: Identifies trends and gaps in policy adoption by gender.
*/
SELECT 
    IFNULL(c.Gender, 'Grand Total') AS Gender, 
    COUNT(p.Policy_ID) AS Policy_Count
FROM Policy_Details p
JOIN Customer_Information c ON p.Customer_ID = c.Customer_ID
GROUP BY c.Gender WITH ROLLUP;


/*
5-Policy Type Wise Policy Count

Definition: Number of policies distributed by policy type
Purpose: Tracks which policy categories are most popular.
*/
SELECT 
    IFNULL(Policy_Type, 'Grand Total') AS Policy_Type, 
    COUNT(Policy_ID) AS Policy_Count
FROM Policy_Details
GROUP BY Policy_Type WITH ROLLUP
ORDER BY GROUPING(Policy_Type) ASC, Policy_Count DESC;

/*
6-Policy Expire This Year

Definition: Count of policies set to expire within the current calendar year.
Purpose: Helps focus on renewal opportunities.
*/
SELECT COUNT(Policy_ID) AS Policies_Expiring_This_Year
FROM Policy_Details
WHERE YEAR(Policy_End_Date) = YEAR(CURDATE());

/*
7-Premium Growth Rate

Definition: Percentage increase in premium revenue over a specific time period.
Purpose: Measures business growth from premiums.
*/

WITH Yearly_Premium AS (
    SELECT 
        YEAR(Policy_Start_Date) AS Policy_Year,
        SUM(Premium_Amount) AS Total_Premium
    FROM Policy_Details
    GROUP BY YEAR(Policy_Start_Date)
)
SELECT 
    Policy_Year,
    Total_Premium,
    LAG(Total_Premium) OVER (ORDER BY Policy_Year) AS Previous_Year_Premium,
    CASE 
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year) IS NULL THEN NULL
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year) = 0 THEN NULL
        ELSE ROUND(((Total_Premium - LAG(Total_Premium) OVER (ORDER BY Policy_Year)) / LAG(Total_Premium) OVER (ORDER BY Policy_Year)) * 100, 2)
    END AS Premium_YoY_Growth_Rate_Percent
FROM Yearly_Premium
ORDER BY Policy_Year;

WITH Quarter_Premium AS (
    SELECT 
        YEAR(Policy_Start_Date) AS Policy_Year,
        QUARTER(Policy_Start_Date) AS Policy_Quarter,
        SUM(Premium_Amount) AS Total_Premium
    FROM Policy_Details
    GROUP BY YEAR(Policy_Start_Date), QUARTER(Policy_Start_Date)
)
SELECT 
    Policy_Year,
    Policy_Quarter,
    Total_Premium,
    LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Quarter) AS Previous_Quarter_Premium,
    CASE 
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Quarter) IS NULL THEN NULL
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Quarter) = 0 THEN NULL
        ELSE ROUND(((Total_Premium - LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Quarter)) / LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Quarter)) * 100, 2)
    END AS Premium_QoQ_Growth_Rate_Percent
FROM Quarter_Premium
ORDER BY Policy_Year, Policy_Quarter;

WITH Monthly_Premium AS (
    SELECT 
        YEAR(Policy_Start_Date) AS Policy_Year,
        MONTH(Policy_Start_Date) AS Policy_Month,
        SUM(Premium_Amount) AS Total_Premium
    FROM Policy_Details
    GROUP BY YEAR(Policy_Start_Date), MONTH(Policy_Start_Date)
)
SELECT 
    Policy_Year,
    Policy_Month,
    Total_Premium,
    LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Month) AS Previous_Month_Premium,
    CASE 
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Month) IS NULL THEN NULL
        WHEN LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Month) = 0 THEN NULL
        ELSE ROUND(((Total_Premium - LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Month)) / LAG(Total_Premium) OVER (ORDER BY Policy_Year, Policy_Month)) * 100, 2)
    END AS Premium_MoM_Growth_Rate_Percent
FROM Monthly_Premium
ORDER BY Policy_Year, Policy_Month;


/*
8-Claim Status Wise Policy Count

Definition: Count of policies grouped by claim status (e.g., approved, rejected, pending).
Purpose: Tracks claim processing efficiency.
*/

SELECT 
    IFNULL(Claim_Status, 'Grand Total') AS Claim_Status, 
    COUNT(DISTINCT Policy_ID) AS Unique_Policy_Count,
    COUNT(Claim_ID) AS Total_Claims_Count
FROM Claims
GROUP BY Claim_Status WITH ROLLUP;


/*
9-Payment Status Wise Policy Count

Definition: Policies categorized by payment status (e.g., paid, overdue, pending).
Purpose: Monitors financial health and payment compliance.
*/

SELECT 
    CASE WHEN GROUPING(Payment_Status) = 1 THEN 'Grand Total' ELSE Payment_Status END AS Payment_Status,
    COUNT(Policy_ID) AS Policy_Count
FROM Payment_History
GROUP BY Payment_Status WITH ROLLUP;


/*
10-Total Claim Amount

Definition: Total amount paid for claims across all policies.
Purpose: Tracks the financial impact of claims on the business
*/

SELECT 
    CONCAT('$', ROUND(SUM(Claim_Amount) / 1000000, 1), 'M') AS Total_Approved_Claims_Amount
FROM Claims
WHERE Claim_Status = 'Approved';
