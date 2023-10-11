#1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
select  distinct market
from dim_customer
where  customer ='Atliq Exclusive' and region = 'APAC'
order by market;

#2.What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
#unique_products_2020,unique_products_2021,percentage_chg

with cte as(select count(distinct product_code) as unique_product_2020
from fact_sales_monthly
where fiscal_year = 2020),
cte2 as(select count(distinct product_code) as unique_product_2021
from fact_sales_monthly
where fiscal_year = 2021),
cte3 as(select ((unique_product_2021- unique_product_2020)*100/unique_product_2020) as percenatge_cheg
from cte2 
join cte)
select unique_product_2020,unique_product_2021,round(percenatge_cheg,2) percenatge_cheg
from cte,cte2,cte3;

#3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains
#2 fields, segment , product_count

select count(distinct product_code) as product_count, segment
from dim_product
group by segment
order by product_count desc;

#4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
# segment, product_count_2020, product_count_2021,difference.

With cte as(select count(distinct fs.product_code) as product_count_2020,segment
from fact_sales_monthly fs join dim_product dp
on fs.product_code = dp.product_code
where fiscal_year = 2020
group by segment),
cte2 as(select count(distinct fs.product_code) as product_count_2021,segment
from fact_sales_monthly fs join dim_product dp
on fs.product_code = dp.product_code
where fiscal_year = 2021
group by segment)
select cte.segment,product_count_2020,product_count_2021,(product_count_2021- product_count_2020) as differnce,segment
from cte join cte2 using(segment)
order by differnce desc;

#5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
#product_code,  product, manufacturing_cost
select dp.product_code,product, manufacturing_cost
from dim_product dp join fact_manufacturing_cost fm
on dp.product_code= fm.product_code
where manufacturing_cost in (( select max(manufacturing_cost) from fact_manufacturing_cost),
(select min(manufacturing_cost) from fact_manufacturing_cost))
 order by manufacturing_cost desc;
 
 #6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
#customer_code, customer,average_discount_percentage

Select dm.customer_code,dm.customer,avg(pre_invoice_discount_pct) as avg_discount_pct
from fact_pre_invoice_deductions  fd join dim_customer dm
on fd.customer_code = dm.customer_code
where fiscal_year= 2021 and market = 'india'
group by 1,2
order by  avg_discount_pct desc
limit 5;

# 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
#The final report contains these columns:
#Month,Year,Gross sales Amount

select monthname(s.date) as month, s.fiscal_year as year, round(sum(gross_price*sold_quantity /100000),2) as gross_sales_mln
from fact_sales_monthly s join dim_customer dm
using(customer_code) join fact_gross_price
using(product_code,fiscal_year)
where customer = 'Atliq Exclusive'
group by month,year
order by 2,3 desc;

#8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
#Quarter, total_sold_quantity

select sum(sold_quantity) as total_sold_quantity, concat('Qtr', "" ,quarter(date + interval 4 month))
from fact_sales_monthly
where fiscal_year = 2020
group by 2
order by  1 desc;

# 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
# Channel, gross_sales_mln, percentage

with cte as(select distinct channel, round(sum(gross_price*sold_quantity/100000),2) as gross_sold_mln
from fact_sales_monthly s join fact_gross_price p
using(product_code,fiscal_year) join dim_customer dc
using(customer_code)
where s.fiscal_year = 2021
group by 1),
cte2 as(select round(sum(gross_sold_mln),2) tgs
from cte)
select channel,gross_sold_mln, round(gross_sold_mln*100/tgs,2) percentage
from cte,cte2
order by gross_sold_mln desc;

#10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields, division, product_code,product, ,total_sold_quantity,rank_order

with tem_table as
(select division, p.product_code, concat(product, "(",variant,")") as product, sum(sold_quantity) as total_sold_qunatity,
rank() over (partition by division  order by sum(sold_quantity) desc) as rank_order
from fact_sales_monthly f join dim_product p
using(product_code)
where fiscal_year = 2021
group by 1,2,3)
select *
from tem_table
where rank_order <=3;