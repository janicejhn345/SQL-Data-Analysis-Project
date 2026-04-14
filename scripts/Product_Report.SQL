/*
=========================================================================

Product Report

=========================================================================

Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - total orders
        - total sales
        - total quantity sold
        - total customers (unique)
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last sale)
        - average order revenue (AOR)
        - average monthly revenue

=========================================================================
*/

CREATE VIEW Products_Report AS
WITH CTE_Baisc_ProdDetails AS 
(
	SELECT order_number, product_name, category, subcategory, cost, sales_amount, quantity, customer_key, order_date 
	FROM dbo.fact_sales f
	LEFT JOIN dbo.dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL
),

CTE_Products_Aggregations AS
(
	SELECT product_name, category, subcategory, 
	SUM(cost) Total_Cost,
	COUNT(DISTINCT order_number) Total_Orders, 
	SUM(sales_amount) Current_Revenue,
	SUM(quantity) Total_Quantity, 
	COUNT(DISTINCT customer_key) Total_Customers,
	MAX(order_date) Last_Order, 
	MIN(order_date) First_Order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) Lifespan,
	DATEDIFF(MONTH, MAX(order_date), GETDATE()) Recency,
	ROUND(AVG(CAST(sales_amount AS float)/NULLIF(quantity,0)),2) AS Avg_Selling_Price
	FROM CTE_Baisc_ProdDetails
	GROUP BY product_name, category, subcategory
),
CTE_With_Prev AS
(
	SELECT *,
	LAG(Current_Revenue) OVER (ORDER BY Current_Revenue) AS Prev_Sales
	FROM CTE_Products_Aggregations
)

SELECT *,
(Current_Revenue - Prev_Sales) AS Change_In_Sales,
CASE 
WHEN Current_Revenue - Prev_Sales < 0 THEN 'Decrease'
WHEN Current_Revenue - Prev_Sales > 0 THEN 'Increase'
ELSE 'No Growth' END AS Sales_Growth,
CASE 
WHEN Current_Revenue > 50000 THEN 'High Performer' 
WHEN Current_Revenue >= 10000 THEN 'Medium Performer'
ELSE 'Low Performer' END AS Performance_Category,
CASE 
WHEN Total_Orders = 0 THEN 0 
ELSE Current_Revenue / Total_Orders END AS Average_Order_Revenue,
CASE 
WHEN Lifespan = 0 THEN Current_Revenue
ELSE Current_Revenue / Lifespan END AS Average_Monthly_Revenue FROM CTE_With_Prev;

SELECT * FROM Products_Report;
