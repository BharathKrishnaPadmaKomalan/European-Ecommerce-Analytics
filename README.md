# European E-Commerce Analytics

### End-to-End Data Analytics Portfolio Project

**Tech Stack:** Python | Pandas | PostgreSQL | SQL | Power BI | DAX | Jupyter Notebook

## Project Overview

This project analyzes historical European online retail transactions to investigate sales performance, customer purchasing behavior, retention patterns, product performance, and data quality.

The project combines Python-based data preparation, PostgreSQL analytics, and interactive Power BI dashboards to transform transactional data into business insights.

## Business Objectives

- Evaluate sales performance across products, countries, and time periods.
- Identify high-value customers using Recency, Frequency, and Monetary (RFM) analysis.
- Measure repeat-purchase retention through monthly customer cohorts.
- Detect transaction anomalies and duplicate records.
- Compare original and deduplicated financial KPIs.

## Key Results

| Metric | Result |
|---|---:|
| Transaction rows analyzed | 1,067,371 |
| Valid-sale rows before deduplication | 1,041,670 |
| Deduplicated orders | 40,077 |
| Unique customers | 5,878 |
| Deduplicated units sold | 11,385,368 |
| Original gross sales | £20,972,594.55 |
| Deduplicated gross sales | £20,913,891.45 |
| Duplicate rows identified | 12,133 |
| Gross sales associated with duplicate valid-sale rows | £58,703.10 |

## Analytical Components

### 1. Sales Performance

Analyzed gross sales, order volumes, average order value, country-level sales, and product rankings.

### 2. Customer Segmentation

Applied RFM analysis to classify customers into Champions, Loyal Customers, At Risk, Hibernating, Recent Customers, and Potential Loyalists.

### 3. Customer Retention

Built monthly cohort retention analysis to study repeat-purchase behavior over time.

### 4. Data Quality

Classified cancellation and adjustment records, identified exact duplicates, and reconciled original versus deduplicated sales.

## Power BI Dashboards

- Executive Overview
- Customer Intelligence
- Customer Retention
- Product Performance & Data Quality

Dashboard screenshots will be included in the `images/` folder.

## Tools Used

**Python / Pandas:** Data inspection, cleaning, transaction classification, and duplicate detection.

**PostgreSQL / SQL:** KPI calculations, customer segmentation, cohort retention, and data-quality validation.

**Power BI / DAX:** Interactive dashboards, business measures, and financial reconciliation.

## Getting Started

### Prerequisites

- Python 3.11
- Jupyter Notebook
- PostgreSQL
- Power BI Desktop (Windows)

### Installation

Clone the repository:

```bash
git clone https://github.com/BharathKrishnaPadmaKomalan/European-Ecommerce-Analytics.git
cd European-Ecommerce-Analytics
```

Create and activate a Python environment, then install dependencies:

```bash
python -m pip install -r requirements.txt
```

### Dataset Setup

Place the source Excel dataset at:

`data/raw/online_retail_II.xlsx`

The dataset is not included in the repository. Refer to the dataset source and licensing information once documented.

### Running the Notebooks

Open Jupyter Notebook from the project root and run the notebooks in this order:

1. `notebooks/01_data_exploration.ipynb`
2. `notebooks/02_data_cleaning.ipynb`

### SQL Analysis

The `sql/` directory contains PostgreSQL queries for:

- Business KPIs
- Customer RFM segmentation
- Customer cohort analysis
- Data-quality validation

The SQL scripts require the appropriate PostgreSQL tables and views to be prepared.

### Power BI

Open `powerbi/European_Ecommerce_Analytics.pbix` in Power BI Desktop.

A configured PostgreSQL connection and access to the underlying database may be required to refresh the data.

## Data and Methodology Notes

The dataset covers historical online retail transactions from 2009–2011. Results represent historical business activity, not current market conditions.

Original and deduplicated metrics are reported separately. Some customer segmentation and cohort results require further reconciliation with the deduplicated transaction dataset.

The dataset source, reproducibility instructions, and detailed business recommendations will be added before publication.

## Project Status

Core SQL analysis, Python data preparation, Power BI dashboards, and GitHub documentation completed. Reproducibility testing, dataset attribution, and cross-dashboard metric reconciliation are being finalized.

## Power BI Dashboard Gallery

### Executive Overview

![Executive Overview](images/Executive%20Overview.png)

### Customer Intelligence

![Customer Intelligence](images/Customer%20Intelligence.png)

### Customer Retention

![Customer Retention](images/Customer%20Retention.png)

### Product Performance & Data Quality

![Product Performance & Data Quality](images/Product%20Performance%20%26%20Data%20Quality.png)

