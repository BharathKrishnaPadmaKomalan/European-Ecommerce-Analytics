# European E-Commerce Analytics
## Technical Methodology

### 1. Data Source
Historical Online Retail II transaction dataset,
covering December 2009 to December 2011.

### 2. Data Exploration and Preparation
Tools: Python, Pandas, Jupyter Notebook.

- Inspected 1,067,371 transaction records.
- Examined missing values and data types.
- Standardized transaction attributes.
- Classified valid sales, cancellations and adjustments.
- Identified exact duplicate transaction records.
- Prepared structured data for PostgreSQL.

### 3. PostgreSQL Data Analysis
Tools: PostgreSQL, pgAdmin, SQL.

SQL scripts:
- 01_business_kpis.sql
- 02_customer_rfm_analysis.sql
- 03_customer_cohort_analysis.sql
- 04_data_quality_validation.sql

Business KPIs included gross sales, orders,
unique customers, units sold and average order value.

### 4. Customer RFM Segmentation
RFM stands for:
- Recency: Days since the last purchase.
- Frequency: Number of distinct purchase invoices.
- Monetary: Total customer-linked sales value.

Customers were classified into six segments:
Champions, Loyal Customers, At Risk,
Hibernating, Recent Customers and Potential Loyalists.

### 5. Cohort Retention Analysis
- Assigned customers to their first purchase month.
- Calculated monthly customer activity.
- Calculated retention relative to cohort size.
- Calculated weighted retention across eligible cohorts.

Verified weighted retention:
- Month 1: 23.15%
- Month 2: 23.27%
- Month 3: 24.51%
- Month 6: 21.78%

### 6. Data Quality Validation
- Identified 12,133 duplicate rows.
- Identified 12,061 duplicate valid-sale rows.
- Quantified duplicate-associated valid-sale revenue
  of GBP 58,703.10.
- Reconciled original and deduplicated sales.

Validated deduplicated results:
- Gross sales: GBP 20,913,891.45
- Orders: 40,077
- Customers: 5,878
- Units sold: 11,385,368
- Average order value: GBP 521.84

### 7. Power BI Reporting
Tools: Power BI Desktop, DAX.

Dashboard pages:
1. Executive Overview
2. Customer Intelligence
3. Customer Retention
4. Product Performance and Data Quality

The dashboards present sales performance,
customer segmentation, retention patterns,
product performance and data-quality metrics.

### 8. Analytical Limitations
- Historical data should not be interpreted
  as current European e-commerce performance.
- Some customer analyses were produced before
  final deduplication and require reconciliation.
- Findings are descriptive and do not establish
  causal relationships.
