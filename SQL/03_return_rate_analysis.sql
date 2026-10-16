-- Question : What is the return rate by category and channel?
-- note: there is no duplicate (all order_id are uniques) checked

create view vv_return_rate_by_category_channel as
SELECT 
	channel,
    primary_category as category,
    ROUND(count(case when returned='Yes' THEN order_id END) / COUNT(order_id) * 100 ,2) as return_rate_pct 
FROM 
	orders
GROUP BY 
	channel ,
    primary_category;
    
  -- Estimate how much total revenue was lost to returns over the analysis period.
select 
	COUNT(order_id) AS orders,
	SUM(returned='Yes') AS returned_orders,
	sum(case when returned = 'Yes' then gross_revenue  else 0 end ) as lost_revenue ,
    ROUND(SUM(CASE WHEN returned='Yes' THEN gross_revenue ELSE 0 END) / SUM(gross_revenue)*100,2) AS lost_revenue_pct
from
	orders ;
    
SELECT * FROM vv_return_rate_by_category_channel ;
