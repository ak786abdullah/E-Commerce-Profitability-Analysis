# BrightCart E-Commerce Profitability Analysis

A full-funnel profitability audit for a multi-channel e-commerce retailer: from raw CSVs to recommendation-first findings and a stakeholder slide deck.

> **Note:** BrightCart is a fictional retailer used in a practice project brief from Analyst Builder. The business scenario and dataset are provided by that platform; the data cleaning, SQL modeling, profit-formula correction, findings and presentation below are original work.


## The Business Problem

BrightCart sells across 8 product categories through four channels: website, mobile app, third-party marketplace, and social commerce. Over a 24-month period the company generated about $278K in gross revenue (across 8 categories), but net margins were shrinking and leadership couldn't say why. This project answers five questions a CEO would actually ask:

1. Which product categories are most and least profitable, and what drives the difference?
2. Which sales channel delivers the best profit per order after fees?
3. How much revenue is lost to returns, by category and channel?
4. Which marketing platform delivers the best ROAS, and which one is burning cash?
5. If we cut 20% of the marketing budget, exactly which platforms and months should go?

## Tech Stack

| Stage | Tool | Why |
|---|---|---|
| Data cleaning & QA | Python (Pandas, Matplotlib) | Fast to profile, visualize outliers, and iterate on cleaning rules |
| Data warehousing | MySQL (loaded via SQLAlchemy) | Set-based, multi-dimensional aggregation is what SQL is built for |
| Analysis | SQL (views, window functions, conditional aggregation) | Reusable, auditable logic per business question |
| Presentation | Slide deck (PDF) | Recommendation-first format for a non-technical stakeholder |

## Methodology

1. **Extract:** load the three raw CSVs (orders, product catalog, marketing spend).
2. **Clean & validate in Python:** reusable functions check data types, duplicates, missing values, IQR-based outliers, and categorical consistency before anything reaches SQL.
3. **Define cost and profit explicitly:** rather than trusting a pre-built column, `total_costs` and `profit` are derived directly so every downstream number is traceable:

```python
order_data['total_costs'] = (
    order_data['product_cost']
    + order_data['shipping_cost']
    + order_data['transaction_fee']
    + order_data['platform_fee']
)
order_data['profit'] = order_data['gross_revenue'] - order_data['total_costs']
```

4. **Load to MySQL:** SQLAlchemy + python-dotenv push cleaned DataFrames into tables without hardcoding credentials.
5. **Analyze in SQL:** five views, each answering one business question, using window functions (`DENSE_RANK`, cumulative `SUM`) and conditional aggregation (`CASE WHEN` inside `SUM`/`COUNT`).
6. **Present:** findings translated into a six-slide, recommendation-first deck (see [Presentation](#presentation)).

## Key Findings

### 1. Category profitability

Electronics is the most profitable category (41.54% margin); Books is the least (25.95%), a gap of about 15.6 percentage points. Shipping cost is the main driver: it takes 14.44 percentage points more of revenue in Books than in Electronics (27.94% vs 13.50%), which accounts for about 93% of the 15.59-point gap. Product cost adds 1.96 points, partly offset by Electronics paying 0.81 points more in transaction and platform fees. Return rates (8.61% Electronics vs 8.37% Books) do not explain the gap.

| Category | Profit margin |
|---|---|
| Electronics | 41.54% |
| Food & Beverage | 37.44% |
| Toys | 36.52% |
| Home & Kitchen | 36.30% |
| Sports | 33.96% |
| Clothing | 33.07% |
| Beauty | 27.75% |
| Books | 25.95% |

The mean margin across the eight categories is 34.1% (a simple average of category margins). Weighted by revenue, the overall margin is 35.25% ($97,985 profit on $277,969 revenue).

**Recommendation:** implement a minimum order value for free shipping on Books to protect net margins.

### 2. Channel profitability

Mobile App and Website are effectively tied at the top (38.95% vs 38.94% margin; $54.71 vs $54.46 profit per order). Social Commerce has the highest return rate (9.14%) and a 29.83% margin. Marketplace has the lowest margin and profit per order even though it has the lowest return rate (6.44%), so returns do not explain its weakness. Average order values are similar across channels ($134 to $140).

| Channel | Avg order value | Profit margin | Return rate | Profit per order |
|---|---|---|---|---|
| Mobile App | $140.45 | 38.95% | 7.30% | $54.71 |
| Website | $139.83 | 38.94% | 7.04% | $54.46 |
| Social Commerce | $134.25 | 29.83% | 9.14% | $40.04 |
| Marketplace | $137.55 | 25.30% | 6.44% | $34.79 |

### 3. Returns

**$22,206.76** in revenue was lost to returns overall (7.99% of gross revenue; 144 of 2,000 orders were returned). Social Commerce has the highest return rate overall (9.14%), peaking at 13.33% in Clothing, though it is low in other categories (3.70% in Beauty). Marketplace has the lowest overall return rate but the widest spread across categories, from 1.61% in Food & Beverage to 11.67% in Clothing; Mobile App is the most consistent (4.76% to 9.47%). Each of the 32 channel-category combinations covers only a few dozen orders, so single-cell differences are indicative rather than conclusive. The table shows the eight highest and two lowest combinations.

| Channel & category | Return rate |
|---|---|
| Social Commerce, Clothing | 13.33% |
| Social Commerce, Home & Kitchen | 13.04% |
| Social Commerce, Books | 13.04% |
| Social Commerce, Food & Beverage | 12.50% |
| Marketplace, Clothing | 11.67% |
| Website, Electronics | 9.90% |
| Mobile App, Sports | 9.47% |
| Website, Books | 9.09% |
| Marketplace, Sports | 1.92% |
| Marketplace, Food & Beverage | 1.61% |

### 4. Marketing ROAS

TikTok Ads leads at 24.02x ROAS with the lowest cost per acquisition ($3.06). Email Marketing is the least efficient at 4.81x ROAS, with a cost per acquisition of $17.86 (about 5.8x TikTok's) and a cost per click of $0.94 (about 6x TikTok's). No platform has an aggregate ROAS below 1.0x; the only platform-month below 1.0x is Email in December 2025 (0.67x).

| Platform | ROAS | Cost per acquisition | Cost per click |
|---|---|---|---|
| TikTok Ads | 24.02x | $3.06 | $0.15 |
| Influencer Campaigns | 22.70x | $3.39 | $0.17 |
| Instagram Ads | 15.73x | $4.70 | $0.21 |
| Google Ads | 14.38x | $4.72 | $0.25 |
| Facebook Ads | 11.45x | $6.27 | $0.32 |
| Email Marketing | 4.81x | $17.86 | $0.94 |

### 5. Budget reallocation

The marketing table holds 144 platform-months (6 platforms × 24 months) and $503,506.14 in total spend, so a 20% cut is about $100,701. A cumulative-spend window function ranks platform-months by ROAS (lowest first). The **34 lowest-ROAS platform-months** are the smallest set that reaches the target, totaling **$104,532.02 (20.76% of budget)**.

| Platform | Platform-months cut | Spend cut | Share of the cut | Share of that platform's spend |
|---|---|---|---|---|
| Facebook Ads | 7 | $36,589 | 35.0% | 34.4% |
| Google Ads | 4 | $20,920 | 20.0% | 13.7% |
| Influencer | 4 | $16,985 | 16.2% | 17.4% |
| Email Marketing | 15 | $16,927 | 16.2% | 69.2% |
| Instagram Ads | 2 | $8,696 | 8.3% | 13.3% |
| TikTok Ads | 2 | $4,414 | 4.2% | 7.7% |

- Email has the most platform-months in the cut (15) and the weakest single month (0.67x in December 2025), and about 69% of its budget is cut. But Email is only 4.9% of total spend, so most of the dollars come from Facebook and Google (55% combined).
- The selected platform-months range from 0.67x to 6.60x ROAS. The cutoff is set by the 20% target, not by a break-even threshold, and only one platform-month is below 1.0x.
- Adding the next platform-month (TikTok, July 2025, 6.63x, $3,326.90) would bring the total to $107,858.92 (21.42% of budget).

**Recommendation:** suspend the identified low-performing platform-months and redeploy that spend toward higher-performing campaigns.

## Methodology Notes

- `profit` is calculated explicitly as `gross_revenue − (product_cost + shipping_cost + transaction_fee + platform_fee)`, not pulled from a pre-built column, so every figure above is auditable back to raw data. Marketing spend is analyzed separately through ROAS and is not deducted from profit.
- Category and channel margins are revenue-weighted (`SUM(profit) / SUM(gross_revenue)`), the standard way to report a blended margin across orders of different sizes. The 34.1% figure above is the exception: a simple mean of the eight category margins.
- Returned orders still contribute their full revenue and profit to the category and channel views. The $22,206.76 return-revenue figure is reported separately rather than subtracted from margin. Netting it out is the next planned refinement.
- ROAS is last-touch (no multi-touch attribution). It is calculated as attributed revenue ÷ spend from the separate `marketing_spend` table, so it is best read as a relative ranking across platforms; it is not reconciled to the revenue in the `orders` table.

## Presentation

The deck (`presentation/BrightCart_Profitability_Analysis.pdf`) walks through the findings in recommendation-first order:

1. Title: E-Commerce Profitability Analysis
2. Profit Margin Audit: category margins and the shipping-cost driver
3. Sales Channel Profitability Analysis: profit per order by channel
4. Return Rate Analysis: $22,206.76 lost to returns, by channel and category
5. ROAS Performance Audit: platforms ranked by ROAS and CPA
6. Budget Optimization Strategy: the 34 lowest-ROAS platform-months behind the ~20% budget cut

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

1. Run `notebooks/01_data_cleaning_and_quality_checks.ipynb` to clean the raw CSVs and build `total_costs` / `profit`.
2. Run `src/load_to_mysql.py` to load the cleaned tables into MySQL.
3. Run the scripts in `sql/` (in order) to build the five analysis views.
4. Query each view to reproduce the findings above.

## Next Steps

- Net returned-order revenue and profit out of the category and channel views for a fully loss-adjusted margin figure
- Automate the ETL step with a scheduler so the views stay current monthly
- Build an interactive Power BI or Tableau layer on top of the MySQL views for stakeholders who want to self-serve
- Extend the marketing model to account for multi-touch attribution instead of last-touch ROAS

## Author

**Muhammad Abdullah**: Data & BI Analyst | BSc Mathematics
GitHub: [ak786abdullah](https://github.com/ak786abdullah)
