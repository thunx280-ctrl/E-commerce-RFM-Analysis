--- Query 01: calculate total visit, pageview, transaction for Jan, Feb and March 2017 (order by month)
SELECT
    -- Chuyển đổi cột date (string) sang định dạng tháng YYYYMM
    format_date('%Y%m', parse_date('%Y%m%d', date)) AS month  
    ,sum(totals.visits) AS visits
    ,sum(totals.pageviews) AS pageviews
    ,sum(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix between '0101' and '0331'
group by month
order by month


--- Query 02: Bounce rate per traffic source in July 2017 (Bounce_rate = num_bounce/total_visit) (order by total_visit DESC)
SELECT
    trafficSource.source source
    ,sum(totals.visits) AS total_visits
    ,sum(totals.bounces) AS total_no_of_bounces
    -- Tính tỉ lệ thoát: (số lần thoát / tổng số visit) * 100
    ,round(sum(totals.bounces) / sum(totals.visits)*100,3) bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
group by source
order by total_visits desc


--- Query 03: Revenue by traffic source by week, by month in June 2017
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
order by time_type, Revenue desc

--- Query 04: Conversion rate by traffic source in 2017. (order by conversion_rate desc)
SELECT
    trafficSource.source source
    ,sum(totals.visits) AS visits
    ,sum(totals.transactions) AS transactions
    ,round(sum(totals.transactions) /sum(totals.visits)*100 ,2) as conversion_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
group by source
HAVING SUM(totals.transactions) >= 50
order by conversion_rate desc

--- Query 05: Average number of pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017.
with purchaser_data AS ( --- tính trung bình pageviews của người mua hàng
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
non_purchaser_data AS ( --- tính trung bình pageviews của người không mua hàng
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
---- join 2 bản lại để lấy kết quả theo tháng
SELECT          
  p.month
  ,p.avg_pageviews_purchase
  ,n.avg_pageviews_non_purchase
FROM purchaser_data p
LEFT JOIN non_purchaser_data n
ON p.month = n.month
ORDER BY p.month;


--- Query 06: Average number of transactions per user that made a purchase in July 2017
--   Avg_total_transactions_per_user = total_trans / total_user (unique)
SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) AS month
    ,round(sum(totals.transactions) / count(distinct fullVisitorId),2) as Avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) hits
    ,UNNEST(hits.product) product
WHERE totals.transactions >= 1
      AND product.productRevenue is not null
GROUP BY month


-- Query 07: Revenue contribution by device (desktop,mobile...) (order by ratio desc)
--   ratio = revenue_by_device / total_revenue
-- Đề bài thiếu phạm vi ngày (ví dụ phạm vi là July/2017)
with device_revenue AS (
  SELECT
    device.deviceCategory AS device
    -- Tính doanh thu cho từng thiết bị ( chia cho 1.000.000)
    ,sum(product.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
  WHERE  totals.transactions IS NOT NULL
         AND product.productRevenue IS NOT NULL
  GROUP BY device
)
SELECT
    device
    ,revenue_by_device
    -- Sử dụng Window Function để tính tổng doanh thu toàn bộ (tất cả các dòng) rồi dán vào từng dòng
    ,SUM(revenue_by_device) OVER() AS total_revenue
    -- Tính tỷ lệ phần trăm (ratio)
    ,ROUND(revenue_by_device * 100 / SUM(revenue_by_device) OVER(), 2) AS ratio
FROM device_revenue
ORDER BY ratio DESC;


--- Query 08: Other products purchased by customers who purchased product "YouTube Men's Vintage Henley" in July 2017. Output should show product name and the quantity was ordered.
WITH 
Henley_buyers AS ( --- Khách hàng đã mua hàng bao gồm sản phẩm "YouTube Men's Vintage Henley"
    SELECT
        DISTINCT fullVisitorId
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS h
    ,UNNEST(h.product) AS p
    WHERE p.v2ProductName = "YouTube Men's Vintage Henley"
          AND p.productRevenue IS NOT NULL
          AND totals.transactions >=1
)
SELECT
     product.v2ProductName
    ,SUM(productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,UNNEST(hits) AS hits
    ,UNNEST(hits.product) AS product
inner join Henley_buyers
using(fullVisitorId)
WHERE
    totals.transactions >=1
    AND product.productRevenue IS NOT NULL
    AND product.v2ProductName != "YouTube Men's Vintage Henley"
GROUP BY product.v2ProductName
order by quantity desc


-- Query 9: Calculate cohort map from product view to addtocart to purchase in Jan, Feb and March 2017. For example, 100% product view then 40% add_to_cart and 10% purchase.
--   Add_to_cart_rate = number product  add to cart/number product view. Purchase_rate = number product purchase/number product view. The output should be calculated in product level.
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

--- Query 10: Calculate revenue by week from May to July 2017 and culmulative revenue.
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
    -- Window Function tính cộng dồn từ dòng đầu tiên đến dòng hiện tại
    ,round(SUM(weekly_revenue) OVER (ORDER BY week),2) AS cumulative_revenue
FROM weekly_rev_data
ORDER BY week;