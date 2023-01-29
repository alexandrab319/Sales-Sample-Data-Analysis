--- Inspecting Data
SELECT * FROM dbo.sales_data_sample

--- Checking Unique Values
SELECT DISTINCT STATUS FROM dbo.sales_data_sample -
SELECT DISTINCT YEAR_ID FROM dbo.sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM dbo.sales_data_sample 
SELECT DISTINCT COUNTRY FROM dbo.sales_data_sample 
SELECT DISTINCT DEALSIZE FROM dbo.sales_data_sample 
SELECT DISTINCT TERRITORY FROM dbo.sales_data_sample 

SELECT DISTINCT MONTH_ID FROM dbo.sales_data_sample
WHERE YEAR_ID = 2003

---Analysis
-----Group sales by productline
SELECT PRODUCTLINE, SUM(SALES) Revenue
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC 

SELECT DEALSIZE, SUM(SALES) Revenue
FROM dbo.sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

---What was the best month for sales in a given year? How much money earned in sales? 
SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY 2 DESC 

--November is the best month for sales. What product do they sell in November?
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC

--- Who is the best customer? 

DROP TABLE IF EXISTS #rfm
;with rfm as
(
	SELECT
		CUSTOMERNAME,
		SUM(SALES) MONETARYVALUE,
		AVG(SALES) AVGMONETARYVALUE,
		COUNT(ORDERNUMBER) FREQUENCY,
		MAX(ORDERDATE) LAST_ORDER_DATE,
		(SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample) MAX_ORDER_DATE,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample)) RECENCY
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc AS 
( 
	SELECT r.*,
		NTILE(4) OVER (ORDER BY  RECENCY DESC) rfm_recency,
		NTILE(4) OVER (ORDER by FREQUENCY) rfm_frequency,
		NTILE(4) OVER (ORDER by MONETARYVALUE) rfm_monetary
	FROM rfm r
)
SELECT c.*, rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
CAST(rfm_recency AS VARCHAR)+ CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) rfm_cell_string
INTO #rfm
FROM rfm_calc c 

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN (111,112,121,122,123,132,211,212,114,141) THEN 'LOST_CUSTOMERS' --- lost customers
		WHEN rfm_cell_string IN (133,134,143,244,334,343,344,144) THEN 'SLIPPING AWAY, CANNOT LOSE' --- big spenders who havent spent lately, pulling away 
		WHEN rfm_cell_string IN (311,411,331) THEN 'NEW CUSTOMERS' 
		WHEN rfm_cell_string IN (222,223,233,322) THEN 'POTENTIAL CHURNERS' 
		WHEN rfm_cell_string IN (323,333,321,422,332,432) THEN 'ACTIVE' --- customers who buy often and recently, but at low prices
		WHEN rfm_cell_string IN (433,434,443,444) THEN 'LOYAL' 
	END rfm_segment

from #rfm 


---What products are most often sold together? - can advertise these items together so they are boughht together 
-- SELECT * FROM dbo.sales_data_sample WHERE ORDERNUMBER = 10411

SELECT DISTINCT ORDERNUMBER, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM [dbo].[sales_data_sample] p
	WHERE ORDERNUMBER IN 
		(
	
			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, COUNT(*) rn
				FROM dbo.sales_data_sample
				WHERE STATUS = 'SHIPPED'
				GROUP BY ORDERNUMBER 
			)m
			WHERE rn = 2 -- where 2 order products are bought together ... rn = 3 would be 3 bought together ... 
		)
		AND p.ORDERNUMBER = s.ORDERNUMBER 
		FOR XML PATH (''))

		, 1, 1, '') PRODUCTCODES

FROM dbo.sales_data_sample s
ORDER BY 2 DESC


-- What are the gross sales in the USA?
--- Compare gross sales in the USA with France

SELECT SUM(SALES) "TOTAL SALES IN USA"
FROM sales_data_sample
WHERE COUNTRY = 'USA'

SELECT 
	COUNTRY, 
	SUM(SALES) AS 'TOTAL SALES',
	(
		SELECT SUM(SALES)
		FROM sales_data_sample
		WHERE COUNTRY = 'USA'
	) - SUM(SALES) AS 'DIFFERENCE IN SALES'
FROM sales_data_sample
WHERE COUNTRY IN ('USA', 'FRANCE','NORWAY', 'AUSTRALIA')
GROUP BY COUNTRY 

--- Total sales in NY
SELECT SUM(SALES) as 'TOTAL SALES IN NY'
FROM sales_data_sample
WHERE COUNTRY = 'USA' AND STATE = 'NY'

--- Total sales in NY vs CA 
SELECT STATE, SUM(SALES) AS 'TOTAL SALES'
FROM sales_data_sample
WHERE STATE IN ('NY','CA')
GROUP BY STATE