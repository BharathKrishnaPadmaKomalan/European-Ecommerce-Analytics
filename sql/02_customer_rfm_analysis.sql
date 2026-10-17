-- European E-Commerce Revenue & Customer Intelligence
-- 02_customer_rfm_analysis.sql
-- PostgreSQL 18 | Database: european_ecommerce
-- Prerequisite: public.transactions populated from Online Retail II.
-- RFM uses positive valid-sale lines with a known customer_id.
-- Monetary values are gross positive sales, NOT net sales or profit.
-- Run this script in pgAdmin Query Tool while connected to european_ecommerce.

-- 01. Verify the customer-linked transaction population.
SELECT
    COUNT(*) AS customer_linked_sales_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(gross_sales_value), 2) AS customer_linked_gross_sales
FROM public.transactions
WHERE transaction_type = 'Valid Sale'
  AND customer_id IS NOT NULL;

-- 02. Preview customer RFM metrics before materializing the table.
-- Reference date = one day after the last observed valid sale.
-- Invoice identifiers are distinguished by source_sheet as well as invoice_no.
WITH reference_date AS (
    SELECT MAX(invoice_date)::date + 1 AS analysis_date
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
), customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date)::date AS last_purchase_date,
        COUNT(DISTINCT (source_sheet, invoice_no)) AS frequency,
        ROUND(SUM(gross_sales_value), 2) AS monetary
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    r.analysis_date - c.last_purchase_date AS recency_days,
    c.frequency,
    c.monetary
FROM customer_metrics c
CROSS JOIN reference_date r
ORDER BY c.monetary DESC
LIMIT 20;

-- 03. Build/rebuild the customer-level RFM table.
-- WARNING: Replaces public.customer_rfm if it already exists.
-- It does NOT alter public.transactions.
DROP TABLE IF EXISTS public.customer_rfm;

CREATE TABLE public.customer_rfm AS
WITH reference_date AS (
    SELECT MAX(invoice_date)::date + 1 AS analysis_date
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
), customer_metrics AS (
    SELECT
        customer_id,
        MAX(invoice_date)::date AS last_purchase_date,
        COUNT(DISTINCT (source_sheet, invoice_no)) AS frequency,
        ROUND(SUM(gross_sales_value), 2) AS monetary
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
), rfm_values AS (
    SELECT
        c.customer_id,
        r.analysis_date - c.last_purchase_date AS recency_days,
        c.frequency,
        c.monetary
    FROM customer_metrics c
    CROSS JOIN reference_date r
), rfm_scores AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC, customer_id) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC, customer_id) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC, customer_id) AS m_score
    FROM rfm_values
)
SELECT
    *,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customers'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
        ELSE 'Potential Loyalists'
    END AS customer_segment
FROM rfm_scores;

ALTER TABLE public.customer_rfm ADD PRIMARY KEY (customer_id);

-- 04. Segment overview: counts, sales and average customer behavior.
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS gross_sales,
    ROUND(AVG(monetary), 2) AS avg_customer_value,
    ROUND(AVG(frequency), 2) AS avg_orders,
    ROUND(AVG(recency_days), 1) AS avg_recency_days
FROM public.customer_rfm
GROUP BY customer_segment
ORDER BY gross_sales DESC;

-- 05. Validate customer uniqueness, monetary totals and score ranges.
SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(monetary), 2) AS total_customer_gross_sales,
    MIN(r_score) AS min_r_score,
    MAX(r_score) AS max_r_score,
    MIN(f_score) AS min_f_score,
    MAX(f_score) AS max_f_score,
    MIN(m_score) AS min_m_score,
    MAX(m_score) AS max_m_score
FROM public.customer_rfm;

-- 06. Customer segment revenue contribution.
SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS gross_sales,
    ROUND(
        100.0 * SUM(monetary) / NULLIF(SUM(SUM(monetary)) OVER (), 0),
        2
    ) AS revenue_share_percent
FROM public.customer_rfm
GROUP BY customer_segment
ORDER BY revenue_share_percent DESC;

-- 07. FINAL VALIDATION: compare RFM gross sales with underlying transaction sales.
-- A zero difference is the target. Small nonzero differences can result
-- from rounding customer-level monetary totals before summation.
WITH rfm_total AS (
    SELECT COALESCE(SUM(monetary), 0) AS amount
    FROM public.customer_rfm
), transaction_total AS (
    SELECT COALESCE(SUM(gross_sales_value), 0) AS amount
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND customer_id IS NOT NULL
)
SELECT
    ROUND(r.amount, 2) AS rfm_gross_sales,
    ROUND(t.amount, 2) AS transaction_gross_sales,
    ROUND(r.amount - t.amount, 2) AS difference_gbp,
    CASE
        WHEN ABS(r.amount - t.amount) < 0.005 THEN 'MATCH'
        ELSE 'REVIEW ROUNDING / SOURCE VALUES'
    END AS reconciliation_status
FROM rfm_total r
CROSS JOIN transaction_total t;

-- 08. FINAL VALIDATION: verify segment counts sum to all RFM customers.
SELECT
    (SELECT COUNT(*) FROM public.customer_rfm) AS rfm_customer_rows,
    (SELECT COUNT(DISTINCT customer_id) FROM public.transactions
     WHERE transaction_type = 'Valid Sale' AND customer_id IS NOT NULL)
        AS source_unique_customers,
    (SELECT COUNT(DISTINCT customer_id) FROM public.customer_rfm)
        AS rfm_unique_customers;

-- Interpretation notes:
-- * RFM scoring uses NTILE(5); tied frequency values may fall into different
--   score groups at quintile boundaries because customer_id breaks ties.
-- * Segments are project-defined rules, not labels supplied by UCI.
-- * The dataset is historical; recency is relative to its final sales date.
-- * Customer IDs missing from sales are intentionally excluded from RFM.
-- * Exact duplicate source rows remain retained pending separate sensitivity review.
