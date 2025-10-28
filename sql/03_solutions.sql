-- Solutions for PostgreSQL
WITH completed AS (
  SELECT * FROM orders WHERE status = 'completed'
),
oi AS (
  SELECT
    oi.order_item_id, oi.order_id, oi.product_id, oi.quantity, oi.unit_price,
    (oi.quantity * oi.unit_price) AS revenue,
    o.customer_id, o.order_date
  FROM order_items oi
  JOIN completed o USING (order_id)
),
ytd_2025 AS (
  SELECT * FROM oi
  WHERE order_date >= '2025-01-01'::timestamp
    AND order_date <= '2025-10-27 23:59:59'::timestamp
);

-- 1) Total revenue YTD 2025
SELECT ROUND(SUM(revenue)::numeric, 2) AS total_revenue_ytd_2025
FROM ytd_2025;

-- 2) Monthly revenue 2025
SELECT TO_CHAR(date_trunc('month', order_date), 'YYYY-MM') AS year_month,
       ROUND(SUM(revenue)::numeric, 2) AS revenue
FROM ytd_2025
GROUP BY 1
ORDER BY 1;

-- 3) Top 5 products by revenue (all time)
SELECT p.product_id, p.name, ROUND(SUM(oi.revenue)::numeric, 2) AS revenue
FROM oi
JOIN products p USING (product_id)
GROUP BY 1,2
ORDER BY revenue DESC
LIMIT 5;

-- 4) AOV 2025 (completed only)
WITH order_totals AS (
  SELECT order_id, SUM(revenue) AS order_revenue
  FROM ytd_2025
  GROUP BY 1
)
SELECT ROUND(AVG(order_revenue)::numeric, 2) AS aov_2025
FROM order_totals;

-- 5) Returning customer rate 2025
WITH counts AS (
  SELECT customer_id, COUNT(DISTINCT order_id) AS n_orders
  FROM ytd_2025
  GROUP BY customer_id
)
SELECT ROUND(100.0 * SUM(CASE WHEN n_orders > 1 THEN 1 ELSE 0 END)::numeric
             / NULLIF(COUNT(*),0), 2) AS returning_customer_rate_pct
FROM counts;

-- 6) Revenue by category (all time)
SELECT p.category, ROUND(SUM(oi.revenue)::numeric, 2) AS revenue
FROM oi JOIN products p USING (product_id)
GROUP BY 1
ORDER BY revenue DESC;

-- 7) Top product per category via window function
WITH prod_cat AS (
  SELECT p.category, p.product_id, p.name, SUM(oi.revenue) AS revenue
  FROM oi JOIN products p USING (product_id)
  GROUP BY 1,2,3
),
ranked AS (
  SELECT *,
         DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM prod_cat
)
SELECT category, product_id, name, ROUND(revenue::numeric,2) AS revenue
FROM ranked
WHERE rnk = 1
ORDER BY revenue DESC;

-- 8) Top 10 customers by lifetime revenue
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       ROUND(SUM(oi.revenue)::numeric, 2) AS lifetime_revenue
FROM oi JOIN customers c USING (customer_id)
GROUP BY 1,2
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 9) New vs returning revenue in 2025
WITH first_order AS (
  SELECT customer_id, MIN(order_date) AS first_order_date
  FROM oi
  GROUP BY customer_id
)
SELECT
  CASE WHEN f.first_order_date >= '2025-01-01'::timestamp
            AND f.first_order_date <= '2025-12-31 23:59:59'::timestamp
       THEN 'new' ELSE 'returning' END AS customer_type,
  ROUND(SUM(y.revenue)::numeric, 2) AS revenue
FROM ytd_2025 y
JOIN first_order f USING (customer_id)
GROUP BY 1
ORDER BY 2 DESC;

-- 10) 2025 % contribution by product
WITH prod_2025 AS (
  SELECT product_id, SUM(revenue) AS rev
  FROM ytd_2025 GROUP BY 1
),
total AS (SELECT SUM(rev) AS tot FROM prod_2025)
SELECT p.product_id, pr.name,
       ROUND(prod_2025.rev::numeric, 2) AS revenue,
       ROUND(100.0 * prod_2025.rev / NULLIF(total.tot,0), 2) AS pct_of_total
FROM prod_2025
JOIN total
JOIN products pr ON pr.product_id = prod_2025.product_id
ORDER BY revenue DESC;

-- 11) 80/20-like cumulative coverage (products, 2025)
WITH prod_2025 AS (
  SELECT product_id, SUM(revenue) AS revenue
  FROM ytd_2025 GROUP BY 1
),
ordered AS (
  SELECT product_id, revenue,
         SUM(revenue) OVER (ORDER BY revenue DESC) AS cum_rev,
         SUM(revenue) OVER () AS total_rev
  FROM prod_2025
)
SELECT *, ROUND(100.0 * cum_rev / NULLIF(total_rev,0), 2) AS cum_pct
FROM ordered
ORDER BY revenue DESC;

-- 12) Median order value in 2025
WITH order_totals AS (
  SELECT order_id, SUM(revenue) AS order_revenue
  FROM ytd_2025
  GROUP BY 1
)
SELECT ROUND(
  percentile_cont(0.5) WITHIN GROUP (ORDER BY order_revenue)::numeric, 2
) AS median_order_value_2025
FROM order_totals;
