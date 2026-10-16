-- Question: If the CEO asked you to cut 20% of the marketing budget, which platforms  would you recommend reducing spend on? Support your recommendation
-- with data.
with ranked_spend as (
SELECT
    platform,
    month,
    spend,
    roas as Return_on_Ad_Spend,
    cpa as cost_per_acquisition,
    cpc as cost_per_click ,
    ROUND(
		SUM(spend) OVER (
        ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),2
    ) AS cumulative_spend,
    ROUND(
        SUM(spend) OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / SUM(spend) OVER () * 100, 2
    ) AS cumulative_pct_of_budget
FROM marketing_spend
ORDER BY roas ASC
) 
SELECT
    platform,
    month,
    spend,
	Return_on_Ad_Spend,
	cost_per_acquisition,
	cost_per_click,
    cumulative_spend,
    cumulative_pct_of_budget
FROM 
	ranked_spend
WHERE 
	cumulative_pct_of_budget <21 