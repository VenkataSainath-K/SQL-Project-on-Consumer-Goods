/*Request 1 - Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/

SELECT DISTINCT
    MARKET
FROM
    DIM_CUSTOMER
WHERE
    CUSTOMER = 'Atliq Exclusive'
        AND REGION = 'APAC'
ORDER BY MARKET;


/*Request 2 -  What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/

WITH unique_products_2020 AS
	(SELECT 
    COUNT(DISTINCT PRODUCT_CODE) AS unique_products_2020
FROM
	FACT_SALES_MONTHLY
WHERE
	FISCAL_YEAR = 2020),
unique_products_2021 AS
	(SELECT 
    COUNT(DISTINCT PRODUCT_CODE) AS unique_products_2021
FROM
    FACT_SALES_MONTHLY
WHERE
    FISCAL_YEAR = 2021)
SELECT 
    unique_products_2020,
    unique_products_2021,
    CONCAT(ROUND((unique_products_2021 - unique_products_2020) / unique_products_2020 * 100,
                    2),
            '%') AS percentage_chg
FROM
    unique_products_2020
        CROSS JOIN
    unique_products_2021


/*Request 3 - Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
The final output contains 2 fields,
segment
product_count*/

SELECT 
    SEGMENT, COUNT(DISTINCT PRODUCT_CODE) AS 'product_count'
FROM
    DIM_PRODUCT
GROUP BY SEGMENT
ORDER BY 'product_count' DESC;


/*Request 4 - Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference*/

WITH CTE_2020 AS
  (SELECT 
    P.SEGMENT,
    COUNT(DISTINCT p.PRODUCT_CODE) AS 'product_count_2020'
FROM
    DIM_PRODUCT p
        INNER JOIN
    FACT_SALES_MONTHLY S ON P.PRODUCT_CODE = S.PRODUCT_CODE
WHERE
    S.FISCAL_YEAR = 2020
GROUP BY P.SEGMENT
ORDER BY `product_count_2020` DESC),
CTE_2021 AS
  (SELECT 
    P.SEGMENT,
    COUNT(DISTINCT P.PRODUCT_CODE) AS 'product_count_2021'
FROM
    DIM_PRODUCT P
        INNER JOIN
    FACT_SALES_MONTHLY S ON P.PRODUCT_CODE = S.PRODUCT_CODE
WHERE
    S.FISCAL_YEAR = 2021
GROUP BY P.SEGMENT
ORDER BY `product_count_2021` DESC)
SELECT 
    CTE_2020.SEGMENT,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 AS difference
FROM
    CTE_2020
        INNER JOIN
    CTE_2021 ON CTE_2020.SEGMENT = CTE_2021.SEGMENT
ORDER BY `difference` DESC;


/*Request 5 - Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code
product
manufacturing_cost*/

SELECT 
    M.PRODUCT_CODE,
    CONCAT(PRODUCT, ' (', VARIANT, ')') AS PRODUCT,
    COST_YEAR,
    manufacturing_cost
FROM
    fact_manufacturing_cost M
        JOIN
    DIM_PRODUCT P ON M.PRODUCT_CODE = P.PRODUCT_CODE
WHERE
    MANUFACTURING_COST = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

/*--------------------------*/
/*Request 6 -  Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage*/

SELECT 
    C.CUSTOMER_CODE,
    C.CUSTOMER,
    ROUND(AVG(PRE_INVOICE_DISCOUNT_PCT), 4) AS average_discount_percentage
FROM
    FACT_PRE_INVOICE_DEDUCTIONS D
        JOIN
    DIM_CUSTOMER C ON D.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE
    C.MARKET = 'India'
        AND FISCAL_YEAR = '2021'
GROUP BY CUSTOMER_CODE
ORDER BY average_discount_percentage DESC
LIMIT 5;


/*Request 7 - Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions. The final report contains these columns:
Month
Year
Gross sales Amount*/

WITH temp_table AS (
    SELECT 
    CUSTOMER,
    MONTHNAME(DATE) AS month,
    MONTH(DATE) AS MONTH_NUMBER,
    YEAR(DATE) AS year,
    (SOLD_QUANTITY * GROSS_PRICE) AS gross_sales
FROM
    FACT_SALES_MONTHLY S
        JOIN
    FACT_GROSS_PRICE G ON S.PRODUCT_CODE = G.PRODUCT_CODE
        JOIN
    DIM_CUSTOMER C ON S.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE
    CUSTOMER = 'Atliq exclusive'
)
SELECT 
    month,
    year,
    CONCAT(ROUND(SUM(gross_sales) / 1000000, 2),
            'M') AS gross_sales
FROM
    temp_table
GROUP BY year , month
ORDER BY year , MONTH_NUMBER;


/*Request 8 - In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

WITH temp_table AS (
  SELECT 
    DATE,
    MONTH(DATE_ADD(DATE, INTERVAL 4 MONTH)) AS PERIOD,
    FISCAL_YEAR,
    SOLD_QUANTITY
FROM
    FACT_SALES_MONTHLY
)
SELECT 
    CASE
        WHEN PERIOD / 3 <= 1 THEN 'Q1'
        WHEN PERIOD / 3 <= 2 AND PERIOD / 3 > 1 THEN 'Q2'
        WHEN PERIOD / 3 <= 3 AND PERIOD / 3 > 2 THEN 'Q3'
        WHEN PERIOD / 3 <= 4 AND PERIOD / 3 > 3 THEN 'Q4'
    END quarter,
    ROUND(SUM(SOLD_QUANTITY) / 1000000, 2) AS total_sold_quanity_in_millions
FROM
    temp_table
WHERE
    FISCAL_YEAR = 2020
GROUP BY quarter
ORDER BY total_sold_quanity_in_millions DESC;
   

/*Request 9 - Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage*/

WITH temp_table AS (
	SELECT 
    C.CHANNEL,
    SUM(S.SOLD_QUANTITY * G.GROSS_PRICE) AS TOTAL_SALES
FROM
    FACT_SALES_MONTHLY S
        JOIN
    FACT_GROSS_PRICE G ON S.PRODUCT_CODE = G.PRODUCT_CODE
        JOIN
    DIM_CUSTOMER C ON S.CUSTOMER_CODE = C.CUSTOMER_CODE
WHERE
    S.FISCAL_YEAR = 2021
GROUP BY C.CHANNEL
ORDER BY TOTAL_SALES DESC
)
SELECT 
    CHANNEL,
    ROUND(TOTAL_SALES / 1000000, 2) AS gross_sales_in_millions,
	CONCAT(ROUND(TOTAL_SALES/(SUM(TOTAL_SALES) OVER()) * 100, 2), '%') AS percentage 
FROM
	temp_table;

/*--------------------------*/
/*Request 10 - Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
division
product_code
product
total_sold_quantity
rank_order*/

WITH temp_table AS (
SELECT
	division, S.product_code, CONCAT(P.PRODUCT,"(",P.VARIANT,")") AS product , SUM(SOLD_QUANTITY) AS total_sold_quantity,
	RANK() OVER (PARTITION BY DIVISION ORDER BY SUM(SOLD_QUANTITY) DESC) AS rank_order
FROM
	FACT_SALES_MONTHLY S
JOIN
	DIM_PRODUCT P ON S.PRODUCT_CODE = P.PRODUCT_CODE
WHERE
	FISCAL_YEAR = 2021
GROUP BY product_code
)
SELECT 
    *
FROM
    temp_table
WHERE
    RANK_ORDER IN (1 , 2, 3);