-- What is the average profit margin by product category? Which categories are the most and least profitable?
use e_commerce_profitability_analysis ;

create view vv_category_profitability as 
 select
	primary_category as category,
    round(SUM(gross_revenue),2) AS total_gross_revenue,
    round(SUM(net_revenue),2) AS total_net_revenue, -- pre_calculated : net_revenue = gross_revenue -(discount_amount + refund_amount) CHECKED
    round(SUM(total_costs),2) as total_cost, -- pre_calculated : total_costs = product_cost + shipping_cost + transaction_fee + platform_fee. CHECKED
    round(sum(gross_revenue -total_costs),2) as total_gross_profit,
    round(sum(profit),2) as total_net_profit, -- pre_calculated : profit = net_revenue - total_costs (CHECKED) 
    round(sum(profit) / nullif(SUM(net_revenue),0) *100 ,2) as net_profit_margin_pct,
    ROUND(sum(case when returned='Yes' THEN 1 ELSE 0 END) / COUNT(order_id) * 100,2) as return_rate_pct, -- no duplicate checked 
    ROUND(sum(product_cost) / nullif(SUM(net_revenue),0) * 100,2) AS product_cost_pct,
    ROUND(sum(shipping_cost) / nullif(SUM(net_revenue),0) * 100,2) AS shipping_cost_pct,
    ROUND(sum(discount_amount) / nullif(SUM(gross_revenue),2) * 100,2) AS discount_pct,
    case 
    when dense_rank() over (order by round(sum(profit) / nullif(SUM(net_revenue),0) *100 ,2) desc) =1 then 'Highest_profit'
    when dense_rank() over (order by round(sum(profit) / nullif(SUM(net_revenue),0) *100 ,2) asc) =1 then 'lowest_profit' else '--' end as performance_flag
from 
	orders 
group by 
	primary_category;
select * from vv_category_profitability ;

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- What is driving the difference (product cost, shipping, returns, or discounts)? 
   SELECT
  MAX(CASE WHEN performance_flag = 'Highest_profit' THEN category END) AS highest_category,
  MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN category END) AS lowest_category,
  ROUND(MAX(CASE WHEN performance_flag = 'Highest_profit' THEN net_profit_margin_pct END)
      - MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN net_profit_margin_pct END), 2) AS net_margin_gap_pts,
  ROUND(MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN shipping_cost_pct END)
      - MAX(CASE WHEN performance_flag = 'Highest_profit' THEN shipping_cost_pct END), 2) AS shipping_pts,
  ROUND(MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN product_cost_pct END)
      - MAX(CASE WHEN performance_flag = 'Highest_profit' THEN product_cost_pct END), 2) AS product_cost_pts,
  ROUND(MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN return_rate_pct END)
      - MAX(CASE WHEN performance_flag = 'Highest_profit' THEN return_rate_pct END), 2) AS return_rate_diff_pts,
  ROUND(MAX(CASE WHEN performance_flag = 'Lowest_profit'  THEN discount_pct END)
      - MAX(CASE WHEN performance_flag = 'Highest_profit' THEN discount_pct END), 2) AS discount_pts
FROM vv_category_profitability;
-- output shiping_pts 17.32(highest) 