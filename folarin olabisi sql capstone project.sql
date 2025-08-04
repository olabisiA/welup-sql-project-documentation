create table temp_project(
transactionno text,
date date,
productno text,
productname text,
price decimal(10,2),
quantity int,
customerno text,
country text
);

select *
from temp_project

SELECT EXTRACT(YEAR FROM date) AS year
FROM temp_project
GROUP BY year
ORDER BY year DESC;

update temp_project
set transactionno=REPLACE (transactionno,'C','');

alter table temp_project
alter column transactionno
type int using transactionno:: integer

alter table temp_project
add column cleanedquantity varchar (50)

UPDATE temp_project
SET cleanedquantity = CASE
    WHEN quantity >= 0 THEN 'purchase'
    WHEN quantity < 0 THEN 'return'
    ELSE NULL
END;


alter table temp_project
add column cleanedcustomerno varchar (50)


UPDATE temp_project
SET cleanedcustomerno = CASE
    WHEN TRIM(LOWER(customerno)) = 'na' THEN 'Unknown'
    ELSE 'Known'
END;


CREATE TABLE temp_project_backup AS
SELECT * FROM temp_project;


DELETE FROM temp_project
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM temp_project
    GROUP BY 
        transactionno, date, productno, productname, 
        price, quantity, customerno, country,cleanedquantity,cleanedcustomerno
);

select count(*)
from temp_project
----------------------syntax for primary key
ALTER TABLE temp_project
ADD COLUMN id SERIAL PRIMARY KEY;

alter table temp_project
add column revenue decimal (10,2)
--------------- Revenue (Price × Quantity) 
update temp_project
set revenue =price *quantity

----------note:To be able to analyse the customer column,I created a helper column to indicate "known"as customer whose detailed were
-----noted and "unknown"whose detailed were not.so therefore, top customers where based on "known"


------Customer transaction count 
select customerno,count(transactionno) as orders
from temp_project
where cleanedcustomerno ='Known'
group by customerno
order by orders desc
limit 20

select *
from temp_project

------Top 20 customers by total revenue
select customerno,sum(revenue) as total_sales
from temp_project
where cleanedcustomerno ='Known'
group by customerno
order by Total_sales desc
limit 20

-------Customer purchase frequency distribution
------Customer purchase frequency distribution 

-------- each customers and how many times they purchased
select customerno,count(transactionno) as purchase
from temp_project
where cleanedcustomerno ='Known'
group by customerno
order by purchase desc

------- to get their frequency distribution
SELECT purchase, COUNT(*) AS number_of_customers
FROM (
    SELECT customerno, COUNT(transactionno) AS purchase
    FROM temp_project
    WHERE cleanedcustomerno = 'Known'
    GROUP BY customerno
) AS purchase_counts
GROUP BY purchase
ORDER BY purchase desc
limit 20
--------------------------Note:To be able to analyse the quantity column, another column was created for it just because of the negative sign in the
------main column, knowing fully well that quantity shouldnt be in (-) sign.upon analysis of the quantity column,in relation to dates and product number,
---meaning the sale was initially completed but later reversed — consistent with a return, not a cancellation.

----Best and worst performing products by revenue and quantity 
---------Best performing product
SELECT  productname,SUM(quantity) AS total_quantity, SUM(revenue) AS total_revenue
FROM  temp_project
WHERE cleanedquantity = 'purchase'
AND quantity > 0
GROUP BY productname
ORDER BY total_revenue DESC
LIMIT 10;

-----worst performing product
SELECT productname,SUM(quantity) AS total_quantity, SUM(revenue) AS total_revenue
FROM  temp_project
WHERE cleanedquantity = 'purchase'
AND quantity > 0
GROUP BY productname
ORDER BY total_revenue asc
LIMIT 10;

------Products with the highest/lowest average transaction values
--------product with the highest average transaction value

select productname,avg (revenue)as transaction_value
from temp_project
where cleanedquantity = 'purchase'
and quantity >0
group by productname
order by transaction_value desc
limit 10
-------- product with the lowest average transaction value
select productname,avg (revenue)as transaction_value
from temp_project
where cleanedquantity = 'purchase'
and quantity >0
group by productname
order by transaction_value asc
limit 10

-----Product performance trends over time
select date_trunc('month', date) as time, productname,sum (quantity) as unit_sold,sum(revenue) as sales
from temp_project
where cleanedquantity ='purchase' and quantity >0
group by time,productname
order by time, productname 

-------Yearly and quarterly sales trends 
------yearly sales trend
select extract('year' from date) as yearly_sales,sum(quantity) as unit_sold, sum (revenue)as sales
from temp_project
where cleanedquantity ='purchase' and quantity>0
group by yearly_sales
order by yearly_sales,unit_sold

-----quarterly sales trend

select date_trunc('quarter', date) as quarterly_sales,sum(quantity)as unit_sold, sum(revenue)as sales
from temp_project
where cleanedquantity ='purchase' and quantity>0
group by quarterly_sales
order by quarterly_sales,unit_sold


------Running totals and moving averages
-------Running totals

SELECT DATE_TRUNC('month', date) AS monthly_sales, SUM(quantity) AS total_unit_sold,SUM(revenue) AS total_revenue,
SUM(SUM(quantity)) OVER (ORDER BY DATE_TRUNC('month', date)) AS running_unit_total,
SUM(SUM(revenue)) OVER (ORDER BY DATE_TRUNC('month', date)) AS running_revenue_total
FROM temp_project
WHERE cleanedquantity = 'purchase' AND quantity > 0
GROUP BY  monthly_sales
ORDER BY  monthly_sales desc

--------Moving averages


SELECT monthly_sales,total_revenue, AVG(total_revenue) OVER ( ORDER BY monthly_sales 
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_revenue
FROM 
(SELECT date_trunc('month', date) AS monthly_sales,SUM(revenue) AS total_revenue
 FROM temp_project
 WHERE cleanedquantity = 'purchase' AND quantity > 0
 GROUP BY monthly_sales
) sub
ORDER BY monthly_sales;

-----Country-wise sales performance ranking 
SELECT country, SUM(revenue) AS total_revenue,
RANK() OVER (ORDER BY SUM(revenue) DESC) AS sales_rank
FROM temp_project
GROUP BY country
ORDER BY sales_rank

-----Market penetration analysis by country
SELECT country,COUNT(DISTINCT customerno) AS customer_count,
ROUND( (COUNT(DISTINCT customerno) * 100.0) / (SELECT COUNT(DISTINCT customerno) FROM temp_project), 2
) AS market_penetration
FROM temp_project
WHERE cleanedquantity = 'purchase' AND quantity > 0
GROUP BY country
ORDER BY market_penetration DESC













