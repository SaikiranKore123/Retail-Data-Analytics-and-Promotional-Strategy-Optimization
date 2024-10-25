SELECT * FROM retail_events_db.dim_campaigns;
SELECT * FROM retail_events_db.dim_products;
SELECT * FROM retail_events_db.dim_stores;
SELECT * FROM retail_events_db.fact_events;

-- 1. Provide a list of products with a base price greater than 500 and 
-- that are featured in promo type of 'BOGOF' (Buy One Get One Free). 
-- This information will help us identify high-value products that are 
-- currently being heavily discounted, which can be useful for evaluating our 
-- pricing and promotion strategies. 

select p.product_code,p.product_name,e.promo_type,e.base_price from retail_events_db.fact_events e
join dim_products p
on e.product_code = p.product_code
where base_price > 500 and promo_type = 'BOGOF';


-- 2. Generate a report that provides an overview of the number of stores in each city. 
-- The results will be sorted in descending order of store counts, allowing us to identify 
-- the cities with the highest store presence. 
-- The report includes two essential fields: city and store count, which will assist 
-- in optimizing our retail operations.

SELECT city,count(store_id) as NO_of_stores_in_city FROM retail_events_db.dim_stores
group by city
order by NO_of_stores_in_city desc;

-- 3. Generate a report that displays each campaign along with the total revenue 
-- generated before and after the campaign? 
-- The report includes three key fields: campaign_name, total_revenue (before_promotion), 
-- total_revenue(after_promotion). This report should help in evaluating the financial impact 
-- of our promotional campaigns. (Display the values in millions)

SELECT * FROM retail_events_db.dim_campaigns;
SELECT * FROM retail_events_db.fact_events e;

alter table fact_events rename column `quantity_sold(before_promo)` to quantity_sold_before_promo;
alter table fact_events rename column `quantity_sold(after_promo)` to quantity_sold_after_promo;

SELECT c.campaign_name,
	   sum(quantity_sold_before_promo * base_price) as Total_revenue_before_promo,
       sum(quantity_sold_after_promo * base_price) as Total_revenue_after_promo
FROM retail_events_db.dim_campaigns c
join fact_events e
on c.campaign_id = e.campaign_id
group by c.campaign_id;


-- 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for 
-- each category during the Diwali campaign. Additionally, provide rankings for the 
-- categories based on their ISU%. The report will include three key fields: category, isu%, 
-- and rank order. This information will assist in assessing the category-wise success 
-- and impact of the Diwali campaign on incremental sales. 
-- Note: ISU% (Incremental Sold Quantity Percentage) is calculated as the percentage 
-- increase/decrease in quantity sold (after promo) compared to quantity sold (before promo)

SELECT * FROM retail_events_db.dim_campaigns;
SELECT * FROM retail_events_db.fact_events e;

with Incremental_sales as(
SELECT p.category,
 ((sum(e.quantity_sold_after_promo)-sum(e.quantity_sold_before_promo))/sum(e.quantity_sold_before_promo))*100
as Incremental_Sold_Quantity_Percentage
FROM fact_events e
join dim_products p
on p.product_code = e.product_code
join dim_campaigns c
on e.campaign_id = c.campaign_id
where c.campaign_name = "Diwali"
group by p.category) 

select category,Incremental_Sold_Quantity_Percentage,
		rank() over( order by Incremental_Sold_Quantity_Percentage desc ) as rn
from Incremental_sales;

-- 5.Create a report featuring the Top 5 products, ranked by 
-- Incremental Revenue Percentage (IR%), across all campaigns. 
-- The report will provide essential information including product name,
-- category, and ir%. This analysis helps identify the most successful products 
-- in terms of incremental revenue across our campaigns, assisting in product optimization.

with Incremental_revenue as(
SELECT p.product_name, p.category,
 ((sum(e.quantity_sold_after_promo)-sum(e.quantity_sold_before_promo))/sum(e.quantity_sold_before_promo))*100
as Incremental_Revenue_Percentage
FROM fact_events e
join dim_products p
on p.product_code = e.product_code
join dim_campaigns c
on e.campaign_id = c.campaign_id
group by p.product_name, p.category)

select  *,rank() over( order by Incremental_Revenue_Percentage desc ) as rn from Incremental_revenue
limit 5;

