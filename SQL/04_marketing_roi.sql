-- Question :
-- Analyze the marketing spend data: Which advertising platform delivers the best ROAS (Return on Ad Spend)? Are there any platforms where the company is spending
-- money but not getting a positive return?

alter view vv_Marketing_ROI_by_platform as
select 
	platform ,
    round(SUM(revenue_attributed) / NULLIF(SUM(spend),0), 2) as return_on_ad ,
    round(SUM(spend) / NULLIF(SUM(conversions),0), 2) as cost_per_acquisition ,
    round(SUM(spend) / NULLIF(SUM(clicks),0), 2) as cost_per_click
from 
	marketing_spend 
group by 
	platform;
    select * from vv_Marketing_ROI_by_platform ;
