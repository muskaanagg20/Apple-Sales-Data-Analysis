# Query performance optimisation

explain analyze
select * from sales
where product_id = 986;

create index sales_product_id on sales(product_id);
create index sales_store_id on sales(store_id);
create index sales_sale_id on sales(sale_id);

# SQL QUERIES AND SOLUTIONS

-- Find the number of stores in each country.

select country, count(store_id) as Total_stores 
from stores
group by 1
order by 2 desc;

-- Calculate the total number of units sold by each store.

select s.store_id, st.store_name, sum(s.quantity) as total_quantity 
from sales as s
join stores as st
on s.store_id=st.store_id
group by 1,2
order by 3 desc;

-- Identify how many sales occurred in December 2024.

select count(*) as Total_Sales 
from sales
where year(sale_date)=2024 and month(sale_date) = 12;

-- Determine how many stores have never had a warranty claim filed.

select count(store_id) as store_count 
from stores
where store_id not in (
	select distinct s.store_id 
	from warranty_claims as w
	join sales as s
	on w.sale_id=s.sale_id
);

-- Calculate the percentage of warranty claims marked as "Warranty Void".

select round(count(claim_id)/ cast((select count(claim_id) from warranty_claims) as unsigned) * 100, 2) as void_percentage from warranty_claims
where repair_status = 'Warranty Void';

-- Identify which store had the highest total units sold in the last month.

select s.store_id, st.store_name,sum(s.quantity) as total_units_sold
from sales as s
join stores as st
on s.store_id = st.store_id
where s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
group by 1,2
order by 3 desc
limit 1;

-- Count the number of unique products sold in the last month.

select count(distinct product_id) as unique_prod_sold 
from sales
where sale_date>=date_sub(current_date(),interval 1 month);

-- Find the average price of products in each category.

select p.category_id, c.category_name,avg(p.price) as avg_price
from products as p
join categories as c
on p.category_id = c.category_id
group by 1,2
order by 3 desc;

-- How many warranty claims were filed in January?

select count(claim_id) as total_jan_claims 
from warranty_claims
where month(claim_date)= 01;

-- For each store, identify the best-selling day based on highest quantity sold.

with day_rank as(
select store_id, dayname(sale_date) as day_name , sum(quantity) as total_quantity,
dense_rank() over(partition by store_id order by sum(quantity) desc) as rankings
from sales
group by 1, 2
order by 1, 3 desc)

select store_id, day_name, total_quantity
from day_rank
where rankings = 1;

-- Identify the least selling product in each country based on total units sold.

with prod_country_rank as (
select st.country, s.product_id,sum(s.quantity) as quantity_sold,
dense_rank() over(partition by st.country order by sum(s.quantity)) as rankings
from sales as s
join stores as st
on s.store_id = st.store_id
group by 1,2
order by 1,3)

select country, product_id, quantity_sold 
from prod_country_rank 
where rankings = 1;

-- Calculate how many warranty claims were filed within 180 days of a product sale.

select count(claim_id) as total_claims
from warranty_claims as w
left join sales as s
on w.sale_id = s.sale_id
where w.claim_date-s.sale_date <= 180;

-- Determine how many warranty claims were filed for products launched in the last two years.

select p.product_id, count(w.claim_id) as total_claims
from products as p
join sales as s
on p.product_id = s.product_id
join warranty_claims as w
on s.sale_id = w.sale_id
where p.launch_date >= date_sub(current_date(), interval 2 year)
group by 1
order by 2 desc;

-- List the days in the last three months where sales exceeded 50 units in the USA.

select dayname(s.sale_date) as day_name, sum(s.quantity) as quantity_sold 
from sales as s
join stores as st
on s.store_id = st.store_id
where s.sale_date >= date_sub(current_date(), interval 3 month) and st.country = 'USA'
group by 1
having sum(s.quantity)>50
order by 2 desc;

-- Identify the product category with the most warranty claims filed in the last two months.

select p.category_id, count(w.claim_id) as total_claims 
from warranty_claims as w
join sales as s
on w.sale_id=s.sale_id
join products as p
on s.product_id = p.product_id
where w.claim_date <= date_sub(current_date(),interval 2 month)
group by 1
order by 2 desc;

-- Determine the percentage chance of receiving warranty claims after each purchase for each country.
with t1 as(
select st.country, count(w.claim_id) as total_claims, sum(s.quantity) as total_units_sold
from sales as s
join stores as st
on s.store_id = st.store_id
left join warranty_claims as w
on s.sale_id = w.sale_id
group by 1)

select country, 
	   total_claims/total_units_sold * 100 as risk_percentage  
from t1;

-- Analyze the month-by-month growth ratio for each store.

with monthly_sales as(
select s.store_id,st.store_name, month(s.sale_date) as month_number,sum(s.quantity*p.price) as net_sales from sales as s
left join products as p
on s.product_id = p.product_id
join stores as st
on s.store_id = st.store_id
group by 1,2,3
order by 1,3), 

growth_perc as(
select store_name, month_number, net_sales as current_month_sale,
	lag(net_sales,1) over(partition by store_name order by month_number) as prev_month_sales
from monthly_sales)

select store_name, month_number, current_month_sale,prev_month_sales,
	round((current_month_sale-prev_month_sales)/prev_month_sales,1) as growth_ratio
from growth_perc
where prev_month_sales is not null;

-- Write a query to calculate the monthly running total of sales for each store.

with monthly_total as(
select s.store_id,st.store_name, year(s.sale_date) as year_num,month(s.sale_date) as month_number,
	sum(s.quantity*p.price) as net_sales from sales as s
left join products as p
on s.product_id = p.product_id
join stores as st
on s.store_id = st.store_id
group by 1,2,3,4
order by 1,4,3)

select store_name, year_num,month_number, net_sales,
	sum(net_sales) over(partition by store_name order by year_num, month_number) as running_total
from monthly_total;
