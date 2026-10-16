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

## ⚡ 3. Advanced SQL Highlights (Kỹ thuật SQL áp dụng)

- **Unnesting Nested & Repeated Data**: Sử dụng cú pháp `UNNEST(hits) AS hits, UNNEST(hits.product) AS product` để bóc tách dữ liệu mảng lồng nhau nhiều cấp độ.
- **Partition & Shard Pruning**: Tối ưu hóa chi phí quét dữ liệu trên BigQuery bằng cách lọc tiền tố `_TABLE_SUFFIX BETWEEN ...`.
- **Window Functions**:
  - `SUM(...) OVER()`: Tính tổng doanh thu toàn hệ thống để tính phần trăm đóng góp không cần thực hiện `JOIN`.
  - `SUM(...) OVER (ORDER BY week)`: Tính doanh thu lũy kế (cumulative revenue) theo dòng thời gian.
- **Common Table Expressions (CTEs)**: Tạo các khối truy vấn trung gian logic (`WITH ...`), giúp cấu trúc code tường minh, dễ kiểm thử và tối ưu hiệu năng.
- **Conditional Aggregation**: Kết hợp `COUNT(CASE WHEN ... END)` để dựng phễu chuyển đổi nhiều bước trong một câu truy vấn duy nhất.

---

## 🔍 4. Analytics Deep-Dive: 10 Analytical Queries (Số liệu thực tế từ BigQuery)

### Query 01: Lưu lượng truy cập, Lượt xem trang & Giao dịch Q1/2017
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

**Kết quả truy vấn thực tế:**
| Month | Visits | Pageviews | Transactions |
| :---: | :---: | :---: | :---: |
| **201701** | 64,694 | 257,708 | 713 |
| **201702** | 62,192 | 233,373 | 733 |
| **201703** | 69,931 | 259,522 | 993 |

💡 **Insight**: Tháng 3/2017 ghi nhận sự bứt phá toàn diện: lượng visits tăng **+12.4%** so với tháng 2, đặc biệt số giao dịch thành công tăng vọt **+35.5%** (từ 733 lên 993 đơn), cho thấy tỷ lệ chốt đơn và nhu cầu mua sắm phục hồi mạnh mẽ sau dịp đầu năm.

---

### Query 02: Tỷ lệ thoát trang (Bounce Rate) theo Nguồn truy cập (Tháng 7/2017)
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

**Kết quả truy vấn thực tế (Top nguồn lưu lượng):**
| Traffic Source | Total Visits | Total Bounces | Bounce Rate (%) |
| :--- | :---: | :---: | :---: |
| `google` | 38,400 | 19,798 | **51.56%** |
| `(direct)` | 19,891 | 8,606 | **43.27%** |
| `youtube.com` | 6,351 | 4,238 | **66.73%** |
| `analytics.google.com` | 1,972 | 1,064 | **53.96%** |

💡 **Insight**: Nguồn dẫn từ `youtube.com` có tỷ lệ thoát lên tới **66.73%**, cao hơn nhiều so với kênh truy cập trực tiếp `(direct)` (43.27%). Người dùng đến từ video có xu hướng tò mò nhấp vào nhưng rời đi ngay. Cần xây dựng Landing Page riêng cho người dùng từ YouTube với các ưu đãi kích thích trải nghiệm duyệt hàng.

---

### Query 03: Doanh thu theo Nguồn truy cập theo Tuần và Tháng (Tháng 6/2017)
> **Bài toán**: Phân bổ doanh thu của từng nguồn truy cập trong tháng 6/2017 theo tuần và tháng bằng kỹ thuật CTEs kết hợp `UNION ALL`.

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

**Kết quả truy vấn thực tế (Top nguồn đóng góp doanh thu tháng 6/2017):**
| Time Type | Time Period | Traffic Source | Revenue ($ USD) |
| :---: | :---: | :--- | :---: |
| Month | 201706 | `(direct)` | **$97,333.62** |
| Week | 201724 | `(direct)` | **$30,908.91** |
| Week | 201725 | `(direct)` | **$27,295.32** |
| Month | 201706 | `google` | **$18,757.18** |

💡 **Insight**: Lưu lượng trực tiếp `(direct)` mang lại tới **$97,333.62** doanh thu trong tháng 6 (chiếm hơn 80% tổng doanh thu các kênh chính, gấp hơn 5 lần kênh `google` ở mức $18,757.18). Điều này phản ánh lòng trung thành thương hiệu mạnh mẽ từ tệp khách hàng quen thuộc.

---

### Query 04: Tỷ lệ chuyển đổi (Conversion Rate) theo Nguồn năm 2017
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

**Kết quả truy vấn thực tế:**
| Traffic Source | Visits | Transactions | Conversion Rate (%) |
| :--- | :---: | :---: | :---: |
| `dfa` | 2,728 | 72 | **2.64%** |
| `(direct)` | 189,447 | 4,697 | **2.48%** |
| `google` | 179,804 | 1,661 | **0.92%** |

💡 **Insight**: Kênh quảng cáo hiển thị `dfa` (DoubleClick for Advertisers) có tỷ lệ chuyển đổi cao nhất (**2.64%**), theo sát là `(direct)` (**2.48%**). Trong khi đó, tìm kiếm `google` dù đem lại lượng traffic khổng lồ (179.8k visits) nhưng conversion rate chỉ đạt **0.92%**, cho thấy cần thanh lọc từ khóa để tối ưu chi phí quảng cáo tìm kiếm trả phí.

---

### Query 05: Độ tương tác trang: Người mua vs. Người không mua hàng (T6 & T7/2017)
> **Bài toán**: So sánh số lượt xem trang trung bình trên mỗi người dùng duy nhất (`fullVisitorId`) giữa nhóm khách có phát sinh đơn hàng (`totals.transactions >= 1`) và nhóm không mua hàng.

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

**Kết quả truy vấn thực tế:**
| Month | Avg Pageviews (Purchasers) | Avg Pageviews (Non-Purchasers) |
| :---: | :---: | :---: |
| **201706** | **94.02** | **316.87** |
| **201707** | **124.24** | **334.06** |

💡 **Insight**: Nhóm khách hàng **không mua hàng** duyệt qua số trang cực lớn (316–334 trang/người), cao gấp 2.7–3.3 lần nhóm người mua (94–124 trang). Điều này chỉ ra rằng nhóm không mua hàng rất quan tâm nhưng bị lạc trong luồng duyệt web hoặc gặp khó khăn khi tìm kiếm sản phẩm mong muốn. Tối ưu công cụ tìm kiếm nội bộ và bộ lọc danh mục là chìa khóa then chốt để chuyển đổi tập khách hàng này.

---

### Query 06: Số giao dịch trung bình trên mỗi Người mua (Tháng 7/2017)
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

**Kết quả truy vấn thực tế:**
| Month | Avg Transactions per Buyer |
| :---: | :---: |
| **201707** | **4.16** |

💡 **Insight**: Khách hàng mua sắm trong tháng 7 thực hiện trung bình **4.16 giao dịch/người**. Đây là tỷ lệ mua lại (repeat purchase rate) rất cao, chứng minh tệp khách hàng mua sắm có mức độ hài lòng cao và gắn bó mật thiết với nền tảng.

---

### Query 07: Tỷ trọng doanh thu theo Thiết bị phần cứng
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
    round(revenue_by_device, 2) AS revenue_by_device,
    round(SUM(revenue_by_device) OVER(), 2) AS total_revenue,
    ROUND(revenue_by_device * 100 / SUM(revenue_by_device) OVER(), 2) AS ratio
FROM device_revenue
ORDER BY ratio DESC;
```

**Kết quả truy vấn thực tế:**
| Device Category | Revenue ($ USD) | Total Revenue ($ USD) | Revenue Share (%) |
| :--- | :---: | :---: | :---: |
| **Desktop** | **$1,674,745.74** | $1,742,046.97 | **96.14%** |
| **Mobile** | **$56,553.10** | $1,742,046.97 | **3.25%** |
| **Tablet** | **$10,748.13** | $1,742,046.97 | **0.62%** |

💡 **Insight**: Desktop áp đảo tuyệt đối với **96.14%** tổng doanh thu toàn sàn ($1.67M trên tổng $1.74M). Mobile chỉ đóng góp vỏn vẹn **3.25%**, bộc lộ điểm nghẽn nghiêm trọng trong trải nghiệm thanh toán trên di động. Việc tích hợp Google Pay / Apple Pay và rút gọn các bước checkout là ưu tiên cấp bách.

---

### Query 08: Khai phá Giỏ hàng (Cross-Selling / Market Basket Analysis)
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

**Kết quả truy vấn thực tế (Top sản phẩm mua kèm nhiều nhất):**
| Rank | Sản phẩm mua kèm (Other Purchased Products) | Số lượng mua cùng (Quantity) |
| :---: | :--- | :---: |
| 1 | **Google Sunglasses** | **20** |
| 2 | **Google Women's Vintage Hero Tee Black** | **7** |
| 3 | **SPF-15 Slim & Slender Lip Balm** | **6** |
| 4 | **Google Women's Short Sleeve Hero Tee Red Heather** | **4** |

💡 **Insight**: Khách hàng mua áo thun Henley thường xuyên mua kèm phụ kiện thời trang dạo phố (Kính râm Google Sunglasses - 20 chiếc) và áo thun Vintage nữ. Doanh nghiệp nên kích hoạt widget *"Frequently Bought Together"* trên trang sản phẩm Henley và tạo combo ưu đãi để đẩy mạnh giá trị đơn hàng trung bình (AOV).

---

### Query 09: Phễu chuyển đổi E-Commerce đa tầng (Q1/2017)
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

**Kết quả truy vấn thực tế:**
| Month | Product Views | Add to Cart | Purchases | Add-to-Cart Rate (%) | Purchase Rate (%) |
| :---: | :---: | :---: | :---: | :---: | :---: |
| **201701** | 25,787 | 7,342 | 2,143 | **28.47%** | **8.31%** |
| **201702** | 21,489 | 7,360 | 2,060 | **34.25%** | **9.59%** |
| **201703** | 23,549 | 8,782 | 2,977 | **37.29%** | **12.64%** |

💡 **Insight**: Tỷ lệ hoàn tất mua hàng tăng trưởng liên tục và vượt bậc qua từng tháng trong Q1 (từ **8.31% lên 12.64%**, tương đương mức tăng trưởng **+52.1%**). Tỷ lệ thêm vào giỏ cũng tăng mạnh từ **28.47% lên 37.29%**, khẳng định quy trình thanh toán và các chương trình khuyến mãi đầu năm đem lại hiệu quả chuyển đổi rất cao.

---

### Query 10: Tốc độ doanh thu theo tuần & Doanh thu lũy kế (T5 – T7/2017)
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

**Kết quả truy vấn thực tế (Toàn bộ 13 tuần):**
| Week | Weekly Revenue ($ USD) | Cumulative Revenue ($ USD) |
| :---: | :---: | :---: |
| `2017-18` | $32,588.71 | $32,588.71 |
| `2017-19` | $34,741.41 | $67,330.12 |
| `2017-20` | $27,606.74 | $94,936.86 |
| `2017-21` | $20,198.54 | $115,135.40 |
| `2017-22` | $31,789.52 | $146,924.92 |
| `2017-23` | $19,751.87 | $166,676.79 |
| `2017-24` | $45,053.91 | $211,730.70 |
| `2017-25` | $28,583.26 | $240,313.96 |
| `2017-26` | $24,813.41 | $265,127.37 |
| `2017-27` | $20,437.74 | $285,565.11 |
| `2017-28` | $41,250.80 | $326,815.91 |
| `2017-29` | **$57,111.46** | $383,927.37 |
| `2017-30` | $29,493.94 | **$413,421.31** |

💡 **Insight**: Tuần 29 (`2017-29`) đạt đỉnh doanh thu kỷ lục trong kỳ với **$57,111.46** (gần gấp đôi tuần thông thường). Tổng doanh thu lũy kế sau 13 tuần (tháng 5 đến tháng 7/2017) cán mốc **$413,421.31**, thể hiện đà tăng trưởng tài chính ổn định và bền vững.

---

## 🎯 5. Final Insights & Strategic Recommendations (Insight tổng kết & Đề xuất hành động)

Dựa trên toàn bộ kết quả phân tích số liệu thực nghiệm, dưới đây là 4 trụ cột chiến lược hành động nhằm tối ưu hóa chuyển đổi và mở rộng doanh thu:

```text
               CHIẾN LƯỢC TỐI ƯU HÓA E-COMMERCE & DOANH THU
                                    │
  ┌──────────────────┬──────────────┴─────┬──────────────────┐
  ▼                  ▼                    ▼                  ▼
Trụ cột 1          Trụ cột 2            Trụ cột 3          Trụ cột 4
Giải quyết điểm    Tối ưu hóa hành      Tối ưu hóa ngân    Chiến lược Cross-sell
nghẽn trên Mobile  trình tìm kiếm       sách quảng cáo     & Bán theo Combo
(96.1% từ Desktop) (Non-purchasers)     (DFA vs Google)    (Henley + Sunglasses)
```

### 1. Xóa bỏ rào cản thanh toán trên thiết bị di động (Solve Mobile Checkout Friction)
- **Thực trạng**: Desktop chiếm áp đảo **96.14%** tổng doanh thu ($1,674,745.74), trong khi Mobile chỉ mang lại vỏn vẹn **3.25%** ($56,553.10) dù lưu lượng truy cập lớn và tỷ lệ thoát trên mạng xã hội di động cao.
- **Hành động đề xuất**: 
  - Tích hợp ngay thanh toán 1 chạm (Apple Pay / Google Pay) trên Mobile Web.
  - Rút ngắn luồng checkout từ 4 bước xuống còn 2 bước, bật chế độ Guest Checkout (thanh toán nhanh không bắt buộc đăng nhập).

### 2. Tinh giản trải nghiệm tìm kiếm để cứu tập khách hàng "bị lạc" (Reduce Search Loops)
- **Thực trạng**: Khách hàng không mua duyệt trung bình tới **316–334 trang/người** (gấp 3 lần người mua với 94–124 trang). Đây là chỉ báo rõ ràng về việc khách hàng gặp khó khăn khi tìm kiếm sản phẩm phù hợp.
- **Hành động đề xuất**:
  - Tích hợp thanh công cụ tìm kiếm thông minh có gợi ý từ khóa (Auto-complete) và sửa lỗi gõ.
  - Tối ưu bộ lọc sản phẩm (Facet Filters) theo kích thước, màu sắc và khoảng giá để khách tiếp cận sản phẩm cần mua trong dưới 3 lượt click.

### 3. Tái phân bổ ngân sách tiếp thị theo tỷ lệ chuyển đổi thực tế (Marketing Budget Optimization)
- **Thực trạng**: Kênh quảng cáo hiển thị `dfa` đạt tỷ lệ chuyển đổi cao nhất (**2.64%**), theo sau là `(direct)` (**2.48%**). Trong khi đó, tìm kiếm `google` dù tốn kém và có traffic lớn nhưng chỉ đạt **0.92%**.
- **Hành động đề xuất**:
  - Dồn ngân sách tiếp thị lại (Retargeting) vào các chiến dịch Display Ads `dfa` nhắm vào tệp khách đã xem sản phẩm nhưng chưa thanh toán.
  - Tinh lọc từ khóa tìm kiếm trên Google Ads, loại bỏ các từ khóa chung chung có tỷ lệ thoát cao để tập trung vào từ khóa thương hiệu (Brand Keywords) có ROI cao hơn.

### 4. Triển khai gói bán kèm tự động (Automated Cross-Selling Bundles)
- **Thực trạng**: Khách mua áo *"YouTube Men's Vintage Henley"* có xu hướng rất cao mua kèm Kính râm *Google Sunglasses* (20 chiếc) và Son dưỡng *Lip Balm* (6 chiếc).
- **Hành động đề xuất**:
  - Thiết lập khối gợi ý *"Frequently Bought Together"* ngay tại trang chi tiết sản phẩm và trong giỏ hàng.
  - Đóng gói Combo *"Summer Outing Pack"* (Áo Henley + Kính râm) với giá ưu đãi giảm 10% nhằm tăng ngay Giá trị đơn hàng trung bình (Average Order Value - AOV).

---

## 👤 Author & Contact

**Nguyễn Xuân Thu**
- 🐙 GitHub: [@thunx280-ctrl](https://github.com/thunx280-ctrl)
- 💼 LinkedIn: [Nguyen Xuan Thu](https://linkedin.com)
- 📧 Email: `thu.nx280@gmail.com`
