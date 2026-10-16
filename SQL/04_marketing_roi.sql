-- Question :
-- Analyze the marketing spend data: Which advertising platform delivers the best ROAS (Return on Ad Spend)? Are there any platforms where the company is spending
-- money but not getting a positive return?

create view vv_Marketing_ROI_by_platform as
select 
	platform ,
	round(SUM(revenue_attributed),2) as total_revenue_attributed ,
    round(SUM(spend),2) as total_spend,
    round(SUM(revenue_attributed) / NULLIF(SUM(spend),0), 2) as Return_on_Ad_Spend,
    round(SUM(spend) / NULLIF(SUM(conversions),0), 2) as cost_per_acquisition ,
    round(SUM(spend) / NULLIF(SUM(clicks),0), 2) as cost_per_click
from 
	marketing_spend 
group by 
	platform;
    select * from vv_Marketing_ROI_by_platform ;
-- output : highest --> Tiktok ads with 24.02 Roas lowests --> Email Mrketing with Roas 4.81 
-- lowest Roas 4.81  so all platform giving positive returns  