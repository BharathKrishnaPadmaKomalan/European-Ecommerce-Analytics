-- European E-Commerce Revenue & Customer Intelligence Platform
-- 03_customer_cohort_analysis.sql
-- PostgreSQL 18 | Database: european_ecommerce
-- Run against a database containing public.transactions.
-- Only CREATE OR REPLACE VIEW changes a database object; source transactions remain unchanged.
-- Cohorts are based on the FIRST OBSERVED valid-sale month, not necessarily a customer's first-ever purchase.
-- Retention is a purchase in the specified month (not continuous activity).

-- 01. Create monthly cohort retention view.
CREATE OR REPLACE VIEW public.customer_cohort_retention AS
WITH customer_months AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date)::date AS purchase_month
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND customer_id IS NOT NULL
      AND invoice_date IS NOT NULL
),
customer_cohorts AS (
    SELECT customer_id, MIN(purchase_month) AS cohort_month
    FROM customer_months
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
        m.customer_id,
        c.cohort_month,
        m.purchase_month,
        ((EXTRACT(YEAR FROM m.purchase_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
          + (EXTRACT(MONTH FROM m.purchase_month) - EXTRACT(MONTH FROM c.cohort_month)))::integer AS cohort_index
    FROM customer_months m
    JOIN customer_cohorts c USING (customer_id)
),
cohort_counts AS (
    SELECT cohort_month, cohort_index, COUNT(*)::bigint AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, cohort_index
),
cohort_sizes AS (
    SELECT cohort_month, active_customers AS cohort_size
    FROM cohort_counts
    WHERE cohort_index = 0
)
SELECT
    cc.cohort_month,
    cc.cohort_index,
    cc.active_customers,
    cs.cohort_size,
    ROUND(100.0 * cc.active_customers / NULLIF(cs.cohort_size, 0), 2) AS retention_rate_percent
FROM cohort_counts cc
JOIN cohort_sizes cs USING (cohort_month);

-- 02. Inspect first 30 results.
SELECT *
FROM public.customer_cohort_retention
ORDER BY cohort_month, cohort_index
LIMIT 30;

-- 03. Validation: month zero should always be 100%; expect zero rows.
SELECT *
FROM public.customer_cohort_retention
WHERE cohort_index = 0 AND retention_rate_percent <> 100;

-- 04. Validation: total initial cohort customers should match 5,878 (for current source).
SELECT SUM(cohort_size) AS total_cohort_customers
FROM public.customer_cohort_retention
WHERE cohort_index = 0;

-- 05. Validation: retention cannot be outside 0..100% or exceed cohort size; expect zero rows.
SELECT *
FROM public.customer_cohort_retention
WHERE retention_rate_percent < 0
   OR retention_rate_percent > 100
   OR active_customers > cohort_size;

-- 06. Validation: source unique customer count equals total cohort size.
SELECT
    (SELECT COUNT(DISTINCT customer_id)
     FROM public.transactions
     WHERE transaction_type = 'Valid Sale'
       AND customer_id IS NOT NULL
       AND invoice_date IS NOT NULL) AS source_customers,
    (SELECT SUM(cohort_size)
     FROM public.customer_cohort_retention
     WHERE cohort_index = 0) AS cohort_customers;

-- 07. Correct weighted retention for months 1, 2, 3 and 6.
-- Includes zero-return cohorts and excludes cohorts without enough observation time.
-- Last observed valid-sale month determines which cohorts are eligible.
WITH max_month AS (
    SELECT DATE_TRUNC('month', MAX(invoice_date))::date AS latest_month
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND invoice_date IS NOT NULL
),
cohorts AS (
    SELECT cohort_month, cohort_size
    FROM public.customer_cohort_retention
    WHERE cohort_index = 0
),
periods AS (
    SELECT unnest(ARRAY[1, 2, 3, 6]) AS cohort_index
),
eligible AS (
    SELECT c.cohort_month, c.cohort_size, p.cohort_index
    FROM cohorts c
    CROSS JOIN periods p
    CROSS JOIN max_month m
    WHERE (c.cohort_month + make_interval(months => p.cohort_index))::date <= m.latest_month
)
SELECT
    e.cohort_index,
    COUNT(*) AS eligible_cohorts,
    COALESCE(SUM(r.active_customers), 0) AS returning_customers,
    SUM(e.cohort_size) AS eligible_customers,
    ROUND(100.0 * COALESCE(SUM(r.active_customers), 0) /
          NULLIF(SUM(e.cohort_size), 0), 2) AS weighted_retention_percent
FROM eligible e
LEFT JOIN public.customer_cohort_retention r
  ON r.cohort_month = e.cohort_month
 AND r.cohort_index = e.cohort_index
GROUP BY e.cohort_index
ORDER BY e.cohort_index;

-- 08. Power BI heatmap source: use the view directly.
-- Rows = cohort_month; Columns = cohort_index; Values = retention_rate_percent.
-- Missing cohort-index combinations indicate zero returning customers IF that month is observable.
-- Future/unobserved months should remain blank, not zero.
SELECT cohort_month, cohort_index, cohort_size, active_customers, retention_rate_percent
FROM public.customer_cohort_retention
ORDER BY cohort_month, cohort_index;
