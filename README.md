# BrightCart E-Commerce Profitability & Marketing ROI Audit (v2 ELT Architecture)

A full-funnel financial and marketing profitability audit for a multi-channel e-commerce retailer: transitioning from an unadjusted gross-margin pipeline (v1) to an audited, net-realized MySQL ELT architecture (v2) with executive recommendations.

> **Note:** BrightCart is a fictional retailer from an Analyst Builder practice brief. The business scenario and raw datasets are provided by that platform; the SQL reconciliation audit, v1-to-v2 accounting correction, window-function modeling, and executive findings below are original work.

---

## 1. The Business Problem

BrightCart sells products across **8 categories** through **4 sales channels** (`Website`, `Mobile App`, `Marketplace`, and `Social Commerce`). Over a 24-month period (`2024-01` to `2025-12`), the company generated **$277,969.13 in gross revenue** across **2,000 orders** and spent **$503,506.14** on marketing across **6 advertising platforms**, but net margins were shrinking and leadership needed to know why.

This project answers five questions from the CEO:
1. **Category Profitability:** What is the average profit margin by product category? Which categories are the most and least profitable, and what is driving the difference (product cost, shipping, returns, or discounts)?
2. **Channel Unit Economics:** How does profitability differ across sales channels? Which channel delivers the best and worst profit per order after accounting for platform fees?
3. **Return Rate & Revenue Loss:** What is the return rate by category and channel, and how much total revenue was lost to returns over the 24-month period?
4. **Marketing Efficiency (ROAS):** Which advertising platform delivers the best Return on Ad Spend (ROAS), and are any platforms burning cash without a positive return?
5. **20% Budget Cut Strategy:** If the CEO cuts 20% of the marketing budget, exactly which platforms and months should be reduced?
> **Data note:** `marketing_spend` is a separate dataset from `orders` and does not reconcile with it. Attributed revenue ($8,146,615.20) is about 29x the gross order revenue ($277,969.13), and marketing spend ($503,506.14) is about 2.1x net order revenue ($236,318.37). The marketing figures (ROAS, CPA, CPC and the 20% budget cut) are therefore used only to rank platforms and platform-months against each other. They are not compared with, or subtracted from, order profit.

---

## 2. Why I Upgraded the Project: v1 (ETL) vs. v2 (Audited ELT)

When I initially built this project (**v1**), I loaded the CSVs into Python, defined `total_costs = product_cost + shipping_cost + transaction_fee + platform_fee`, and overwrote the `profit` column as `gross_revenue - total_costs` before loading the tables to MySQL. 

While reviewing my v1 outputs, I realized that **overwriting `profit` with `gross_revenue - total_costs` ignored discounts and customer refunds**, forcing me to add footnotes that returns and discounts were excluded from category and channel margins.

To fix this in **v2**, I switched to a **MySQL ELT (Extract, Load, Transform)** architecture. I loaded the raw CSVs directly into MySQL first and wrote a dedicated SQL reconciliation script (`00_validation_checks.sql`) to audit the native accounting logic before building any analytical views.

### What the SQL Validation Audit Revealed (`00_validation_checks.sql`)
* **Grain Integrity:** `COUNT(*) = COUNT(DISTINCT order_id)` (**2,000 unique orders**, zero duplicates).
* **Verified Cost Rollup:** `SUM(product_cost + shipping_cost + transaction_fee + platform_fee) = SUM(total_costs)` (**$179,984.54**). Discounts and refunds are not inside `total_costs`.
* **Verified Net Revenue Formula:** `SUM(gross_revenue - (discount_amount + refund_amount)) = SUM(net_revenue)` (**$236,318.37**).
* **Zeroed Net Revenue on Returns:** Every returned order (`returned = 'Yes'`, **144 orders**) has `net_revenue = 0`.
* **True Net Profit Built-In:** `SUM(net_revenue - total_costs) = SUM(profit)` (**$56,333.83**). When an order is returned, `net_revenue` drops to `$0`, so `profit` automatically records `-total_costs` (capturing the sunk fulfillment, product, and fee losses).

### Impact of the v1-to-v2 Methodology Upgrade

| Metric | v1 Approach (Unadjusted Gross) | v2 Approach (Audited Net) | Analytical Difference |
| :--- | :---: | :---: | :--- |
| **Revenue Basis** | $277,969.13 (`gross_revenue`) | $236,318.37 (`net_revenue`) | -$41,650.76 (discounts + refunds netted out) |
| **Total Profit** | $97,984.59 (`gross_profit`) | $56,333.83 (`net_profit`) | **v1 overstated total profit by $41,650.76 (42.51%)** |
| **Revenue-Weighted Margin** | 35.25% | **23.84%** | -11.41 percentage points |
| **Mean Category Margin** | 34.10% | **22.53%** | -11.57 percentage points |
| **Category Margin Gap** | 15.59 pts (41.54% vs. 25.95%) | **19.19 pts (31.13% vs. 11.94%)** | True cost drag on `Books` is 3.60 pts wider |
| **Mobile App vs. Website** | Tied ($54.71 vs. $54.46/order) | **$36.32 vs. $31.60/order** | **Mobile App clearly leads by $4.72/order (+2.75% margin)** |

---

## 3. Tech Stack & Architecture

| Stage | Tool | Purpose |
| :--- | :--- | :--- |
| **1. Extract & Load** | MySQL (Local Database Import) | Direct ingestion of raw CSVs (`orders.csv`, `products.csv`, `marketing_spend.csv`) into `e_commerce_profitability_analysis` without destructive pre-overwrites |
| **2. Data QA & Reconciliation** | MySQL (`00_validation_checks.sql`) | Primary-key uniqueness checks, cost-component verification, and gross-to-net revenue/profit accounting validation |
| **3. Analytical Modeling** | MySQL Views, CTEs & Window Functions | Reusable SQL views (`vv_category_profitability`, `vv_channel_analysis`, `vv_return_rate_by_category_channel`, `vv_Marketing_ROI_by_platform`) using `DENSE_RANK()`, conditional `CASE WHEN` pivots, and `SUM() OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` |
| **4. Executive Presentation** | Slide Deck (PDF / HTML) | Recommendation-first visual narrative for executive stakeholders |

---

## 4. Key Findings & SQL Outputs

### 1. Category Profitability (`01_category_profitability.sql`)
Across all 8 categories, BrightCart generated **$277,969.13 in gross revenue**, **$236,318.37 in net revenue**, **$179,984.54 in total costs**, and **$56,333.83 in net profit**—yielding a **23.84% revenue-weighted net profit margin** (and a **22.53% simple average** across the 8 categories).

* **Most Profitable Category:** `Electronics` leads at a **31.13% net profit margin** ($13,973.46 net profit on $44,885.84 net revenue).
* **Least Profitable Category:** `Books` ranks last at an **11.94% net profit margin** ($2,249.79 net profit on $18,847.37 net revenue).
* **Category Ranking Shift (v2 vs. v1):** Once discounts and returns are netted out, `Toys` (**26.15%**) and `Home & Kitchen` (**25.37%**) outperform `Food & Beverage` (**24.76%**), which dropped from #2 in v1 to #4 in v2.

| Category | Gross Revenue | Net Revenue | Total Cost | Gross Profit | Net Profit | Net Margin % | Return Rate % | Product Cost % (of Net) | Shipping Cost % (of Net) | Discount % (of Gross) | Flag |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Electronics** | $52,876.49 | $44,885.84 | $30,912.38 | $21,964.11 | $13,973.46 | **31.13%** | 8.61% | 44.76% | 15.91% | 7.40% | `Highest_profit` |
| **Toys** | $39,081.00 | $33,595.68 | $24,809.43 | $14,271.57 | $8,786.25 | **26.15%** | 7.00% | 46.47% | 20.06% | 7.72% | `--` |
| **Home & Kitchen** | $30,879.43 | $26,359.76 | $19,671.19 | $11,208.24 | $6,688.57 | **25.37%** | 6.00% | 46.85% | 18.93% | 7.06% | `--` |
| **Food & Beverage** | $36,878.52 | $30,662.69 | $23,070.92 | $13,807.60 | $7,591.77 | **24.76%** | 5.67% | 46.63% | 21.01% | 7.35% | `--` |
| **Sports** | $37,453.25 | $32,329.83 | $24,733.20 | $12,720.05 | $7,596.63 | **23.50%** | 7.19% | 48.54% | 21.39% | 8.32% | `--` |
| **Clothing** | $37,515.60 | $31,383.13 | $25,110.65 | $12,404.95 | $6,272.48 | **19.99%** | 8.19% | 48.90% | 23.72% | 7.79% | `--` |
| **Beauty** | $20,871.36 | $18,254.07 | $15,079.19 | $5,792.17 | $3,174.88 | **17.39%** | 5.85% | 47.06% | 28.34% | 8.39% | `--` |
| **Books** | $22,413.48 | $18,847.37 | $16,597.58 | $5,815.90 | $2,249.79 | **11.94%** | 8.37% | 47.52% | 33.23% | 6.51% | `lowest_profit` |
| **Total / Weighted** | **$277,969.13** | **$236,318.37** | **$179,984.54** | **$97,984.59** | **$56,333.83** | **23.84%** | **7.20%** | **46.94%** | **20.97%** | **7.59%** | **22.53% Mean** |

#### What Drives the 19.19-Point Gap Between Electronics and Books?
Using dynamic conditional aggregation (`performance_flag = 'Highest_profit'` vs. `'lowest_profit'`), the follow-up query isolates the exact cost drivers:
* **Shipping Cost (+17.32 percentage points):** Shipping consumes **33.23%** of net revenue in `Books` versus **15.91%** in `Electronics`—accounting for **90.26% of the entire 19.19-point net margin gap**.
* **Product Cost (+2.76 percentage points):** Product cost takes **47.52%** of net revenue in `Books` versus **44.76%** in `Electronics`.
* **Returns (-0.24 pts) & Discounts (-0.89 pts):** Both are slightly lower in `Books` (8.37% return rate, 6.51% discount) than in `Electronics` (8.61% return rate, 7.40% discount), proving that **heavy per-unit shipping relative to low book selling prices** is the primary margin killer.

---

### 2. Sales Channel Profitability (`02_channel_analysis.sql`)
Evaluating channels on true `net_revenue` and `profit` reveals a stark divide between owned channels (`Mobile App`, `Website`) and third-party channels (`Social Commerce`, `Marketplace`):

* **Mobile App Leads All Channels:** Generates **$36.32 net profit per order** at a **29.76% net margin** ($122.06 net AOV), outperforming `Website` ($31.60/order, 27.01% net margin) by **$4.72 per order** and **2.75 percentage points**.
* **Marketplace Ranks Last Despite Lowest Returns:** `Marketplace` earns just **$15.40 net profit per order** (**13.03% net margin** on a $118.15 net AOV)—less than half of `Mobile App` (**2.36x lower**)—even though `Marketplace` has the lowest return rate (**6.44%**). Third-party platform fees directly compress Marketplace unit economics.
* **Social Commerce:** Earns **$17.11 net profit per order** (**15.37% net margin** on a $111.32 net AOV), dragged down by both platform fees and the highest channel return rate (**9.14%**).

| Sales Channel | Net AOV | Net Profit Margin % | Return Rate % | Net Profit per Order | Performance Flag |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Mobile App** | $122.06 | **29.76%** | 7.30% | **$36.32** | `Highest_profit` |
| **Website** | $116.97 | **27.01%** | 7.04% | **$31.60** | `--` |
| **Social Commerce** | $111.32 | **15.37%** | 9.14% | **$17.11** | `--` |
| **Marketplace** | $118.15 | **13.03%** | 6.44% | **$15.40** | `lowest_profit` |

---

### 3. Return Rate & Lost Revenue Analysis (`03_return_rate_analysis.sql`)
* **Headline Return Impact:** Out of **2,000 total orders**, **144 orders were returned** (an overall order return rate of **7.20%**), resulting in **$22,206.76 in lost gross revenue** (**7.99% of total gross revenue**).
* **Channel & Category Hotspots:** Across all 32 channel-category combinations, **Social Commerce** accounts for the four highest return rates—peaking in `Clothing` (**13.33%**), `Home & Kitchen` (**13.04%**), `Books` (**13.04%**), and `Food & Beverage` (**12.50%**).
* **Channel Spread:** `Marketplace` has the lowest overall return rate (**6.44%**) and logs the two lowest category cells (`Food & Beverage` at **1.61%** and `Sports` at **1.92%**), but spikes to **11.67%** in `Clothing`. `Mobile App` is the most consistent channel across categories (**4.76%** in `Home & Kitchen` to **9.47%** in `Sports`).

| Rank | Channel & Category Combination | Return Rate % |
| :--- | :--- | :---: |
| **1 (Highest)** | Social Commerce — Clothing | **13.33%** |
| **2 (Tied)** | Social Commerce — Home & Kitchen | **13.04%** |
| **2 (Tied)** | Social Commerce — Books | **13.04%** |
| **4** | Social Commerce — Food & Beverage | **12.50%** |
| **5** | Marketplace — Clothing | **11.67%** |
| **6** | Website — Electronics | **9.90%** |
| **7** | Mobile App — Sports | **9.47%** |
| **8** | Website — Books | **9.09%** |
| **31 (2nd Lowest)** | Marketplace — Sports | **1.92%** |
| **32 (Lowest)** | Marketplace — Food & Beverage | **1.61%** |

---

### 4. Marketing ROI by Platform (`04_marketing_roi.sql`)
Across 144 platform-months (6 platforms × 24 months), BrightCart spent **$503,506.14** and generated **$8,146,615.20** in last-touch attributed revenue (**16.18x blended ROAS**).

* **Top Efficiency & Scale:** `TikTok Ads` delivers the highest ROAS at **24.02x** with the lowest CPA (**$3.06**) and CPC (**$0.15**), generating **$1,374,627.17** in attributed revenue on just **$57,229.22** of spend (producing $156K more attributed revenue than `Facebook Ads` on almost half the spend). `Influencer` campaigns rank a close second at **22.70x ROAS** (**$3.39 CPA**, **$0.17 CPC**) and drive the highest total attributed revenue (**$2,216,974.26** on **$97,663.12** spend).
* **Budget Misallocation:** `Google Ads` (**$152,546.48** spend, **14.38x ROAS**) and `Facebook Ads` (**$106,451.93** spend, **11.45x ROAS**) absorb **51.4% of the total marketing budget** despite ranking 4th and 5th in ROAS.
* **Lowest Efficiency:** `Email Marketing` is the least efficient channel at **4.81x ROAS**, with a CPA of **$17.86** (5.8x higher than TikTok) and a CPC of **$0.94** (6.3x higher than TikTok).
* **Are Any Platforms Negative?** In aggregate, **no platform is below 1.0x ROAS**. At the monthly grain, only **1 out of 144 platform-months** lost money: `Email Marketing` in `2025-12` (**0.67x ROAS**, $1,796.66 spend, $163.33 CPA, $3.77 CPC).

| Advertising Platform | Attributed Revenue | Total Spend | Share of Budget | ROAS | CPA | CPC |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **TikTok Ads** | $1,374,627.17 | $57,229.22 | 11.37% | **24.02x** | **$3.06** | **$0.15** |
| **Influencer** | $2,216,974.26 | $97,663.12 | 19.40% | **22.70x** | **$3.39** | **$0.17** |
| **Instagram Ads** | $1,024,639.06 | $65,154.02 | 12.94% | **15.73x** | **$4.70** | **$0.21** |
| **Google Ads** | $2,194,120.83 | $152,546.48 | 30.30% | **14.38x** | **$4.72** | **$0.25** |
| **Facebook Ads** | $1,218,572.43 | $106,451.93 | 21.14% | **11.45x** | **$6.27** | **$0.32** |
| **Email Marketing** | $117,681.45 | $24,461.37 | 4.86% | **4.81x** | **$17.86** | **$0.94** |
| **Total / Blended** | **$8,146,615.20** | **$503,506.14** | **100.00%** | **16.18x** | **$4.75** | **$0.23** |

---

### 5. 20% Marketing Budget Cut Strategy (`05_budget_reallocation.sql`)
A 20% reduction of the **$503,506.14** budget equals **$100,701.23**. Using a CTE with an ordered cumulative window function (`SUM(spend) OVER (ORDER BY roas ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)`), I ranked all 144 platform-months from lowest to highest ROAS and filtered `WHERE cumulative_pct_of_budget < 21`.

* **The Optimal Cut Set:** The **34 lowest-ROAS platform-months** (ranging from **0.67x to 6.60x ROAS**) represent the smallest set reaching the 20% target, cutting **$104,532.02** (**20.76% of total spend**).Adding the 35th month (`TikTok Ads`, `2025-07`, 6.63x ROAS, $3,326.90) would push the cut to $107,858.92 (21.42%).
* **Where the Frequency vs. Dollars Come From:**
  * `Email Marketing` has the highest number of months cut (**15 of 24 months**, or **69.2% of Email's total budget**), including the 4 worst months in the dataset (`2025-12` at 0.67x, `2025-10` at 1.21x, `2025-07` at 1.74x, and `2024-06` at 1.80x). However, because Email is a low-spend channel, those 15 months only yield **$16,927.46 (16.19% of the cut)**.
  * **55.01% of the dollar savings ($57,508.56)** comes from cutting **7 low-performing months of `Facebook Ads` ($36,589.02)** and **4 low-performing months of `Google Ads` ($20,919.54)**.

| Platform | Months Cut (of 24) | Spend Cut | Share of Cut | Share of Platform's Total Spend | ROAS Range of Cut Months | Mean CPA in Cut | Mean CPC in Cut |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Facebook Ads** | 7 | **$36,589.02** | **35.00%** | 34.37% | 2.51x – 6.60x | $12.23 | $0.44 |
| **Google Ads** | 4 | **$20,919.54** | **20.01%** | 13.71% | 3.32x – 4.27x | $13.70 | $0.35 |
| **Influencer** | 4 | **$16,985.14** | **16.25%** | 17.39% | 3.78x – 5.83x | $10.53 | $0.25 |
| **Email Marketing** | 15 | **$16,927.46** | **16.19%** | 69.20% | 0.67x – 6.57x | $35.07 | $1.34 |
| **Instagram Ads** | 2 | **$8,696.44** | **8.32%** | 13.35% | 5.19x – 5.76x | $10.12 | $0.26 |
| **TikTok Ads** | 2 | **$4,414.42** | **4.22%** | 7.71% | 6.01x – 6.28x | $8.55 | $0.17 |
| **Total Cut** | **34 Months** | **$104,532.02** | **100.00%** | **20.76% of Total Budget** | **0.67x – 6.60x** | **$22.25** | **$0.82** |

---

## 5. Top 3 Executive Recommendations

1. **Enforce a Minimum Order Value (MOV) for Free Shipping on Books & Beauty:**
   * *Problem:* `Books` (**11.94% net margin**) and `Beauty` (**17.39% net margin**) lose **33.23%** and **28.34%** of their net revenue to shipping costs (versus 15.91% in `Electronics`), with shipping driving **90.3%** of the category margin gap.
   * *Action:* Introduce a minimum order threshold (e.g., $35+) or multi-item bundling requirement for free shipping in `Books` and `Beauty`. Reducing `Books` shipping cost share from 33.23% to the 20.97% company average recovers **~$2,311 in direct net profit** (+102.7% category net profit lift).
2. **Shift Customer Acquisition & Retention from Marketplace/Social to Owned Mobile App:**
   * *Problem:* Third-party `Marketplace` yields just **$15.40 net profit/order (13.03% margin)** due to platform fees, while `Social Commerce` yields **$17.11/order (15.37% margin)** and suffers a **9.14% return rate** (**13.33% in Clothing**). By contrast, `Mobile App` generates **$36.32 net profit/order (29.76% margin)**.
   * *Action:* Use insert cards and app-exclusive loyalty discounts to migrate repeat `Marketplace` and `Social Commerce` buyers to the `Mobile App` (+$19.21 to +$20.92 incremental net profit per migrated order), and tighten sizing guides/product videos on `Social Commerce — Clothing`, `Books`, and `Home & Kitchen` to cut the **$22,206.76** annual return bleed.
3. **Cut $104,532.02 (20.76%) Across the 34 Lowest-ROAS Platform-Months & Reallocate to TikTok/Influencer:**
   * *Problem:* $104.5K is tied up in 34 platform-months operating below 6.60x ROAS—including 15 months of `Email Marketing` ($16,927.46, 0.67x–6.57x ROAS) and 11 seasonal slump months in `Facebook Ads` ($36,589.02) and `Google Ads` ($20,919.54).
   * *Action:* Pause or cap spend during those 34 underperforming platform-months to immediately save **$104,532.02 (20.76% of budget)**, or redeploy a portion of that capital into uncapped months on `TikTok Ads` (**24.02x ROAS, $3.06 CPA**) and `Influencer` (**22.70x ROAS, $3.39 CPA**).

---

## 6. Repository Structure

```text
brightcart-profitability-analysis/
├── README.md
├── data/
│   ├── raw/
│   │   ├── orders.csv
│   │   ├── products.csv
│   │   └── marketing_spend.csv
│   └── outputs/
│       ├── result of 01.csv          # Category net profitability view output
│       ├── result of 01.0.csv        # Electronics vs. Books cost-driver gap output
│       ├── result of 02.csv          # Sales channel net profitability output
│       ├── result of 03.csv          # 32 channel-category return rate matrix
│       ├── result of 03.0.csv        # Total returned orders & lost gross revenue summary
│       ├── result of 04.0.csv        # Marketing platform ROAS, CPA, CPC & total spend
│       └── result of 05.0_2.csv      # 34 lowest-ROAS platform-months for 20% budget cut
├── sql/
│   ├── 00_validation_checks.sql      # Grain, cost rollup, net revenue & return-loss audit
│   ├── 01_category_profitability.sql # Category net margins & dynamic driver attribution
│   ├── 02_channel_analysis.sql       # Channel net AOV, net margin & profit per order
│   ├── 03_return_rate_analysis.sql   # Channel-category return rates & lost revenue KPIs
│   ├── 04_marketing_roi.sql          # Platform attributed revenue, spend, ROAS, CPA & CPC
│   └── 05_budget_reallocation.sql    # CTE + window function isolating the 20% spend cut
└── presentation/
    └── BrightCart_Profitability_Deck.pdf
```

---

## 7. How to Reproduce

1. **Create Database & Import Raw CSVs:**
   Create the `e_commerce_profitability_analysis` schema in MySQL and import `orders.csv`, `products.csv`, and `marketing_spend.csv` directly via MySQL Workbench Table Data Import Wizard or `LOAD DATA INFILE`.
2. **Run Reconciliation Checks:**
   Execute `sql/00_validation_checks.sql` to verify zero duplicate `order_id` rows and confirm the native `total_costs`, `net_revenue`, and `profit` accounting identities.
3. **Build Analytical Views & Run Queries:**
   Execute scripts `01` through `05` in `sql/` in order to generate the views and reproduce the output CSVs in `data/outputs/`.

---

## Author

**Muhammad Abdullah**  
Data & BI Analyst | BSc Mathematics  
[GitHub](https://github.com/ak786abdullah)
