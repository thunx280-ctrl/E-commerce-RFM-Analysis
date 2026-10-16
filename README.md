# 🛒 E-Commerce RFM Analytics

> **In-depth behavioral analysis, multi-stage conversion funnel optimization, and revenue attribution across millions of user sessions on Google Merchandise Store using Google BigQuery Standard SQL.**

---

## 📌 1. Project Overview (Tóm tắt dự án)

Dự án thực hiện phân tích hành vi người dùng và hiệu quả kinh doanh của nền tảng thương mại điện tử **Google Merchandise Store** dựa trên bộ dữ liệu thực tế **Google Analytics 360 (GA360)** lưu trữ trên nền tảng điện toán đám mây **Google BigQuery**.

Bằng việc truy vấn và bóc tách các trường dữ liệu bán cấu trúc dạng lồng nhau (`RECORD` và `REPEATED`), dự án trả lời các câu hỏi kinh doanh trọng yếu về:
1. **Lưu lượng & Tương tác**: Đánh giá biến động lượt truy cập (visits), số trang xem (pageviews) và số đơn hàng (transactions).
2. **Tỷ lệ thoát trang (Bounce Rate)**: Xác định chất lượng các nguồn traffic để tối ưu chi phí tiếp thị.
3. **Phân bổ doanh thu (Revenue Attribution)**: Đo lường doanh thu theo nguồn truy cập phân tách theo tuần và tháng.
4. **Hiệu suất chuyển đổi (Conversion Rate)**: Xếp hạng các kênh tiếp thị chuyển đổi hiệu quả nhất năm 2017.
5. **Hành vi người mua (User Engagement)**: So sánh thói quen duyệt trang giữa nhóm khách mua hàng (purchasers) và không mua hàng (non-purchasers).
6. **Tần suất mua sắm**: Đo lường số giao dịch trung bình trên mỗi khách hàng có phát sinh đơn hàng.
7. **Đóng góp phần cứng (Device Performance)**: Xác định tỷ trọng doanh thu giữa Desktop, Mobile và Tablet bằng Window Functions.
8. **Khai phá giỏ hàng (Market Basket Analysis)**: Phân tích các sản phẩm thường được mua kèm để tối ưu hóa chiến lược Cross-selling / Upselling.
9. **Tối ưu phễu chuyển đổi (Conversion Funnel)**: Đo lường tỷ lệ rớt phễu qua các giai đoạn từ Xem sản phẩm $\rightarrow$ Thêm vào giỏ $\rightarrow$ Mua hàng thành công.
10. **Doanh thu tích lũy (Cumulative Revenue)**: Theo dõi tốc độ tăng trưởng doanh thu theo tuần và lũy kế YTD.

---

## 📖 2. Data Dictionary (Từ điển dữ liệu)

Bảng dữ liệu nguồn: `bigquery-public-data.google_analytics_sample.ga_sessions_*` (dữ liệu phân vùng theo ngày từ 08/2016 đến 08/2017).

| Tên trường (Field Name) | Kiểu dữ liệu | Mô tả chi tiết |
| :--- | :---: | :--- |
| `fullVisitorId` | `STRING` | Mã định danh duy nhất của mỗi người dùng (Visitor ID). |
| `date` | `STRING` | Ngày diễn ra phiên truy cập, định dạng `YYYYMMDD`. |
| `totals.visits` | `INTEGER` | Số lượt truy cập (mặc định = 1 cho mỗi phiên hợp lệ). |
| `totals.pageviews` | `INTEGER` | Tổng số lượt xem trang trong một phiên truy cập. |
| `totals.bounces` | `INTEGER` | Tổng số lần thoát trang đơn (1 nếu rời đi ngay, `NULL` nếu có tương tác tiếp). |
| `totals.transactions` | `INTEGER` | Số lượng đơn hàng được thanh toán thành công trong phiên. |
| `trafficSource.source` | `STRING` | Nguồn gốc lưu lượng truy cập (vd: `google`, `(direct)`, `youtube.com`, `dfa`). |
| `device.deviceCategory` | `STRING` | Loại thiết bị người dùng sử dụng (`desktop`, `mobile`, `tablet`). |
| `hits` | `RECORD (REPEATED)` | Mảng chứa toàn bộ tương tác/sự kiện chi tiết phát sinh trong phiên. |
| `hits.eCommerceAction.action_type` | `STRING` | Mã hành vi thương mại điện tử trong phiên: <br>• `'2'` = Xem chi tiết sản phẩm (Product Detail View)<br>• `'3'` = Thêm sản phẩm vào giỏ (Add to Cart)<br>• `'6'` = Hoàn tất mua hàng (Completed Purchase) |
| `hits.product` | `RECORD (REPEATED)` | Mảng lồng nhau chứa thông tin các sản phẩm xuất hiện trong hit. |
| `hits.product.v2ProductName` | `STRING` | Tên chính thức của sản phẩm hiển thị trên website. |
| `hits.product.productQuantity` | `INTEGER` | Số lượng sản phẩm được đặt mua trong đơn hàng. |
| `hits.product.productRevenue` | `INTEGER` | Doanh thu sản phẩm dạng vi đơn vị (micro-units). **Cần chia $1,000,000$** để chuyển đổi sang USD. |

---
## ⚡ 3. Advanced SQL Highlights (Kỹ thuật SQL trọng tâm)

- **Unnesting Multi-Level Arrays**: `UNNEST(hits) AS hits, UNNEST(hits.product) AS product` để bóc tách cấu trúc mảng lồng nhau.
- **Partition Pruning**: Lọc tiền tố `_TABLE_SUFFIX BETWEEN ...` để tối ưu chi phí quét dữ liệu.
- **Window Functions**: `SUM(...) OVER()` tính tổng tỷ trọng và `SUM(...) OVER (ORDER BY ...)` tính doanh thu cộng dồn lũy kế.
- **Common Table Expressions (CTEs)**: Xây dựng truy vấn dạng module logic, dễ kiểm thử và bảo trì.
- **Conditional Aggregation**: Kết hợp `COUNT(CASE WHEN ... END)` dựng phễu chuyển đổi đa tầng trong 1 truy vấn.

---

## 🔍 4. Analytics Deep-Dive: 10 Analytical Queries (Code & Kết quả BigQuery)

### Query 01: Lưu lượng truy cập, Lượt xem trang & Giao dịch Q1/2017
> **Bài toán**: Tính tổng số visits, pageviews và transactions trong tháng 1, 2 và 3 năm 2017.

```sql
SELECT
    format_date('%Y%m', parse_date('%Y%m%d', date)) AS month  
    ,sum(totals.visits) AS visits
    ,sum(totals.pageviews) AS pageviews
    ,sum(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix between '0101' and '0331'
group by month
order by month;
```

**Bảng kết quả từ BigQuery:**
| Row | month | visits | pageviews | transactions |
| :---: | :---: | :---: | :---: | :---: |
| 1 | 201701 | 64,694 | 257,708 | 713 |
| 2 | 201702 | 62,192 | 233,373 | 733 |
| 3 | 201703 | 69,931 | 259,522 | 993 |

💡 **Key Takeaways:**
- **Tăng trưởng:** Tháng 3 bứt phá mạnh với lượt truy cập tăng **+12.4%** và số đơn hàng tăng vọt **+35.5%** so với tháng 2.
- **Hành động:** Chủ động tăng ngân sách tiếp thị và dự trữ hàng hóa từ cuối tháng 2 để đón đầu mùa mua sắm tháng 3.

---

### Query 02: Tỷ lệ thoát trang (Bounce Rate) theo Nguồn truy cập (Tháng 7/2017)
> **Bài toán**: Đánh giá tỷ lệ thoát trang của các kênh traffic trong tháng 7/2017 (sắp xếp giảm dần theo lượt truy cập).

```sql
SELECT
    trafficSource.source source
    ,sum(totals.visits) AS total_visits
    ,sum(totals.bounces) AS total_no_of_bounces
    ,round(sum(totals.bounces) / sum(totals.visits)*100,3) bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
group by source
order by total_visits desc;
```

**Bảng kết quả từ BigQuery:**
| Row | source | total_visits | total_no_of_bounces | bounce_rate (%) |
| :---: | :--- | :---: | :---: | :---: |
| 1 | `google` | 38,400 | 19,798 | **51.557%** |
| 2 | `(direct)` | 19,891 | 8,606 | **43.266%** |
| 3 | `youtube.com` | 6,351 | 4,238 | **66.730%** |
| 4 | `analytics.google.com` | 1,972 | 1,064 | **53.955%** |
| 5 | `Partners` | 1,788 | 936 | **52.349%** |
| 6 | `m.facebook.com` | 669 | 430 | **64.275%** |
| 7 | `google.com` | 368 | 183 | **49.728%** |

💡 **Key Takeaways:**
- **Kênh thoát cao:** Nguồn video/social như `youtube.com` (**66.73%**) và `m.facebook.com` (**64.28%**) có tỷ lệ thoát cao vượt trội so với `(direct)` (**43.27%**).
- **Hành động:** Thiết kế Landing Page chuyên biệt, tối ưu trên di động cho khách đến từ YouTube/Facebook thay vì dẫn về trang chủ chung.

---

### Query 03: Doanh thu theo Nguồn truy cập theo Tuần và Tháng (Tháng 6/2017)
> **Bài toán**: Tính doanh thu theo nguồn traffic trong tháng 6/2017 phân tách theo tuần và tháng bằng CTEs và `UNION ALL`.

```sql
with
  week as (
    SELECT
      'Week' AS time_type
      ,format_date('%Y%V', parse_date('%Y%m%d', date)) AS time
      ,trafficSource.source source
      ,round(sum(productRevenue)/1000000,4) as Revenue  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
      ,unnest (hits) hits
      ,unnest (hits.product) product
    where productRevenue is not null
    group by time_type,source,time
  ),
  month as (
    SELECT
        'Month'  as time_type
        ,format_date('%Y%m', parse_date('%Y%m%d', date)) AS time
        ,trafficSource.source source
        ,round(sum(productRevenue)/1000000,4) as Revenue  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`
      ,unnest (hits) hits
      ,unnest (hits.product) product
    where productRevenue is not null
    group by time_type,source,time
  )
SELECT * FROM week
UNION ALL
SELECT * FROM month
order by time_type, Revenue desc;
```

**Bảng kết quả từ BigQuery (Top kết quả theo Tháng):**
| Row | time_type | time | source | Revenue ($ USD) |
| :---: | :---: | :---: | :--- | :---: |
| 1 | Month | 201706 | `(direct)` | **$97,333.62** |
| 2 | Month | 201706 | `google` | **$18,757.18** |
| 3 | Month | 201706 | `dfa` | **$8,862.23** |
| 4 | Month | 201706 | `mail.google.com` | **$2,563.13** |
| 5 | Month | 201706 | `search.myway.com` | **$105.94** |
| 6 | Month | 201706 | `groups.google.com` | **$101.96** |

💡 **Key Takeaways:**
- **Kênh chủ lực:** Kênh `(direct)` tạo ra **$97,333.62** doanh thu (gấp hơn 5 lần nguồn tìm kiếm `google`), chứng tỏ tập khách quen trung thành chiếm tỷ trọng chi tiêu áp đảo.
- **Hành động:** Đẩy mạnh các chương trình tri ân và cá nhân hóa trải nghiệm duyệt web cho tệp khách truy cập trực tiếp.

---

### Query 04: Tỷ lệ chuyển đổi (Conversion Rate) theo Nguồn năm 2017
> **Bài toán**: Xếp hạng các nguồn truy cập chuyển đổi tốt nhất năm 2017 (lọc các nguồn có $\ge 50$ transactions).

```sql
SELECT
    trafficSource.source source
    ,sum(totals.visits) AS visits
    ,sum(totals.transactions) AS transactions
    ,round(sum(totals.transactions) /sum(totals.visits)*100 ,2) as conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
group by source
HAVING SUM(totals.transactions) >= 50
order by conversion_rate desc;
```

**Bảng kết quả từ BigQuery:**
| Row | source | visits | transactions | conversion_rate (%) |
| :---: | :--- | :---: | :---: | :---: |
| 1 | `dfa` | 2,728 | 72 | **2.64%** |
| 2 | `(direct)` | 189,447 | 4,697 | **2.48%** |
| 3 | `google` | 179,804 | 1,661 | **0.92%** |

💡 **Key Takeaways:**
- **Hiệu suất kênh:** Quảng cáo hiển thị `dfa` có tỷ lệ chuyển đổi cao nhất (**2.64%**), theo sau là `(direct)` (**2.48%**). Trong khi đó, `google` có traffic khổng lồ nhưng tỷ lệ chuyển đổi thấp (**0.92%**).
- **Hành động:** Tinh lọc từ khóa tìm kiếm Google Ads và tăng phân bổ ngân sách sang mạng quảng cáo hiển thị `dfa`.

---

### Query 05: Độ tương tác trang: Người mua vs. Người không mua hàng (T6 & T7/2017)
> **Bài toán**: So sánh số pageviews trung bình/người dùng duy nhất giữa nhóm mua hàng và không mua hàng.

```sql
with purchaser_data AS (
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month
    ,(sum(totals.pageviews) / count(distinct fullVisitorId)) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY month
),
non_purchaser_data AS (
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month
    ,(sum(totals.pageviews) / count(distinct fullVisitorId)) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY month
)
SELECT          
  p.month
  ,p.avg_pageviews_purchase
  ,n.avg_pageviews_non_purchase
FROM purchaser_data p
LEFT JOIN non_purchaser_data n ON p.month = n.month
ORDER BY p.month;
```

**Bảng kết quả từ BigQuery:**
| Row | month | avg_pageviews_purchase | avg_pageviews_non_purchase |
| :---: | :---: | :---: | :---: |
| 1 | 201706 | **94.02** | **316.87** |
| 2 | 201707 | **124.24** | **334.06** |

💡 **Key Takeaways:**
- **Hành vi duyệt trang:** Khách **không mua** duyệt số trang gấp **~3 lần** người mua (~317–334 trang so với ~94–124 trang), cho thấy họ bị lạc trong luồng tìm kiếm sản phẩm.
- **Hành động:** Nâng cấp bộ lọc sản phẩm (kích thước, giá, danh mục) và thuật toán tìm kiếm để giúp người dùng chốt đơn nhanh hơn.

---

### Query 06: Số giao dịch trung bình trên mỗi Người mua (Tháng 7/2017)
> **Bài toán**: Tính tần suất phát sinh đơn hàng trung bình của khách hàng mua sắm trong tháng 7/2017.

```sql
SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month
    ,round(sum(totals.transactions) / count(distinct fullVisitorId),2) as Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) hits
    ,UNNEST(hits.product) product
WHERE totals.transactions >= 1
      AND product.productRevenue is not null
GROUP BY month;
```

**Bảng kết quả từ BigQuery:**
| Row | month | Avg_total_transactions_per_user |
| :---: | :---: | :---: |
| 1 | 201707 | **4.16** |

💡 **Key Takeaways:**
- **Tần suất cao:** Người mua trung bình thực hiện **4.16 giao dịch/tháng**, chứng minh mức độ gắn kết và giá trị vòng đời (LTV) của khách hàng mua sắm rất lớn.
- **Hành động:** Xây dựng cơ chế tích điểm khách hàng thân thiết để duy trì tỷ lệ quay lại mua hàng.

---

### Query 07: Tỷ trọng doanh thu theo Thiết bị phần cứng (Tháng 7/2017)
> **Bài toán**: Đo lường đóng góp doanh thu của Desktop, Mobile, Tablet trong tháng 7/2017 bằng Window Function `SUM(...) OVER()`.

```sql
with device_revenue AS (
  SELECT
    device.deviceCategory AS device
    ,sum(product.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
  WHERE totals.transactions IS NOT NULL
         AND product.productRevenue IS NOT NULL
  GROUP BY device
)
SELECT
    device
    ,revenue_by_device
    ,SUM(revenue_by_device) OVER() AS total_revenue
    ,ROUND(revenue_by_device * 100 / SUM(revenue_by_device) OVER(), 2) AS ratio
FROM device_revenue
ORDER BY ratio DESC;
```

**Bảng kết quả từ BigQuery:**
| Row | device | revenue_by_device ($ USD) | total_revenue ($ USD) | ratio (%) |
| :---: | :--- | :---: | :---: | :---: |
| 1 | **desktop** | **$153,459.89** | $160,909.86 | **95.37%** |
| 2 | **mobile** | **$6,897.82** | $160,909.86 | **4.29%** |
| 3 | **tablet** | **$552.15** | $160,909.86 | **0.34%** |

💡 **Key Takeaways:**
- **Lệch pha phần cứng:** Desktop chiếm **95.37%** doanh thu, trong khi Mobile chỉ đạt **4.29%** dù lượng truy cập di động rất cao.
- **Hành động:** Rút gọn quy trình thanh toán trên Mobile từ 4 bước xuống 2 bước và tích hợp Google Pay / Apple Pay 1-click checkout.

---

### Query 08: Khai phá Giỏ hàng (Cross-Selling / Market Basket Analysis)
> **Bài toán**: Tìm các sản phẩm được mua kèm nhiều nhất với áo *"YouTube Men's Vintage Henley"* trong tháng 7/2017.

```sql
WITH 
Henley_buyers AS (
    SELECT DISTINCT fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS h
    ,UNNEST(h.product) AS p
    WHERE p.v2ProductName = "YouTube Men's Vintage Henley"
          AND p.productRevenue IS NOT NULL
          AND totals.transactions >=1
)
SELECT
     product.v2ProductName AS ProductName
    ,SUM(productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
inner join Henley_buyers using(fullVisitorId)
WHERE totals.transactions >=1
    AND product.productRevenue IS NOT NULL
    AND product.v2ProductName != "YouTube Men's Vintage Henley"
GROUP BY product.v2ProductName
order by quantity desc;
```

**Bảng kết quả từ BigQuery:**
| Row | ProductName | quantity |
| :---: | :--- | :---: |
| 1 | **Google Sunglasses** | **20** |
| 2 | **Google Women's Vintage Hero Tee Black** | **7** |
| 3 | **SPF-15 Slim & Slender Lip Balm** | **6** |
| 4 | **Google Women's Short Sleeve Hero Tee Red Heather** | **4** |
| 5 | **YouTube Men's Fleece Hoodie Black** | **3** |
| 6 | **Google Men's Short Sleeve Badge Tee Black** | **3** |
| 7 | **YouTube Twill Cap** | **2** |

💡 **Key Takeaways:**
- **Sản phẩm mua kèm:** Khách mua áo Henley thường mua kèm phụ kiện thời trang như Kính râm Google (20 chiếc) và Son dưỡng (6 chiếc).
- **Hành động:** Tạo khối gợi ý *"Frequently Bought Together"* và bán Combo ưu đãi giảm 10% tại giỏ hàng để nâng cao AOV.

---

### Query 09: Phễu chuyển đổi E-Commerce đa tầng (Q1/2017)
> **Bài toán**: Đo lường tỷ lệ chuyển đổi qua các giai đoạn: Xem chi tiết (`action_type = '2'`) $\rightarrow$ Thêm giỏ hàng (`'3'`) $\rightarrow$ Mua hàng (`'6'`).

```sql
with product_data as(
select
    format_date('%Y%m', parse_date('%Y%m%d',date)) as month,
    count(CASE WHEN eCommerceAction.action_type = '2' THEN product.v2ProductName END) as num_product_view,
    count(CASE WHEN eCommerceAction.action_type = '3' THEN product.v2ProductName END) as num_add_to_cart,
    count(CASE WHEN eCommerceAction.action_type = '6' and product.productRevenue is not null THEN product.v2ProductName END) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
,UNNEST(hits) as hits
,UNNEST (hits.product) as product
where _table_suffix between '20170101' and '20170331'
and eCommerceAction.action_type in ('2','3','6')
group by month
order by month
)
select
    month
    ,num_product_view
    ,num_add_to_cart
    ,num_purchase
    ,round(num_add_to_cart/num_product_view * 100, 2) as add_to_cart_rate
    ,round(num_purchase/num_product_view * 100, 2) as purchase_rate
from product_data;
```

**Bảng kết quả từ BigQuery:**
| Row | month | num_product_view | num_add_to_cart | num_purchase | add_to_cart_rate (%) | purchase_rate (%) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 201701 | 25,787 | 7,342 | 2,143 | **28.47%** | **8.31%** |
| 2 | 201702 | 21,489 | 7,360 | 2,060 | **34.25%** | **9.59%** |
| 3 | 201703 | 23,549 | 8,782 | 2,977 | **37.29%** | **12.64%** |

💡 **Key Takeaways:**
- **Tối ưu phễu:** Tỷ lệ mua hàng tăng liên tục từ **8.31% lên 12.64%** (tăng trưởng tương đối **+52.1%**), tỷ lệ thêm giỏ hàng cũng tăng mạnh từ **28.47% lên 37.29%**.
- **Hành động:** Duy trì các chính sách kích thích thêm vào giỏ và tối ưu giao diện giỏ hàng đã áp dụng trong quý 1.

---

### Query 10: Tốc độ doanh thu theo tuần & Doanh thu lũy kế (T5 – T7/2017)
> **Bài toán**: Tính doanh thu theo tuần và doanh thu cộng dồn lũy kế từ tháng 5 đến tháng 7/2017 bằng `SUM(...) OVER (ORDER BY week)`.

```sql
WITH weekly_rev_data AS (
    SELECT
         format_date('%Y-%W', parse_date('%Y%m%d', date)) AS week
        ,round(SUM(p.productRevenue) / 1000000,2) AS weekly_revenue
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
        ,UNNEST(hits) AS h
        ,UNNEST(h.product) AS p
    WHERE _TABLE_SUFFIX BETWEEN '0501' AND '0731'
           AND p.productRevenue IS NOT NULL
    GROUP BY week
)
SELECT
     week
    ,weekly_revenue
    ,round(SUM(weekly_revenue) OVER (ORDER BY week),2) AS cumulative_revenue
FROM weekly_rev_data
ORDER BY week;
```

**Bảng kết quả từ BigQuery (Toàn bộ 13 tuần):**
| Row | week | weekly_revenue ($ USD) | cumulative_revenue ($ USD) |
| :---: | :---: | :---: | :---: |
| 1 | `2017-18` | $32,588.71 | $32,588.71 |
| 2 | `2017-19` | $34,741.41 | $67,330.12 |
| 3 | `2017-20` | $27,606.74 | $94,936.86 |
| 4 | `2017-21` | $20,198.54 | $115,135.40 |
| 5 | `2017-22` | $31,789.52 | $146,924.92 |
| 6 | `2017-23` | $19,751.87 | $166,676.79 |
| 7 | `2017-24` | $45,053.91 | $211,730.70 |
| 8 | `2017-25` | $28,583.26 | $240,313.96 |
| 9 | `2017-26` | $24,813.41 | $265,127.37 |
| 10 | `2017-27` | $20,437.74 | $285,565.11 |
| 11 | `2017-28` | $41,250.80 | $326,815.91 |
| 12 | `2017-29` | **$57,111.46** | $383,927.37 |
| 13 | `2017-30` | $29,493.94 | **$413,421.31** |

💡 **Key Takeaways:**
- **Đỉnh doanh thu:** Tuần 29 đạt kỷ lục **$57,111.46**; tổng doanh thu lũy kế sau 13 tuần vượt mốc **$413,421.31**.
- **Hành động:** Phân tích chiến dịch khuyến mãi của tuần 29 để chuẩn hóa thành công thức chạy chiến dịch cho các mùa cao điểm kế tiếp.

---

## 🎯 5. Final Insights & Strategic Recommendations (Chiến lược hành động)

| Trụ cột chiến lược | Thực trạng cốt lõi (Data Finding) | Đề xuất hành động kinh doanh (Actionable Solution) |
| :--- | :--- | :--- |
| **1. Giải quyết điểm nghẽn Mobile** | Desktop chiếm **95.37%** doanh thu, Mobile chỉ chiếm **4.29%** dù traffic lớn. | Tích hợp Apple Pay / Google Pay và rút ngắn luồng checkout từ 4 bước xuống 2 bước. |
| **2. Tối ưu tìm kiếm cho Non-Purchasers** | Người không mua xem tới **~320 trang/người** (gấp 3 lần người mua ~100 trang). | Bổ sung thanh tìm kiếm thông minh (auto-complete) và bộ lọc theo giá/size để người dùng không bị lạc. |
| **3. Tối ưu ngân sách Marketing** | Kênh hiển thị `dfa` chuyển đổi **2.64%**, vượt trội so với tìm kiếm `google` (**0.92%**). | Chuyển bớt ngân sách sang Display Ads Retargeting và lọc từ khóa Google Ads có tỷ lệ thoát cao. |
| **4. Bán Combo & Cross-Selling** | Khách mua áo Henley thường mua kèm Kính râm (20 lượt) và Áo thun đen (7 lượt). | Tạo gói Combo *"Summer Outing Pack"* (Áo + Kính râm) giảm 10% tại giỏ hàng để gia tăng AOV. |


---

## 👤 Author & Contact

**Nguyễn Xuân Thu**
- 🐙 GitHub: [@thunx280-ctrl](https://github.com/thunx280-ctrl)
- 💼 LinkedIn: [Nguyen Xuan Thu](https://linkedin.com)
- 📧 Email: `thu.nx280@gmail.com`
