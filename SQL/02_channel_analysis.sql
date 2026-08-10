-- QUESTION: 
-- How does profitability differ across sales channels (Website, Mobile App, Marketplace, Social Commerce)? Which channel has the best and worst profit per order after
--  accounting for platform fees?
create view vv_channel_analysis as 
SELECT 
	channel,
	ROUND(SUM(gross_revenue) / COUNT(DISTINCT order_id), 2) AS average_order_value,
    round(sum(profit) / nullif(SUM(gross_revenue),0) *100 ,2) as profit_margin,
    ROUND(count(case when returned='Yes' THEN order_id END) / COUNT(order_id) * 100 ,2) as return_rate,
    ROUND(sum(profit)/ COUNT(DISTINCT order_id), 2) AS profit_per_order,
    case 
    when dense_rank() over (order by ROUND(sum(profit)/ COUNT(DISTINCT order_id), 2) desc) =1 then 'Highest_profit'
    when dense_rank() over (order by ROUND(sum(profit)/ COUNT(DISTINCT order_id), 2) asc) =1 then 'lowest_profit' else '--' end as performance_flag
FROM 
	orders
GROUP BY 
	channel;
 select * from vv_channel_analysis ;
