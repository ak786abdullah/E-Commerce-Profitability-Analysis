-- What is the average profit margin by product category? Which categories are the most and least profitable, 
use e_commerce_profitability_analysis ;
create view vv_category_profitability as 
 select
	primary_category as category,
    round(SUM(gross_revenue),2) AS total_revenue,
    round(SUM(total_costs),2) as total_cost,
    round(sum(profit),2) as total_profit,
    round(sum(profit) / nullif(SUM(gross_revenue),0) *100 ,2) as profit_margin_pct,
    ROUND(count(case when returned='Yes' THEN order_id END) / COUNT(order_id) * 100,2) as return_rate_pct,
    ROUND(sum(product_cost) / SUM(gross_revenue) * 100,2) AS avg_product_cost_pct,
    ROUND(sum(shipping_cost) / SUM(gross_revenue)  *100,2) AS avg_shipping_cost_pct,
    ROUND(sum(discount_amount) / SUM(gross_revenue) *100,2) AS avg_discount_pct,
    case 
    when dense_rank() over (order by round(sum(profit) / nullif(SUM(gross_revenue),0) *100 ,2) desc) =1 then 'Highest_profit'
    when dense_rank() over (order by round(sum(profit) / nullif(SUM(gross_revenue),0) *100 ,2) asc) =1 then 'lowest_profit' else '--' end as performance_flag
from 
	orders 
group by 
	primary_category;
select * from vv_category_profitability ;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- and what is driving the difference (product cost, shipping, returns, or discounts)?
    SELECT 
		max(case when category ='Electronics' then avg_shipping_cost_pct end)  - max(case when category ='Books' then avg_shipping_cost_pct end) as shiping_cost_difference ,
        max(case when category ='Electronics' then avg_product_cost_pct end) - max(case when category ='Books' then avg_product_cost_pct end) as product_cost_difference ,
        max(case when category ='Electronics' then avg_discount_pct end) - max(case when category ='Books' then avg_discount_pct end) as discountcost_difference,
        max(case when category ='Electronics' then return_rate_pct end) - max(case when category ='Books' then return_rate_pct end) as return_rate_difference
	FROM 
		vv_category_profitability;
