# 🛒 E-Commerce RFM Analytics

> **In-depth behavioral analysis, multi-stage conversion funnel optimization, and revenue attribution across millions of user sessions on Google Merchandise Store using Google BigQuery Standard SQL.**

---

## 📌 1. Project Overview (Tóm tắt dự án)

Dự án thực hiện phân tích hành vi người dùng và hiệu quả kinh doanh của nền tảng thương mại điện tử **Google Merchandise Store** dựa trên bộ dữ liệu thực tế **Google Analytics 360 (GA360)** lưu trữ trên nền tảng điện toán đám mây **Google BigQuery**.

Bằng việc truy vấn và bóc tách các trường dữ liệu bán cấu trúc dạng lồng nhau (`RECORD` và `REPEATED`), dự án trả lời các câu hỏi kinh doanh trọng yếu về:
1. **Lưu lượng & Tương tác**: Đánh giá biến động lượt truy cập (visits), số trang xem (pageviews) và tỷ lệ thoát (bounce rate).
2. **Kênh tiếp thị (Acquisition Channels)**: Đo lường doanh thu đóng góp và tỷ lệ chuyển đổi (conversion rate) theo từng nguồn truy cập.
3. **Hành vi người mua (User Engagement)**: So sánh thói quen duyệt trang giữa nhóm khách mua hàng (purchasers) và không mua hàng (non-purchasers).
4. **Đóng góp phần cứng (Device Performance)**: Xác định tỷ trọng doanh thu giữa Desktop, Mobile và Tablet.
5. **Khai phá giỏ hàng (Market Basket Analysis)**: Phân tích các sản phẩm thường được mua kèm để tối ưu hóa chiến lược Cross-selling / Upselling.
6. **Tối ưu phễu chuyển đổi (Conversion Funnel)**: Đo lường tỷ lệ rớt phễu qua các giai đoạn từ Xem sản phẩm $\rightarrow$ Thêm vào giỏ $\rightarrow$ Mua hàng thành công.
7. **Doanh thu tích lũy (Cumulative Revenue)**: Theo dõi tốc độ tăng trưởng doanh thu theo tuần và lũy kế.

---

## 📖 2. Data Dictionary (Từ điển dữ liệu)

Bảng dữ liệu nguồn: `bigquery-public-data.google_analytics_sample.ga_sessions_*` (dữ liệu phân vùng theo ngày từ 08/2016 đến 08/2017).

| Tên trường (Field Name) | Kiểu dữ liệu | Mô tả chi tiết |
| :--- | :---: | :--- |
| `fullVisitorId` | `STRING` | Mã định danh duy nhất của mỗi người dùng (Visitor ID). |
| `date` | `STRING` | Ngày diễn ra phiên truy cập, định dạng `YYYYMMDD`. |
| `totals.visits` | `INTEGER` | Số lượt truy cập (mặc định = 1 cho mỗi phiên hợp lệ). |
| `totals.pageviews` | `INTEGER` | Tổng số lượt xem trang trong một phiên truy cập. |
| `totals.bounces` | `INTEGER` | Tổng số lần thoát trang đơn (1 nếu rời đi ngay, `NULL` nếu tương tác tiếp). |
| `totals.transactions` | `INTEGER` | Số lượng đơn hàng được thanh toán thành công trong phiên. |
| `trafficSource.source` | `STRING` | Nguồn gốc lưu lượng truy cập (vd: `google`, `(direct)`, `youtube.com`, `dealspotr.com`). |
| `device.deviceCategory` | `STRING` | Loại thiết bị người dùng sử dụng (`desktop`, `mobile`, `tablet`). |
| `hits` | `RECORD (REPEATED)` | Mảng chứa toàn bộ tương tác/sự kiện chi tiết phát sinh trong phiên. |
| `hits.eCommerceAction.action_type` | `STRING` | Mã hành vi thương mại điện tử trong phiên: <br>• `'2'` = Xem chi tiết sản phẩm (Product Detail View)<br>• `'3'` = Thêm sản phẩm vào giỏ (Add to Cart)<br>• `'6'` = Hoàn tất mua hàng (Completed Purchase) |
| `hits.product` | `RECORD (REPEATED)` | Mảng lồng nhau chứa thông tin các sản phẩm xuất hiện trong hit. |
| `hits.product.v2ProductName` | `STRING` | Tên chính thức của sản phẩm hiển thị trên website. |
| `hits.product.productQuantity` | `INTEGER` | Số lượng sản phẩm được đặt mua trong đơn hàng. |
| `hits.product.productRevenue` | `INTEGER` | Doanh thu sản phẩm dạng vi đơn vị (micro-units). **Cần chia $1,000,000$** để chuyển đổi sang USD. |

---

## ⚡ 3. Advanced SQL Highlights (Kỹ thuật SQL áp dụng)

- **Unnesting Nested & Repeated Data**: Sử dụng cú pháp `UNNEST(hits) AS hits, UNNEST(hits.product) AS product` để bóc tách dữ liệu mảng lồng nhau nhiều cấp độ.
- **Partition & Shard Pruning**: Tối ưu hóa chi phí quét dữ liệu trên BigQuery bằng cách lọc tiền tố `_TABLE_SUFFIX BETWEEN ...`.
- **Window Functions**:
  - `SUM(...) OVER()`: Tính tổng doanh thu toàn hệ thống để tính phần trăm đóng góp không cần thực hiện `JOIN`.
  - `SUM(...) OVER (ORDER BY week)`: Tính doanh thu lũy kế (cumulative revenue) theo dòng thời gian.
- **Common Table Expressions (CTEs)**: Tạo các khối truy vấn trung gian logic (`WITH ...`), giúp cấu trúc code tường minh, dễ kiểm thử và tối ưu hiệu năng.
- **Conditional Aggregation**: Kết hợp `COUNT(CASE WHEN ... END)` để dựng phễu chuyển đổi nhiều bước trong một câu truy vấn duy nhất.

---

## 🔍 4. Analytics Deep-Dive: 10 Analytical Questions

### Question 01: Lưu lượng truy cập, Lượt xem trang & Giao dịch Q1/2017
> **Bài toán**: Tính tổng số lượt truy cập (visits), tổng số trang xem (pageviews) và số lượng giao dịch thành công (transactions) trong các tháng 1, 2 và 3 năm 2017.

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

**Kết quả truy vấn:**
| Month | Visits | Pageviews | Transactions |
| :---: | :---: | :---: | :---: |
| **201701** | 64,711 | 264,887 | 713 |
| **201702** | 62,192 | 244,142 | 733 |
| **201703** | 69,892 | 298,875 | 993 |

💡 **Insight**: Tháng 3/2017 chứng kiến sự bứt phá mạnh mẽ: lượng visits tăng **+12.4%** so với tháng 2, đặc biệt số giao dịch tăng vọt **+35.5%** (từ 733 lên 993 đơn), cho thấy nhu cầu mua sắm và hiệu quả chốt đơn tăng cao rõ rệt khi bước vào mùa xuân.

---

### Question 02: Tỷ lệ thoát trang (Bounce Rate) theo Nguồn truy cập (Tháng 7/2017)
> **Bài toán**: Xác định tỷ lệ thoát theo từng nguồn traffic trong tháng 7/2017 để đánh giá chất lượng nguồn dẫn. $\text{Bounce Rate (\%)} = \frac{\sum(\text{totals.bounces})}{\sum(\text{totals.visits})} \times 100$.

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

**Kết quả truy vấn (Top nguồn lưu lượng):**
| Traffic Source | Total Visits | Total Bounces | Bounce Rate (%) |
| :--- | :---: | :---: | :---: |
| `google` | 38,400 | 19,798 | **51.557%** |
| `(direct)` | 19,891 | 8,606 | **43.266%** |
| `youtube.com` | 6,351 | 4,238 | **66.730%** |
| `analytics.google.com` | 1,972 | 1,064 | **53.955%** |
| `Partners` | 1,783 | 936 | **52.496%** |
| `m.facebook.com` | 669 | 496 | **74.141%** |

💡 **Insight**: Lượng truy cập chuyển tiếp từ mạng xã hội/video có tỷ lệ thoát rất cao (`youtube.com` đạt **66.73%**, `m.facebook.com` lên tới **74.14%**). Người dùng từ các kênh này thường chỉ lướt xem rồi thoát, đòi hỏi doanh nghiệp cần thiết kế Landing Page riêng biệt, tối ưu cho giao diện di động thay vì dẫn thẳng về trang chủ.

---

### Question 03: Doanh thu theo Nguồn truy cập theo Tuần và Tháng (Tháng 6/2017)
> **Bài toán**: Tính toán doanh thu đóng góp của từng nguồn truy cập trong tháng 6/2017 phân tách theo tuần và theo tháng bằng kỹ thuật CTEs kết hợp `UNION ALL`.

```sql
WITH
  week AS (
    SELECT
      'Week' AS time_type,
      format_date('%Y%V', parse_date('%Y%m%d', date)) AS time,
      trafficSource.source AS source,
      round(sum(productRevenue) / 1000000, 4) AS Revenue  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
      UNNEST(hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE productRevenue IS NOT NULL
    GROUP BY time_type, source, time
  ),
  month AS (
    SELECT
      'Month' AS time_type,
      format_date('%Y%m', parse_date('%Y%m%d', date)) AS time,
      trafficSource.source AS source,
      round(sum(productRevenue) / 1000000, 4) AS Revenue  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
      UNNEST(hits) AS hits,
      UNNEST(hits.product) AS product
    WHERE productRevenue IS NOT NULL
    GROUP BY time_type, source, time
  )
SELECT * FROM week
UNION ALL
SELECT * FROM month
ORDER BY time_type, Revenue DESC;
```

**Kết quả tiêu biểu (Top nguồn đóng góp doanh thu tháng 6/2017):**
| Time Type | Time Period | Traffic Source | Revenue ($ USD) |
| :---: | :---: | :--- | :---: |
| Month | 201706 | `(direct)` | **$97,333.62** |
| Month | 201706 | `google` | **$18,757.18** |
| Month | 201706 | `dfa` | **$8,862.23** |
| Month | 201706 | `mail.google.com` | **$2,563.13** |

💡 **Insight**: Lưu lượng trực tiếp `(direct)` tạo ra tới **$97,333** doanh thu (áp đảo so với kênh `google` ở mức $18,757), khẳng định độ nhận diện thương hiệu cực kỳ lớn và tập khách hàng trung thành thường xuyên gõ trực tiếp URL để mua lại hàng.

---

### Question 04: Tỷ lệ chuyển đổi (Conversion Rate) theo Nguồn năm 2017
> **Bài toán**: Tìm các kênh tiếp thị chuyển đổi hiệu quả nhất trong cả năm 2017 (lọc các kênh có từ 50 đơn hàng trở lên để đảm bảo ý nghĩa thống kê).

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

**Kết quả truy vấn:**
| Traffic Source | Visits | Transactions | Conversion Rate (%) |
| :--- | :---: | :---: | :---: |
| `dealspotr.com` | 543 | 56 | **10.31%** |
| `mail.google.com` | 2,815 | 122 | **4.33%** |
| `(direct)` | 177,295 | 4,295 | **2.42%** |
| `google` | 382,211 | 4,493 | **1.18%** |
| `dfa` | 8,421 | 56 | **0.67%** |

💡 **Insight**: Nguồn website khuyến mãi/affiliate `dealspotr.com` có tỷ lệ chuyển đổi dẫn đầu tuyệt đối với **10.31%** (gấp gần 10 lần so với tìm kiếm tự nhiên của Google là 1.18%). Kênh Email Marketing (`mail.google.com`) cũng đạt tỷ lệ ấn tượng **4.33%**, cho thấy khách hàng đến từ coupon và email có chủ đích mua sắm ngay lập tức.

---

### Question 05: Độ tương tác trang: Người mua vs. Người không mua hàng (T6 & T7/2017)
> **Bài toán**: So sánh số lượt xem trang trung bình trên mỗi người dùng duy nhất (`fullVisitorId`) giữa nhóm khách có phát sinh giao dịch so với nhóm không mua hàng.

```sql
WITH purchaser_data AS (
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month,
    (sum(totals.pageviews) / count(distinct fullVisitorId)) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
  GROUP BY month
),
non_purchaser_data AS (
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month,
    (sum(totals.pageviews) / count(distinct fullVisitorId)) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND product.productRevenue IS NULL
  GROUP BY month
)
SELECT          
  p.month,
  round(p.avg_pageviews_purchase, 2) AS avg_pageviews_purchase,
  round(n.avg_pageviews_non_purchase, 2) AS avg_pageviews_non_purchase
FROM purchaser_data p
LEFT JOIN non_purchaser_data n ON p.month = n.month
ORDER BY p.month;
```

**Kết quả truy vấn:**
| Month | Avg Pageviews (Purchasers) | Avg Pageviews (Non-Purchasers) |
| :---: | :---: | :---: |
| **201706** | **94.67** | **316.87** |
| **201707** | **124.24** | **334.06** |

💡 **Insight**: Điểm bất ngờ lớn: Khách hàng **không mua hàng** duyệt qua số lượng trang cao gấp 2.7–3.3 lần khách mua hàng (~317–334 trang so với ~95–124 trang). Điều này phản ánh nhóm khách không chốt được đơn thường rơi vào vòng lặp tìm kiếm, gặp khó khăn khi tìm kiếm sản phẩm phù hợp. Cần cải thiện thanh công cụ tìm kiếm, bộ lọc thông minh (search filters) và hiển thị gợi ý sản phẩm tốt hơn.

---

### Question 06: Số giao dịch trung bình trên mỗi Người mua (Tháng 7/2017)
> **Bài toán**: Tính tần suất phát sinh đơn hàng trung bình của những khách hàng thực sự mua sắm trong tháng 7/2017.

```sql
SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month,
    round(sum(totals.transactions) / count(distinct fullVisitorId), 2) AS Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE totals.transactions >= 1
      AND product.productRevenue IS NOT NULL
GROUP BY month;
```

**Kết quả truy vấn:**
| Month | Avg Transactions per Buyer |
| :---: | :---: |
| **201707** | **4.16** |

💡 **Insight**: Trung bình mỗi người mua hoàn tất **4.16 giao dịch** chỉ trong vòng 1 tháng. Điều này chứng minh giá trị vòng đời (Customer Lifetime Value - LTV) của tệp khách hàng mua sắm là rất cao, doanh nghiệp nên tập trung vào các chương trình khách hàng thân thiết (loyalty programs) để gia tăng tần suất quay lại.

---

### Question 07: Tỷ trọng doanh thu theo Thiết bị phần cứng (Tháng 7/2017)
> **Bài toán**: Đo lường đóng góp doanh thu của các loại thiết bị (`desktop`, `mobile`, `tablet`) và tỷ lệ phần trăm tương ứng bằng Window Function `SUM(...) OVER()`.

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

**Kết quả truy vấn:**
| Device Category | Revenue ($ USD) | Total Revenue ($ USD) | Revenue Share (%) |
| :--- | :---: | :---: | :---: |
| **Desktop** | **$159,920.49** | $166,334.80 | **96.14%** |
| **Mobile** | **$5,404.91** | $166,334.80 | **3.25%** |
| **Tablet** | **$1,009.40** | $166,334.80 | **0.61%** |

💡 **Insight**: Desktop đóng góp tới **96.14%** tổng doanh thu toàn sàn. Dù lưu lượng truy cập từ Mobile rất lớn, doanh thu mang lại chỉ vỏn vẹn **3.25%**. Đây là dấu hiệu của rào cản thanh toán nghiêm trọng trên thiết bị di động (quy trình thanh toán rườm rà, chưa tối ưu One-Click Checkout qua Apple Pay/Google Pay).

---

### Question 08: Khai phá Giỏ hàng (Cross-Selling / Market Basket Analysis)
> **Bài toán**: Tìm các sản phẩm được mua kèm nhiều nhất bởi những khách hàng đã mua sản phẩm *"YouTube Men's Vintage Henley"* trong tháng 7/2017.

```sql
WITH Henley_buyers AS (
    SELECT DISTINCT fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
      UNNEST(hits) AS h,
      UNNEST(h.product) AS p
    WHERE p.v2ProductName = "YouTube Men's Vintage Henley"
      AND p.productRevenue IS NOT NULL
      AND totals.transactions >= 1
)
SELECT
    product.v2ProductName,
    SUM(productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
INNER JOIN Henley_buyers USING (fullVisitorId)
WHERE totals.transactions >= 1
  AND product.productRevenue IS NOT NULL
  AND product.v2ProductName != "YouTube Men's Vintage Henley"
GROUP BY product.v2ProductName
ORDER BY quantity DESC;
```

**Top 5 sản phẩm mua kèm nhiều nhất:**
| Rank | Sản phẩm mua kèm | Số lượng mua cùng (Quantity) |
| :---: | :--- | :---: |
| 1 | **Google Sunglasses** | **20** |
| 2 | **Google Women's Vintage Hero Tee Black** | **7** |
| 3 | **Google Men's Vintage Badge Tee Black** | **7** |
| 4 | **Android Mountain View Short Sleeve T-Shirt** | **6** |
| 5 | **Google Lip Balm Splash** | **6** |

💡 **Insight**: Khách hàng mua áo thun Henley rất thích phụ kiện thời trang dạo phố (Kính râm Google Sunglasses - 20 chiếc) và các mẫu áo thun đen khác. Doanh nghiệp có thể thiết lập ngay tính năng *"Gợi ý mua kèm"* hoặc bán gói Combo với mức giảm giá 10% để gia tăng ngay giá trị đơn hàng trung bình (AOV).

---

### Question 09: Phễu chuyển đổi E-Commerce đa tầng (Q1/2017)
> **Bài toán**: Xây dựng phễu chuyển đổi từ: **Xem chi tiết sản phẩm** (`action_type = '2'`) $\rightarrow$ **Thêm vào giỏ hàng** (`action_type = '3'`) $\rightarrow$ **Thanh toán thành công** (`action_type = '6'`).

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

**Bảng tỷ lệ chuyển đổi qua các giai đoạn:**
| Month | Product Views | Add to Cart | Purchases | Add-to-Cart Rate (%) | Purchase Rate (%) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **201701** | 25,787 | 7,342 | 2,143 | **28.47%** | **8.31%** |
| **201702** | 21,489 | 7,360 | 2,060 | **34.25%** | **9.59%** |
| **201703** | 23,549 | 8,782 | 2,977 | **37.29%** | **12.64%** |

💡 **Insight**: Hiệu suất phễu chuyển đổi tăng trưởng ấn tượng trong suốt quý 1:
- Tỷ lệ thêm vào giỏ tăng đều từ **28.47% lên 37.29%** (+8.82 điểm %).
- Tỷ lệ hoàn tất mua hàng tăng vượt bậc từ **8.31% lên 12.64%** (tăng trưởng tương đối **+52.1%**), phản ánh việc các rào cản trong giỏ hàng đã được xử lý tốt và khách hàng có độ tin tưởng mua sắm cao hơn.

---

### Question 10: Tốc độ doanh thu theo tuần & Doanh thu lũy kế (T5 – T7/2017)
> **Bài toán**: Tính doanh thu theo từng tuần và doanh thu cộng dồn từ tuần đầu tiên đến thời điểm hiện tại bằng Window Function `SUM(...) OVER (ORDER BY week)`.

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

**Bảng doanh thu tuần & lũy kế:**
| Week | Weekly Revenue ($ USD) | Cumulative Revenue ($ USD) |
| :---: | :---: | :---: |
| `2017-18` | $12,382.47 | $12,382.47 |
| `2017-19` | $16,773.85 | $29,156.32 |
| `2017-20` | $10,030.70 | $39,187.02 |
| `2017-21` | $14,642.50 | $53,829.52 |
| `2017-22` | $15,649.07 | $69,478.59 |
| `2017-23` | $16,339.46 | $85,818.05 |
| `2017-24` | $19,410.63 | $105,228.68 |
| `2017-25` | **$46,654.54** | $151,883.22 |
| `2017-26` | $23,059.85 | $174,943.07 |
| `2017-27` | $18,485.49 | $193,428.56 |
| `2017-28` | $14,945.71 | $208,374.27 |
| `2017-29` | $19,052.95 | $227,427.22 |
| `2017-30` | $24,196.26 | $251,623.48 |
| `2017-31` | $8,898.37 | **$260,521.85** |

💡 **Insight**: Tuần 25 (`2017-25`) đạt đỉnh doanh thu đột biến **$46,654.54** (cao gấp 2.5 lần mức trung bình các tuần còn lại), thường ứng với chiến dịch Summer Sale hoặc đơn đặt hàng số lượng lớn của khách hàng B2B. Tổng doanh thu lũy kế 14 tuần đạt mốc **$260,521.85**.

---

## 🎯 5. Final Insights & Strategic Recommendations (Insight tổng kết & Đề xuất hành động)

Dựa trên toàn bộ kết quả phân tích số liệu thực nghiệm, dưới đây là 4 trụ cột chiến lược hành động nhằm tối ưu hóa chuyển đổi và mở rộng doanh thu:

```text
               CHIẾN LƯỢC TỐI ƯU HÓA E-COMMERCE & DOANH THU
                                    │
  ┌──────────────────┬──────────────┴─────┬──────────────────┐
  ▼                  ▼                    ▼                  ▼
Trụ cột 1          Trụ cột 2            Trụ cột 3          Trụ cột 4
Giải quyết điểm    Tối ưu hóa hành      Mở rộng & Nhân     Chiến lược Cross-sell
nghẽn trên Mobile  trình tìm kiếm       rộng kênh Hot      & Bán theo Combo
(96% từ Desktop)   (Non-purchaser Loop) (Dealspotr & Mail) (Henley + Sunglasses)
```

### 1. Xóa bỏ rào cản thanh toán trên thiết bị di động (Solve Mobile Checkout Friction)
- **Vấn đề**: Desktop chiếm áp đảo **96.14%** doanh thu, trong khi Mobile chỉ mang lại **3.25%** dù chiếm lưu lượng truy cập cao và tỷ lệ thoát cao (Facebook Mobile bounce rate lên tới 74.1%).
- **Đề xuất**: 
  - Tối ưu hóa UI/UX phiên bản Mobile Web: Tích hợp ngay thanh toán 1 chạm (Apple Pay / Google Pay / PayPal).
  - Rút ngắn phễu thanh toán di động từ 4 bước xuống còn 2 bước, cho phép chế độ Guest Checkout (thanh toán không bắt buộc tạo tài khoản trước).

### 2. Cải thiện trải nghiệm tìm kiếm để cứu tập khách hàng "bị lạc" (Reduce Search Loops)
- **Vấn đề**: Người không mua hàng xem tới **~320 trang/người** (gấp hơn 3 lần so với người mua ~100 trang), minh chứng rõ ràng họ có nhu cầu mua sắm lớn nhưng bị lạc trong danh mục và không tìm thấy sản phẩm ưng ý.
- **Đề xuất**:
  - Nâng cấp công cụ tìm kiếm: Tích hợp gợi ý từ khóa thông minh (Auto-complete) và sửa lỗi chính tả.
  - Tinh giản bộ lọc sản phẩm (Facet Filters) theo màu sắc, kích cỡ, mức giá để khách hàng tiếp cận sản phẩm mục tiêu trong dưới 3 lần nhấp chuột.

### 3. Tái phân bổ ngân sách vào các kênh có tỷ lệ chuyển đổi cao (Scale High-Converting Channels)
- **Vấn đề**: Kênh Coupon (`dealspotr.com`) đạt tỷ lệ chuyển đổi **10.31%**, và Email Marketing (`mail.google.com`) đạt **4.33%** (vượt xa kênh tự nhiên 1.18%).
- **Đề xuất**:
  - Đẩy mạnh hợp tác Affiliate với các trang mã giảm giá uy tín cho các sản phẩm cận date hoặc tồn kho cao.
  - Xây dựng hệ thống Email Automation: Gửi email nhắc nhở giỏ hàng bỏ quên (Abandoned Cart Recovery) sau 2 tiếng và 24 tiếng với mã giảm giá độc quyền 5%.

### 4. Thiết lập gói sản phẩm mua kèm tự động (Automated Cross-Selling Bundles)
- **Vấn đề**: Khách mua áo *"YouTube Men's Vintage Henley"* thường xuyên mua kèm Kính râm *Google Sunglasses* (20 lượt) và các áo thun vintage khác.
- **Đề xuất**:
  - Triển khai thuật toán gợi ý sản phẩm liên quan (Frequently Bought Together) ngay dưới nút "Thêm vào giỏ hàng".
  - Đóng gói Combo *"Summer Streetwear Pack"* (Áo Henley + Kính râm) với giá ưu đãi giảm 10% nhằm nâng cao trực tiếp Giá trị đơn hàng trung bình (AOV).

---


## 👤  Author & Contact

**Nguyễn Xuân Thu**
- 🐙 GitHub: [@thunx280-ctrl](https://github.com/thunx280-ctrl)
- 💼 LinkedIn: [Nguyen Xuan Thu](https://linkedin.com)
- 📧 Email: `thu.nx280@gmail.com`
