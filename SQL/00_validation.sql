-- 00: Validation checks 
USE e_commerce_profitability_analysis;

-- 1. First Glance 
Select * FROM orders limit 10;


-- duplicate check:
-- 1. Orders: row_count must equal distinct_orders
SELECT COUNT(*) AS row_count, COUNT(DISTINCT order_id) AS distinct_orders FROM orders;
-- output --> row_count = distinct_orders --> No Duplicates 

-- 3. Marketing table totals 
SELECT COUNT(*) AS platform_months,
       ROUND(SUM(spend), 2) AS total_spend,
       ROUND(SUM(revenue_attributed), 2) AS attributed_revenue_total
FROM marketing_spend;

-- varification 1: is total cost column include returns and discount or not 
select sum(o.product_cost + o.shipping_cost + o.transaction_fee + o.platform_fee) , sum(o.total_costs) from orders o ;
-- output --> sum(o.product_cost + o.shipping_cost + o.transaction_fee + o.platform_fee) = sum(o.total_costs) from orders o
-- varified : total_costs = product_cost + shipping_cost + transaction_fee + platform_fee.(returns and discount not inclueded)

-- varification 2: is net revenue  column calculated as gross revenue - (discount + returns) 
select sum(gross_revenue -(discount_amount + refund_amount)) ,sum(net_revenue) from orders ;
-- output : sum(gross_revenue -(discount_amount + refund_amount)) = sum(net_revenue) 
-- varified : net_revenue = gross_revenue -(discount_amount + refund_amount)

-- varification 3: is profit column gross_profit or net profit 
SELECT
       sum(o.net_revenue - total_costs) AS calculated_net_profit,
       sum(o.profit) as profit_column
FROM orders o;
-- output --> calculated_net_profit = profit_column
-- varified : profit column is calculated from net revenue so it is net profit 

-- -- varification 4: net revenue recorded as  0  for returned orders ?
Select 
sum(case when returned = 'Yes' THEN 1 ELSE 0 end ) as returned_count ,
sum(case when returned = 'Yes' and net_revenue =0 THEN 1 ELSE 0 end ) as net_zero_returned_count 
FROM orders ;
-- output : returned_count = net_zero_returned_count
-- varified : net revenue recorded as  0  for each returned orders 

-- we do not need to recalculate the net revenue becouse our net profit is calculated as net revenue - total cost 
-- (if revenue is 0 it still calculate profit as negitive (loss)
