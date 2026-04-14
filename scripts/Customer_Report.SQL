/*
=====================================================================
Customer Report
=====================================================================

Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
=====================================================================
*/
CREATE VIEW Customer_Report AS
WITH CTE_CustomerReport_Details AS
(
SELECT f.customer_key, customer_number, CONCAT(first_name, ' ', last_name) Customer_Name,
DATEDIFF(YEAR, birthdate, GETDATE()) Age, order_date,                          
order_number, sales_amount, quantity, product_key
FROM dbo.fact_sales f
LEFT JOIN dbo.dim_customers c
ON f.customer_key = c.customer_key
),
CTE_Customer_Metrics AS 
(
SELECT customer_key, customer_number, Customer_Name, Age, COUNT(DISTINCT order_number) Total_Orders,
SUM(sales_amount) Total_Sales, SUM(quantity) Total_Quantity,         
COUNT(DISTINCT product_key) Total_Products,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) Lifespan,
MIN(order_date) First_Order, MAX(order_date) Last_Order
FROM CTE_CustomerReport_Details
GROUP BY customer_key, customer_number, Customer_Name, Age
)
SELECT customer_key, customer_number, Customer_Name, Age, 
First_Order, Last_Order,  
CASE WHEN Total_Sales > 5000 AND Lifespan >=12 THEN 'VIP' 
			WHEN Total_Sales <=5000 AND Lifespan >=12 THEN 'Regular'
			ELSE 'New' END Customer_Category,
CASE WHEN Age < 20 THEN 'Below 20' 
			WHEN Age BETWEEN 20 AND 30 THEN '20-30' 
			WHEN Age BETWEEN 30 AND 40 THEN '30-40' 
			WHEN Age BETWEEN 40 AND 50 THEN '40-50' 
			WHEN Age BETWEEN 50 AND 60 THEN '50-60' 
			ELSE 'Abv 60' END Customer_Age
, Total_Orders, Total_Sales, Total_Quantity, Total_Products, Lifespan, DATEDIFF(MONTH, Last_Order, GETDATE()) Recency,
Total_Sales/Total_Orders AS Average_Order_Value,
CASE WHEN Lifespan = 0 THEN Total_Sales
ELSE Total_Sales/Lifespan END AS Avg_Monthly_Orders
FROM CTE_Customer_Metrics;

SELECT * FROM Customer_Report;
