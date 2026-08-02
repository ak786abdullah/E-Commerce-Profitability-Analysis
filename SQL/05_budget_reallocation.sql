-- Question: If the CEO asked you to cut 20% of the marketing budget, which platforms  would you recommend reducing spend on? Support your recommendation
-- with data.

WITH monthly_perf AS (
    SELECT platform, DATE(month) AS month, spend, roas
    FROM marketing_spend
)
SELECT
    platform,
    month,
    spend,
    roas,
    ROUND(
		SUM(spend) OVER (
        ORDER BY roas ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ),2
    ) AS cumulative_spend,
    ROUND(
        SUM(spend) OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / SUM(spend) OVER () * 100, 2
    ) AS cumulative_pct_of_budget
FROM monthly_perf
ORDER BY roas ASC;