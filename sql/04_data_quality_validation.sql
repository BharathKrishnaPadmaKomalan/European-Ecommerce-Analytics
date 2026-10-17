-- European E-Commerce Analytics
-- 04_data_quality_validation.sql
-- PostgreSQL 18 | Read-only data-quality checks
-- Source: public.transactions
-- Assumptions: transaction_type, is_duplicate_extra, gross_sales_value,
--              invoice_no, customer_id, quantity are present.
-- IMPORTANT: is_duplicate_extra must mark only the extra copies of exact duplicates.
-- Run each section independently in pgAdmin, or run the entire script.

-- 01. Inspect total rows and transaction classification
SELECT
    COUNT(*) AS total_transaction_rows,
    COUNT(*) FILTER (WHERE transaction_type = 'Valid Sale') AS valid_sale_rows,
    COUNT(*) FILTER (WHERE transaction_type = 'Cancellation') AS cancellation_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE transaction_type = 'Cancellation')
          / NULLIF(COUNT(*), 0), 2) AS cancellation_row_rate_percent
FROM public.transactions;

SELECT transaction_type, COUNT(*) AS transaction_rows
FROM public.transactions
GROUP BY transaction_type
ORDER BY transaction_rows DESC;

-- 02. Check duplicate flag population and duplicate-associated gross sales
SELECT
    COUNT(*) FILTER (WHERE is_duplicate_extra IS TRUE) AS duplicate_rows,
    COUNT(*) FILTER (
        WHERE is_duplicate_extra IS TRUE AND transaction_type = 'Valid Sale'
    ) AS duplicate_valid_sale_rows,
    ROUND(COALESCE(SUM(gross_sales_value) FILTER (
        WHERE is_duplicate_extra IS TRUE AND transaction_type = 'Valid Sale'
    ), 0)::numeric, 2) AS duplicate_valid_sale_gross_sales
FROM public.transactions;

-- 03. Reconcile original and deduplicated sales and other KPIs
WITH original AS (
    SELECT
        COUNT(*) AS valid_sale_rows,
        COUNT(DISTINCT invoice_no) AS total_orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        COALESCE(SUM(quantity), 0) AS units_sold,
        COALESCE(SUM(gross_sales_value), 0) AS gross_sales
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
),
deduplicated AS (
    SELECT
        COUNT(*) AS deduplicated_valid_sale_rows,
        COUNT(DISTINCT invoice_no) AS deduplicated_orders,
        COUNT(DISTINCT customer_id) AS deduplicated_customers,
        COALESCE(SUM(quantity), 0) AS deduplicated_units_sold,
        COALESCE(SUM(gross_sales_value), 0) AS deduplicated_gross_sales
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
      AND is_duplicate_extra IS NOT TRUE
)
SELECT
    o.valid_sale_rows,
    d.deduplicated_valid_sale_rows,
    o.total_orders,
    d.deduplicated_orders,
    o.unique_customers,
    d.deduplicated_customers,
    o.units_sold,
    d.deduplicated_units_sold,
    o.units_sold - d.deduplicated_units_sold AS duplicate_units_removed,
    ROUND(o.gross_sales::numeric, 2) AS original_gross_sales,
    ROUND(d.deduplicated_gross_sales::numeric, 2) AS deduplicated_gross_sales,
    ROUND((o.gross_sales - d.deduplicated_gross_sales)::numeric, 2)
        AS duplicate_gross_sales_removed,
    ROUND(100 * (o.gross_sales - d.deduplicated_gross_sales)::numeric
          / NULLIF(o.gross_sales, 0), 2) AS duplicate_revenue_share_percent,
    ROUND(o.gross_sales::numeric / NULLIF(o.total_orders, 0), 2)
        AS original_average_order_value,
    ROUND(d.deduplicated_gross_sales::numeric
          / NULLIF(d.deduplicated_orders, 0), 2)
        AS deduplicated_average_order_value
FROM original o CROSS JOIN deduplicated d;

-- 04. Validate that the duplicate flag does not affect unique orders/customers
WITH counts AS (
    SELECT
        COUNT(DISTINCT invoice_no) AS original_orders,
        COUNT(DISTINCT invoice_no) FILTER (WHERE is_duplicate_extra IS NOT TRUE)
            AS deduplicated_orders,
        COUNT(DISTINCT customer_id) AS original_customers,
        COUNT(DISTINCT customer_id) FILTER (WHERE is_duplicate_extra IS NOT TRUE)
            AS deduplicated_customers
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
)
SELECT *,
       CASE WHEN original_orders = deduplicated_orders THEN 'PASS' ELSE 'REVIEW' END
           AS order_count_check,
       CASE WHEN original_customers = deduplicated_customers THEN 'PASS' ELSE 'REVIEW' END
           AS customer_count_check
FROM counts;

-- 05. Confirm gross-sales reconciliation against duplicate valid-sale rows
WITH values AS (
    SELECT
        COALESCE(SUM(gross_sales_value) FILTER (
            WHERE transaction_type = 'Valid Sale'), 0) AS original_sales,
        COALESCE(SUM(gross_sales_value) FILTER (
            WHERE transaction_type = 'Valid Sale'
              AND is_duplicate_extra IS NOT TRUE), 0) AS deduplicated_sales,
        COALESCE(SUM(gross_sales_value) FILTER (
            WHERE transaction_type = 'Valid Sale'
              AND is_duplicate_extra IS TRUE), 0) AS duplicate_sales
    FROM public.transactions
)
SELECT
    ROUND(original_sales::numeric, 2) AS original_sales,
    ROUND(deduplicated_sales::numeric, 2) AS deduplicated_sales,
    ROUND(duplicate_sales::numeric, 2) AS duplicate_sales,
    ROUND((original_sales - deduplicated_sales - duplicate_sales)::numeric, 2)
        AS reconciliation_difference,
    CASE WHEN ABS(original_sales - deduplicated_sales - duplicate_sales) < 0.01
         THEN 'PASS' ELSE 'REVIEW' END AS reconciliation_check
FROM values;

-- 06. Inspect nulls in essential analytical fields
SELECT
    COUNT(*) FILTER (WHERE invoice_no IS NULL) AS missing_invoice_no,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE transaction_type IS NULL) AS missing_transaction_type,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantity,
    COUNT(*) FILTER (WHERE gross_sales_value IS NULL) AS missing_gross_sales_value,
    COUNT(*) FILTER (WHERE is_duplicate_extra IS NULL) AS missing_duplicate_flag
FROM public.transactions;

-- Reference values from prior validated analysis (not hard-coded assertions):
-- total_transaction_rows:        1,067,371
-- valid_sale_rows:              1,041,670
-- duplicate_rows:                  12,133
-- duplicate_valid_sale_rows:      12,061
-- original gross sales:       GBP 20,972,594.55
-- deduplicated gross sales:   GBP 20,913,891.45
-- duplicate valid-sale sales: GBP     58,703.10
-- deduplicated orders:            40,077
-- deduplicated customers:          5,878
-- deduplicated units:         11,385,368
