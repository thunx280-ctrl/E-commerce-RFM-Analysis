# 🛒 E-Commerce Web Analytics & Conversion Funnel Optimization

[![Google BigQuery](https://img.shields.io/badge/Google%20BigQuery-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)](https://cloud.google.com/bigquery)
[![Standard SQL](https://img.shields.io/badge/Standard%20SQL-CC292B?style=for-the-badge&logo=sqlite&logoColor=white)](https://cloud.google.com/bigquery/docs/reference/standard-sql)
[![Google Analytics 360](https://img.shields.io/badge/Google%20Analytics%20360-E37400?style=for-the-badge&logo=googleanalytics&logoColor=white)](https://support.google.com/analytics/answer/3437719)
[![Data Analysis](https://img.shields.io/badge/Domain-E--Commerce%20Analytics-22c55e?style=for-the-badge)](https://github.com/thunx280-ctrl)

> **In-depth behavioral analysis, multi-stage conversion funnel optimization, and revenue attribution across millions of user sessions on Google Merchandise Store using Google BigQuery Standard SQL.**

---

## 📌 Executive Summary

This project conducts a comprehensive end-to-end web analytics investigation of an e-commerce platform using the public **Google Analytics 360 (GA360)** dataset hosted on **Google BigQuery**. 

By querying raw session logs with nested, semi-structured records (`RECORD` and `REPEATED`), the analysis extracts vital business intelligence across **traffic acquisition, audience engagement, device contribution, cross-selling baskets, and conversion funnels** to drive commercial growth and optimize marketing ROI.

### Key Business Takeaways:
- **Desktop Dominance in Monetization:** Desktop generates **96.14%** of total revenue despite mobile accounting for significant traffic, signaling high checkout friction on mobile devices.
- **Improving Purchase Conversion Rate:** The end-to-end funnel purchase rate surged from **8.31% (Jan 2017)** to **12.64% (Mar 2017)**, driven by strong checkout completion.
- **Cross-Selling Potential:** Customers purchasing the *"YouTube Men's Vintage Henley"* displayed strong affinity for *Google Sunglasses* (20 units) and *Hero Tee Black* (7 units), highlighting clear bundling and recommendation opportunities.
- **Traffic Channel Divergence:** Sources like `mail.google.com` and `dealspotr.com` delivered exceptional conversion rates (>10%), while organic and direct channels drove sheer volume.

---

## 📂 Repository Structure

```text
bigquery-ecommerce-sql-analysis/
├── .gitignore                      # Excludes raw spreadsheets, drafts, and system files
├── Explore_Ecommerce_Dataset.sql   # 10 production-ready analytical SQL queries
└── README.md                       # Comprehensive documentation & business report
```

---

## 🛠️ Dataset & Technical Highlights

### 1. Dataset Overview
- **Source:** `bigquery-public-data.google_analytics_sample.ga_sessions_*`
- **Volume:** Daily partitioned tables covering 12 months (August 2016 – August 2017).
- **Schema Complexity:** Contains nested structures (`hits`, `customDimensions`) and repeated arrays (`hits.product`, `hits.promotion`).

### 2. Advanced SQL Competencies Demonstrated
- **Nested & Repeated Data Unnesting:** Multi-level `UNNEST(hits) AS hits, UNNEST(hits.product) AS product` with comma-join flattening syntax.
- **Partition & Shard Pruning:** Efficient query cost optimization using `_TABLE_SUFFIX BETWEEN ...` to scan only targeted date partitions.
- **Window Analytical Functions:** Calculating totals, running cumulative revenue, and contribution ratios via `SUM(...) OVER()` and `SUM(...) OVER(ORDER BY ...)`.
- **E-Commerce Funnel & Action Mapping:** Mapping GA action types (`action_type = '2'` view, `'3'` add-to-cart, `'6'` purchase) into an aggregated multi-stage funnel.
- **Common Table Expressions (CTEs):** Modular, readable query architectures for complex cohort and purchaser segmentation.
- **Temporal Transformations:** Date parsing and formatting via `PARSE_DATE('%Y%m%d', date)` and `FORMAT_DATE('%Y%m', ...)`.

---

## 🔍 In-Depth Analytical Breakdown (10 Queries)

### Query 01: Monthly Traffic, Pageviews, and Transaction Volume
- **Objective:** Track high-level growth trends in visits, user engagement (pageviews), and transactions for Q1 2017 (Jan – Mar).
- **SQL Mechanics:** Shard filtering via `_table_suffix between '0101' and '0331'`, aggregation with `SUM()`.

```sql
SELECT
    format_date('%Y%m', parse_date('%Y%m%d', date)) AS month,
    sum(totals.visits) AS visits,
    sum(totals.pageviews) AS pageviews,
    sum(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix between '0101' and '0331'
GROUP BY month
ORDER BY month;
```

**Results:**
| Month | Visits | Pageviews | Transactions |
| :---: | :---: | :---: | :---: |
| **201701** | 64,711 | 264,887 | 713 |
| **201702** | 62,192 | 244,142 | 733 |
| **201703** | 69,892 | 298,875 | 993 |

💡 **Insight:** March 2017 saw strong rebound across all metrics: visits rose by **+12.4%** MoM, while transactions surged by **+35.5%** MoM (from 733 to 993), signaling increased purchase intent heading into spring.

---

### Query 02: Bounce Rate per Traffic Source (July 2017)
- **Objective:** Identify which acquisition channels attract high-bounce (low-intent) visitors versus engaged audiences.
- **Formula:** $\text{Bounce Rate (\%)} = \frac{\sum(\text{totals.bounces})}{\sum(\text{totals.visits})} \times 100$

```sql
SELECT
    trafficSource.source AS source,
    sum(totals.visits) AS total_visits,
    sum(totals.bounces) AS total_no_of_bounces,
    round(sum(totals.bounces) / sum(totals.visits) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;
```

**Key Findings (Top Sources by Traffic):**
| Traffic Source | Total Visits | Total Bounces | Bounce Rate (%) |
| :--- | :---: | :---: | :---: |
| `google` | 38,400 | 19,798 | **51.557%** |
| `(direct)` | 19,891 | 8,606 | **43.266%** |
| `youtube.com` | 6,351 | 4,238 | **66.730%** |
| `analytics.google.com` | 1,972 | 1,064 | **53.955%** |
| `Partners` | 1,783 | 936 | **52.496%** |
| `m.facebook.com` | 669 | 496 | **74.141%** |

💡 **Insight:** Referral traffic from `youtube.com` (66.7%) and social mobile `m.facebook.com` (74.1%) exhibited severe bounce rates. Users landing from video/social platforms require tailored, mobile-responsive landing pages rather than generic catalog pages.

---

### Query 03: Revenue Attribution by Traffic Source (Week vs. Month)
- **Objective:** Compare revenue generated by acquisition sources in June 2017 across both weekly and monthly granularities.
- **SQL Mechanics:** Two CTEs (`week` and `month`) combined using `UNION ALL`, dividing `productRevenue` by $10^6$ to normalize micro-units.

**Key Findings (Top Monthly Revenue Drivers):**
| Time Type | Time Period | Traffic Source | Revenue ($ USD) |
| :---: | :---: | :--- | :---: |
| Month | 201706 | `(direct)` | **$97,333.62** |
| Month | 201706 | `google` | **$18,757.18** |
| Month | 201706 | `dfa` | **$8,862.23** |
| Month | 201706 | `mail.google.com` | **$2,563.13** |

💡 **Insight:** Direct traffic is by far the primary revenue driver ($97.3K vs $18.8K for Google organic/paid), demonstrating high brand retention and repeat purchasers bookmarking the site.

---

### Query 04: Conversion Rate by Traffic Source (2017)
- **Objective:** Determine the most effective converting channels across entire 2017, filtered to statistically significant sources ($\ge 50$ transactions).
- **Formula:** $\text{Conversion Rate (\%)} = \frac{\sum(\text{totals.transactions})}{\sum(\text{totals.visits})} \times 100$

```sql
SELECT
    trafficSource.source AS source,
    sum(totals.visits) AS visits,
    sum(totals.transactions) AS transactions,
    round(sum(totals.transactions) / sum(totals.visits) * 100, 2) AS conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
GROUP BY source
HAVING SUM(totals.transactions) >= 50
ORDER BY conversion_rate DESC;
```

**Results:**
| Traffic Source | Visits | Transactions | Conversion Rate (%) |
| :--- | :---: | :---: | :---: |
| `dealspotr.com` | 543 | 56 | **10.31%** |
| `mail.google.com` | 2,815 | 122 | **4.33%** |
| `(direct)` | 177,295 | 4,295 | **2.42%** |
| `google` | 382,211 | 4,493 | **1.18%** |
| `dfa` | 8,421 | 56 | **0.67%** |

💡 **Insight:** Coupon/affiliate channel `dealspotr.com` achieves an extraordinary **10.31%** conversion rate, proving that discount-oriented shoppers arrive with immediate purchase intent. Email marketing (`mail.google.com`) also converts at nearly 4x the rate of organic search (4.33% vs 1.18%).

---

### Query 05: User Engagement: Purchasers vs. Non-Purchasers
- **Objective:** Measure the engagement depth (average pageviews per unique visitor) between users who complete a purchase versus those who leave without buying.
- **SQL Mechanics:** Separate CTEs calculating $\frac{\sum(\text{pageviews})}{\text{COUNT(DISTINCT fullVisitorId)}}$ unnesting products, joined on month.

**Results:**
| Month | Avg Pageviews (Purchasers) | Avg Pageviews (Non-Purchasers) |
| :---: | :---: | :---: |
| **201706** | **94.67** | **316.87** |
| **201707** | **124.24** | **334.06** |

💡 **Insight:** Contrary to common assumptions, non-purchasers consume significantly more pageviews per user (~316–334) than actual purchasers (~94–124). This indicates users who fail to purchase often get lost in deep navigation loops or struggle to find specific items, suggesting a need for improved search algorithms and streamlined product filtering.

---

### Query 06: Average Transactions per Buyer (July 2017)
- **Objective:** Evaluate purchasing frequency among active buyers in July 2017.
- **Formula:** $\text{Avg Trans/Buyer} = \frac{\sum(\text{totals.transactions})}{\text{COUNT(DISTINCT fullVisitorId)}}$

```sql
SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month,
    round(sum(totals.transactions) / count(distinct fullVisitorId), 2) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) hits,
    UNNEST(hits.product) product
WHERE totals.transactions >= 1
      AND product.productRevenue IS NOT NULL
GROUP BY month;
```

**Results:**
| Month | Avg Transactions per Buyer |
| :---: | :---: |
| **201707** | **4.16** |

💡 **Insight:** On average, purchasing customers completed **4.16 transactions** within the single month of July 2017, proving high customer lifetime value (LTV) and high repeat purchase behavior within the active customer segment.

---

### Query 07: Device Revenue Contribution Share (July 2017)
- **Objective:** Quantify revenue contribution split across hardware device categories using Window Functions.
- **SQL Mechanics:** Window function `SUM(revenue_by_device) OVER()` to calculate overall revenue dynamically without an extra `JOIN`.

```sql
WITH device_revenue AS (
  SELECT
    device.deviceCategory AS device,
    sum(product.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE totals.transactions IS NOT NULL
        AND product.productRevenue IS NOT NULL
  GROUP BY device
)
SELECT
    device,
    revenue_by_device,
    SUM(revenue_by_device) OVER() AS total_revenue,
    ROUND(revenue_by_device * 100 / SUM(revenue_by_device) OVER(), 2) AS ratio
FROM device_revenue
ORDER BY ratio DESC;
```

**Results:**
| Device Category | Revenue ($ USD) | Total Revenue ($ USD) | Revenue Share (%) |
| :--- | :---: | :---: | :---: |
| **Desktop** | **$159,920.49** | $166,334.80 | **96.14%** |
| **Mobile** | **$5,404.91** | $166,334.80 | **3.25%** |
| **Tablet** | **$1,009.40** | $166,334.80 | **0.61%** |

💡 **Insight:** **96.14%** of revenue is generated via desktop. While mobile accounts for considerable web visits, conversion friction (complex checkout forms, non-optimized mobile payments) prevents mobile monetization. Optimizing Apple Pay / Google Pay one-click checkout is an immediate strategic priority.

---

### Query 08: Market Basket Analysis (Cross-Selling)
- **Objective:** Discover products frequently bought in conjunction with the popular *"YouTube Men's Vintage Henley"* in July 2017.
- **SQL Mechanics:** Self-joining buyer ID cohort CTE (`Henley_buyers`) against overall product transactions, excluding the anchor item itself.

**Top Co-Purchased Items:**
| Rank | Recommended Product | Quantity Purchased Together |
| :---: | :--- | :---: |
| 1 | **Google Sunglasses** | **20** |
| 2 | **Google Women's Vintage Hero Tee Black** | **7** |
| 3 | **Google Men's Vintage Badge Tee Black** | **7** |
| 4 | **Android Mountain View Short Sleeve T-Shirt** | **6** |
| 5 | **Google Lip Balm Splash** | **6** |

💡 **Strategic Action:** Implement an automated *"Customers Who Bought This Also Bought"* widget on the Henley product page displaying *Google Sunglasses* and *Vintage Black Tees*, and test pre-bundled product packages at a 10% discount.

---

### Query 09: E-Commerce Conversion Funnel Cohort (Q1 2017)
- **Objective:** Track progression through the full buyer journey: **Product Views** (`action_type = '2'`) $\rightarrow$ **Add to Cart** (`action_type = '3'`) $\rightarrow$ **Completed Purchases** (`action_type = '6'`).
- **SQL Mechanics:** Conditional aggregation using `COUNT(CASE WHEN ... END)` across multi-level nested fields.

```sql
WITH product_data AS (
  SELECT
    format_date('%Y%m', parse_date('%Y%m%d', date)) AS month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) AS num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) AS num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' AND product.productRevenue IS NOT NULL THEN product.v2ProductName END) AS num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _table_suffix BETWEEN '20170101' AND '20170331'
        AND eCommerceAction.action_type IN ('2','3','6')
  GROUP BY month
)
SELECT
    month,
    num_product_view,
    num_add_to_cart,
    num_purchase,
    round(num_add_to_cart / num_product_view * 100, 2) AS add_to_cart_rate,
    round(num_purchase / num_product_view * 100, 2) AS purchase_rate
FROM product_data
ORDER BY month;
```

**Funnel Metrics Table:**
| Month | Product Views | Add to Cart | Purchases | Add-to-Cart Rate (%) | Purchase Rate (%) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **201701** | 25,787 | 7,342 | 2,143 | **28.47%** | **8.31%** |
| **201702** | 21,489 | 7,360 | 2,060 | **34.25%** | **9.59%** |
| **201703** | 23,549 | 8,782 | 2,977 | **37.29%** | **12.64%** |

💡 **Insight:** Across Q1 2017, the e-commerce store significantly improved bottom-funnel conversion:
- Add-to-cart rate expanded from **28.47%** to **37.29%** (+8.82 percentage points).
- Final purchase rate increased from **8.31%** to **12.64%** (+4.33 percentage points, a **+52.1% relative gain**), demonstrating high product attractiveness and reduced cart abandonment.

---

### Query 10: Weekly & Cumulative Revenue Run-Rate (May – July 2017)
- **Objective:** Track weekly revenue velocity and cumulative financial trajectory over a 3-month window.
- **SQL Mechanics:** Window function `SUM(weekly_revenue) OVER (ORDER BY week)` to calculate unbounded running cumulative revenue.

```sql
WITH weekly_rev_data AS (
    SELECT
        format_date('%Y-%W', parse_date('%Y%m%d', date)) AS week,
        round(SUM(p.productRevenue) / 1000000, 2) AS weekly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
        UNNEST(hits) AS h,
        UNNEST(h.product) AS p
    WHERE _TABLE_SUFFIX BETWEEN '0501' AND '0731'
          AND p.productRevenue IS NOT NULL
    GROUP BY week
)
SELECT
    week,
    weekly_revenue,
    round(SUM(weekly_revenue) OVER (ORDER BY week), 2) AS cumulative_revenue
FROM weekly_rev_data
ORDER BY week;
```

**Results:**
| Week | Weekly Revenue ($ USD) | Cumulative Revenue ($ USD) |
| :---: | :---: | :---: |
| `2017-18` | $12,382.47 | $12,382.47 |
| `2017-19` | $16,773.85 | $29,156.32 |
| `2017-20` | $10,030.70 | $39,187.02 |
| `2017-21` | $14,642.50 | $53,829.52 |
| `2017-22` | $15,649.07 | $69,478.59 |
| `2017-23` | $16,339.46 | $85,818.05 |
| `2017-24` | $19,410.63 | $105,228.68 |
| `2017-25` | $46,654.54 | $151,883.22 |
| `2017-26` | $23,059.85 | $174,943.07 |
| `2017-27` | $18,485.49 | $193,428.56 |
| `2017-28` | $14,945.71 | $208,374.27 |
| `2017-29` | $19,052.95 | $227,427.22 |
| `2017-30` | $24,196.26 | $251,623.48 |
| `2017-31` | $8,898.37 | **$260,521.85** |

💡 **Insight:** Week 25 (`2017-25`) witnessed an enormous revenue spike to **$46,654.54** (over 2.4x the average weekly run-rate), likely due to a mid-year promotional campaign or enterprise bulk order. Total cumulative revenue over the 14-week period reached **$260,521.85**.

---

## 💻 How to Replicate Queries in Google BigQuery

The dataset used in this project is publicly accessible and free to query on Google Cloud BigQuery:

1. Open the [Google Cloud BigQuery Console](https://console.cloud.google.com/bigquery).
2. Create a new SQL query tab.
3. Copy any query block from [`Explore_Ecommerce_Dataset.sql`](./Explore_Ecommerce_Dataset.sql).
4. Run the query directly against the public dataset:
   ```text
   bigquery-public-data.google_analytics_sample.ga_sessions_*
   ```
5. *(Optional)* Save queries as BigQuery Views or connect to Google Looker Studio / Power BI for real-time dashboarding.

---

## 👤 Author & Contact

**Nguyễn Xuân Thu**
- 🐙 GitHub: [@thunx280-ctrl](https://github.com/thunx280-ctrl)
- 💼 LinkedIn: [Nguyen Xuan Thu](https://linkedin.com)
- 📧 Email: `thunx280@gmail.com`
