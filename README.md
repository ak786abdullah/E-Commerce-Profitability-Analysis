# BrightCart E-Commerce Profitability Analysis

**A full-funnel profitability audit for a multi-channel e-commerce retailer — from raw CSVs to boardroom-ready recommendations.**

> Note: BrightCart is a fictional retailer used in a practice project brief from [Analyst Builder](https://www.analystbuilder.com/projects/e-commerce-profitability-analysis-KvrTi). The business scenario and dataset are provided by that platform; the data cleaning, SQL modeling, profit-formula correction, and findings below are original work.

**Time investment:** ~20 hours across 10 days (2 hours/day), completed alongside other work.

## The Business Problem

BrightCart sells across 8 product categories through four channels — website, mobile app, third-party marketplace, and social commerce. Over a 24-month period the company generated $1M+ in gross revenue, but net margins were shrinking and leadership couldn't say why. This project answers five questions a CEO would actually ask:

1. Which product categories are most/least profitable, and what's driving the difference?
3. Which sales channel delivers the best profit per order after fees?
4. How much revenue is lost to returns, by category and channel?
5. Which marketing platform delivers the best ROAS — and which one is burning cash?
6. If we cut 20% of the marketing budget, exactly which platforms and months should go?

## Tech Stack

| Stage | Tool | Why |
|---|---|---|
| Data cleaning & QA | Python (Pandas, Matplotlib) | Fast to profile, visualize outliers, and iterate on cleaning rules |
| Data warehousing | MySQL (loaded via SQLAlchemy) | Set-based, multi-dimensional aggregation is what SQL is built for |
| Analysis | SQL (views, window functions, conditional aggregation) | Reusable, auditable logic per business question |
| Presentation | Slide deck (PDF) | Recommendation-first format for a non-technical stakeholder |

## Methodology

1. **Extract** — load the three raw CSVs (orders, product catalog, marketing spend).
2. **Clean & validate in Python** — reusable functions check data types, duplicates, missing values, IQR-based outliers, and categorical consistency before anything hits SQL.
3. **Define cost and profit explicitly** — rather than trusting a pre-built column, `total_costs` and `profit` are derived directly so every downstream number is traceable:

```python
order_data['total_costs'] = (
    order_data['product_cost']
    + order_data['shipping_cost']
    + order_data['transaction_fee']
    + order_data['platform_fee']
)
order_data['profit'] = order_data['gross_revenue'] - order_data['total_costs']
```

4. **Load to MySQL** — `SQLAlchemy` + `python-dotenv` push cleaned DataFrames into tables without hardcoding credentials.
5. **Analyze in SQL** — five views, each answering one business question, using window functions (`DENSE_RANK`, cumulative `SUM`) and conditional aggregation (`CASE WHEN` inside `SUM`/`COUNT`).
6. **Present** — findings translated into a recommendation-first slide deck.

<details>
<summary>Example — outlier detection used during cleaning</summary>

```python
def show_outliers_iqr(df, column):
    Q1 = df[column].quantile(0.25)
    Q3 = df[column].quantile(0.75)
    IQR = Q3 - Q1
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    return df[(df[column] < lower_bound) | (df[column] > upper_bound)].sort_values(by=column, ascending=False)
```
</details>

<details>
<summary>Example — cumulative-spend window function for the budget-cut question</summary>

```sql
SELECT
    platform, month, spend, roas,
    SUM(spend) OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_spend,
    SUM(spend) OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
        / SUM(spend) OVER () * 100 AS cumulative_pct_of_budget
FROM monthly_perf
ORDER BY roas ASC;
```

This ranks every platform-month by ROAS and tracks exactly how much spend accumulates as the worst performers are removed — turning a ranked list into an actionable cutoff point.
</details>

## Key Findings

**Category profitability** — Electronics is the most profitable category (41.54% margin); Books the least (25.95%). Shipping cost is the single largest driver of that ~15.6-point gap.

**Channel profitability** — Mobile App delivers the best profit per order ($54.71, 38.95% margin); Marketplace the worst ($34.79, 25.3% margin), largely due to platform fees rather than returns. Website stays close behind Mobile App on profit per order ($54.46) on the strength of a $139.83 average order value.

**Returns** — $22,206.76 in revenue lost to returns overall. Social Commerce has the highest return rates (up to 13.33% in Clothing); Marketplace is the most stable (as low as 1.61% in Food & Beverage).

**Marketing ROAS** — TikTok Ads leads at 24.02x ROAS with a $3.06 CPA. Email Marketing is the weakest at 4.81x ROAS with a $17.86 CPA.

**Budget reallocation** — A cumulative-spend window function identifies the exact 34 platform-month campaigns to cut, freeing $107,858.92 (20% of total budget) — concentrated in Email Marketing, which bottomed out at 0.67x ROAS in December 2025.

## Methodology Notes

- `profit` is calculated explicitly as `gross_revenue − (product_cost + shipping_cost + transaction_fee + platform_fee)`, not pulled from a pre-built column, so every figure above is fully auditable back to raw data.
- Category and channel margins are revenue-weighted (`SUM(profit) / SUM(gross_revenue)`), not a simple average of each order's individual margin — the standard way to report a blended margin across orders of different sizes.
- Returned orders currently still contribute their full revenue and profit to the category/channel views; the $22,206.76 return-revenue figure is reported separately rather than subtracted from margin. Netting this out is the next planned refinement (see below).

## Repository Structure

```
brightcart-profitability-analysis/
├── README.md
├── requirements.txt
├── .env.example
├── .gitignore
├── data/
│   ├── raw/
│   │   ├── orders.csv
│   │   ├── products.csv
│   │   └── marketing_spend.csv
│   └── processed/
├── notebooks/
│   └── 01_data_cleaning_and_quality_checks.ipynb
├── src/
│   ├── data_quality.py
│   └── load_to_mysql.py
├── sql/
│   ├── 01_category_profitability.sql
│   ├── 02_channel_analysis.sql
│   ├── 03_return_rate_analysis.sql
│   ├── 04_marketing_roi.sql
│   └── 05_budget_reallocation.sql
└── presentation/
    └── BrightCart_Profitability_Analysis.pdf
```

## How to Reproduce

```bash
git clone https://github.com/<your-username>/brightcart-profitability-analysis.git
cd brightcart-profitability-analysis
python -m venv venv && source venv/bin/activate    # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env   # add your MySQL password
```

1. Run `notebooks/01_data_cleaning_and_quality_checks.ipynb` to clean the raw CSVs and build `total_costs`/`profit`.
2. Run `src/load_to_mysql.py` to load the cleaned tables into MySQL.
3. Run the scripts in `sql/` (in order) to build the five analysis views.
4. Query each view to reproduce the findings above.

## Next Steps

- Net returned-order revenue and profit out of the category/channel views for a fully loss-adjusted margin figure
- Automate the ETL step with a scheduler so the views stay current monthly
- Build an interactive Power BI or Tableau layer on top of the MySQL views for stakeholders who want to self-serve
- Extend the marketing model to account for multi-touch attribution instead of last-touch ROAS

## Author

**Muhammad Abdullah** — Data & BI Analyst | BSc Mathematics
GitHub: [ak786abdullah](https://github.com/ak786abdullah)

## License

MIT
