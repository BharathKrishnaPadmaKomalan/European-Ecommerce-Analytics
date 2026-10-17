-- European E-Commerce Revenue & Customer Intelligence Platform
-- File: sql/01_business_kpis.sql
-- Database: european_ecommerce (PostgreSQL)
-- Source table: public.transactions
-- Definition: gross_sales_value represents positive valid-sale line value,
-- excluding cancellation-prefixed invoices and nonstandard adjustment rows.
-- Gross sales are not net revenue, profit, or cancellation-adjusted sales.
-- Duplicate-looking lines are retained pending source-level verification.
-- All monetary values are in GBP as recorded in the source dataset.

-- 00. Create the transaction table (safe to rerun; existing rows are preserved)
-- Connect to the european_ecommerce database in pgAdmin before running.
-- CREATE DATABASE is intentionally not included: this file is executed inside
-- the already-created european_ecommerce database.
CREATE TABLE IF NOT EXISTS public.transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    invoice_no VARCHAR(50),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(12, 2),
    customer_id BIGINT,
    country VARCHAR(100),
    source_sheet VARCHAR(50),
    is_cancellation BOOLEAN,
    is_valid_sale BOOLEAN,
    transaction_status VARCHAR(50),
    revenue NUMERIC(18, 2),
    year INTEGER,
    month INTEGER,
    year_month VARCHAR(7),
    day_of_week VARCHAR(20),
    transaction_type VARCHAR(50),
    is_duplicate_extra BOOLEAN,
    gross_sales_value NUMERIC(18, 2)
);

-- 00A. CSV import instructions (do not import again if rows already exist)
-- In pgAdmin: right-click public.transactions > Import/Export Data > Import.
-- Select data/processed/transactions_postgresql.csv, CSV, Header = Yes,
-- encoding UTF8. On the Columns tab select all 20 data columns in the order
-- below, EXCLUDING transaction_id (PostgreSQL generates it automatically).
-- Import only into an empty table to avoid loading the same rows twice.
-- An optional server-side COPY command is shown below. It is COMMENTED OUT
-- because COPY reads files from the PostgreSQL SERVER's filesystem, which
-- may not have access to your Windows Documents folder.
-- COPY public.transactions (
--     invoice_no, stock_code, description, quantity, invoice_date, unit_price,
--     customer_id, country, source_sheet, is_cancellation, is_valid_sale,
--     transaction_status, revenue, year, month, year_month, day_of_week,
--     transaction_type, is_duplicate_extra, gross_sales_value
-- ) FROM 'C:/path/to/transactions_postgresql.csv'
-- WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');

-- 00B. Verify the imported row count (expected: 1,067,371)
SELECT COUNT(*) AS total_transaction_rows FROM public.transactions;

-- 01. Data import and transaction classification validation
SELECT
    transaction_type,
    COUNT(*) AS transaction_rows
FROM public.transactions
GROUP BY transaction_type
ORDER BY transaction_rows DESC;

-- 02. Gross sales reconciliation and customer-ID coverage
SELECT
    COUNT(*) AS valid_sale_rows,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp,
    ROUND(SUM(gross_sales_value) FILTER (WHERE customer_id IS NOT NULL), 2)
        AS identified_customer_sales_gbp,
    ROUND(SUM(gross_sales_value) FILTER (WHERE customer_id IS NULL), 2)
        AS unidentified_customer_sales_gbp,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS unidentified_customer_rows
FROM public.transactions
WHERE transaction_type = 'Valid Sale';

-- 03. Overall sales KPIs (positive sales only)
SELECT
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS identified_customers,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp,
    ROUND(SUM(gross_sales_value) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value_gbp,
    SUM(quantity) AS units_sold
FROM public.transactions
WHERE transaction_type = 'Valid Sale';

-- 04. Top 15 countries by gross sales
SELECT
    country,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(quantity) AS units_sold,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp,
    ROUND(SUM(gross_sales_value) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value_gbp
FROM public.transactions
WHERE transaction_type = 'Valid Sale'
GROUP BY country
ORDER BY gross_sales_gbp DESC
LIMIT 15;

-- 05. Germany, Netherlands, and Ireland (EIRE) comparison
-- EIRE is Ireland, not Luxembourg.
SELECT
    country,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp,
    ROUND(SUM(gross_sales_value) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value_gbp
FROM public.transactions
WHERE transaction_type = 'Valid Sale'
  AND country IN ('Germany', 'Netherlands', 'EIRE')
GROUP BY country
ORDER BY gross_sales_gbp DESC;

-- 06. Monthly gross sales and order trends
SELECT
    DATE_TRUNC('month', invoice_date)::date AS sales_month,
    COUNT(DISTINCT invoice_no) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp,
    ROUND(SUM(gross_sales_value) / NULLIF(COUNT(DISTINCT invoice_no), 0), 2)
        AS average_order_value_gbp
FROM public.transactions
WHERE transaction_type = 'Valid Sale'
GROUP BY DATE_TRUNC('month', invoice_date)::date
ORDER BY sales_month;

-- 07. Month-over-month gross sales change using a window function
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::date AS sales_month,
        SUM(gross_sales_value) AS gross_sales
    FROM public.transactions
    WHERE transaction_type = 'Valid Sale'
    GROUP BY DATE_TRUNC('month', invoice_date)::date
),
monthly_with_previous AS (
    SELECT
        sales_month,
        gross_sales,
        LAG(gross_sales) OVER (ORDER BY sales_month) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(gross_sales, 2) AS gross_sales_gbp,
    ROUND(previous_month_sales, 2) AS previous_month_sales_gbp,
    ROUND(100.0 * (gross_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0), 2) AS mom_growth_pct
FROM monthly_with_previous
ORDER BY sales_month;

-- 08. Top 10 products by gross sales (stock code is the product key)
SELECT
    stock_code,
    MAX(description) AS example_description,
    SUM(quantity) AS units_sold,
    ROUND(SUM(gross_sales_value), 2) AS gross_sales_gbp
FROM public.transactions
WHERE transaction_type = 'Valid Sale'
GROUP BY stock_code
ORDER BY gross_sales_gbp DESC
LIMIT 10;

-- 09. Duplicate-associated gross sales sensitivity check
-- Potential impact only; duplicate-looking rows may be legitimate.
SELECT
    COUNT(*) FILTER (WHERE is_duplicate_extra IS TRUE) AS extra_duplicate_rows,
    ROUND(SUM(gross_sales_value) FILTER (WHERE is_duplicate_extra IS TRUE), 2)
        AS duplicate_associated_gross_sales_gbp,
    ROUND(100.0 * SUM(gross_sales_value) FILTER (WHERE is_duplicate_extra IS TRUE)
        / NULLIF(SUM(gross_sales_value), 0), 2)
        AS share_of_gross_sales_pct
FROM public.transactions
WHERE transaction_type = 'Valid Sale';
