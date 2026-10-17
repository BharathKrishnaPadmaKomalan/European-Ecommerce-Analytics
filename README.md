# European E-Commerce Analytics

### End-to-End Data Analytics Portfolio Project

**Tech Stack:** Python | Pandas | PostgreSQL | SQL | Power BI | DAX | Jupyter Notebook

## Project Overview

This project analyzes historical European online retail transactions to investigate sales performance, customer purchasing behavior, retention patterns, product performance, and data quality.

The project combines Python-based data preparation, PostgreSQL analytics, and interactive Power BI dashboards to transform transactional data into business insights.

## Dataset Source

This project uses the **Online Retail II** dataset from the UCI Machine Learning Repository.

The dataset contains 1,067,371 transaction records from a UK-based online retailer between 1 December 2009 and 9 December 2011.

**Dataset details:**
- **Creator:** Daqing Chen
- **Repository:** UCI Machine Learning Repository
- **Dataset ID:** 502
- **Format:** Microsoft Excel (`online_retail_II.xlsx`)
- **License:** Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Official source:** https://archive.ics.uci.edu/dataset/502/online+retail+ii
- **DOI:** https://doi.org/10.24432/C5CG6D

### Dataset Setup

1. Download the Online Retail II dataset from the official UCI repository.
2. Extract the downloaded archive if necessary.
3. Create the `data/raw/` directory inside the project if it does not already exist.
4. Place `online_retail_II.xlsx` inside `data/raw/`.

Expected file location:

`data/raw/online_retail_II.xlsx`

The original dataset is not included in this GitHub repository. Users can download it directly from UCI.

### Dataset Attribution

Chen, D. (2012). *Online Retail II* [Dataset]. UCI Machine Learning Repository. https://doi.org/10.24432/C5CG6D

The source dataset is distributed under CC BY 4.0. This project performs independent data cleaning, SQL analysis, customer segmentation, cohort analysis, and Power BI visualization.

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

**Completed — End-to-End European E-Commerce Analytics Portfolio Project**

This project integrates Python-based data preparation, PostgreSQL analytical queries, and interactive Power BI dashboards.

**Validation completed:**
- Both Jupyter notebooks successfully executed from a fresh kernel.
- PostgreSQL business KPIs reconciled with Power BI results.
- Customer RFM coverage and weighted cohort retention verified.
- Duplicate detection and original-versus-deduplicated sales reconciled.
- All four Power BI dashboard pages reviewed.
- Project code and documentation maintained in GitHub.

The repository includes Python notebooks, SQL analysis scripts, a Power BI report, dashboard screenshots, and methodology documentation.

The original Online Retail II dataset is available separately from the UCI Machine Learning Repository.

## Power BI Dashboard Gallery

### Executive Overview

![Executive Overview](images/Executive%20Overview.png)

### Customer Intelligence

![Customer Intelligence](images/Customer%20Intelligence.png)

### Customer Retention

![Customer Retention](images/Customer%20Retention.png)

### Product Performance & Data Quality

![Product Performance & Data Quality](images/Product%20Performance%20%26%20Data%20Quality.png)

