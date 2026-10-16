# BrightCart E-Commerce Profitability & Marketing ROI Audit (v2 ELT Architecture)

An end-to-end profitability and marketing attribution audit for a multi-channel e-commerce retailer: moving from raw CSV ingestion in MySQL to SQL-based financial reconciliation, true net margin modeling, and an executive stakeholder presentation.

> **Note:** BrightCart is a fictional retailer used in a practice project brief from Analyst Builder. The business scenario and raw dataset are provided by that platform; the ELT validation framework, v1-to-v2 accounting reconciliation, SQL window-function modeling, findings, and executive deck below are original work.

---

## The Business Problem

BrightCart sells products across **8 categories** through **4 sales channels**: Website, Mobile App, Third-Party Marketplace, and Social Commerce. Over a 24-month period, the company generated **$277,969.13 in gross revenue** ($236,318.37 in net revenue across 2,000 orders), alongside **$503,506.14 in marketing spend**, but net margins were shrinking and leadership needed to pinpoint where profits were leaking.

This project answers five questions a CEO would actually ask:
1. **Category Profitability:** What is the average profit margin by product category? Which categories are most and least profitable, and what is driving the difference (product cost, shipping, returns, or discounts)?
2. **Channel Unit Economics:** How does profitability differ across sales channels? Which channel delivers the best and worst profit per order after accounting for platform fees?
3. **Return Rate Impact:** What is the return rate by category and channel, and how much total revenue was lost to returns?
4. **Marketing ROAS:** Which advertising platform delivers the best Return on Ad Spend (ROAS), and are any platforms burning cash without a positive return?
5. **20% Budget Cut Strategy:** If the CEO cuts 20% of the marketing budget, which exact platforms and months should be reduced?

---

## Why I Rebuilt This Project: v1 (ETL) vs. v2 (ELT) Methodology Audit

In my **initial approach (v1)**, I pre-processed the data in Python before loading it to MySQL and manually overwrote the `profit` column using:

```python
# v1 Flawed Approach (Gross Profit only — ignored
