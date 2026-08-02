-- Question : What is the return rate by category and channel?
alter view vv_return_rate_by_category_channel as
SELECT 
	channel,
    primary_category as category,
    ROUND(count(case when returned='Yes' THEN order_id END) / COUNT(order_id) * 100 ,2) as return_rate
FROM 
	orders
GROUP BY 
	channel ,
    primary_category;
    
  -- Estimate how much total revenue was lost to returns over the analysis period.
select 
	sum(case when returned = 'Yes' then gross_revenue else 0 end ) as lost_revenue
from
	orders ;
    
SELECT * FROM vv_return_rate_by_category_channel ;