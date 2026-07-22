# Production-Style E-Commerce Data Engineering Platform

## Project Overview

This project implements a production-style e-commerce data engineering pipeline using Python, PostgreSQL, and Power BI. The pipeline ingests raw Olist e-commerce CSV files, loads them into a PostgreSQL raw layer, converts them into typed staging tables, applies data quality checks, builds a star-schema data warehouse, implements advanced ETL modules, and exposes dashboard-ready analytical views for Power BI reporting.

## Tech Stack

- Python
- PostgreSQL
- DBeaver
- VS Code
- Power BI
- SQL
- psycopg2
- pandas
- Git/GitHub

## Dataset

The project uses the Olist Brazilian E-Commerce public dataset. It contains multiple CSV files related to customers, orders, order items, products, sellers, payments, reviews, geolocation, and product category translation.

## Architecture

```mermaid
flowchart TD
    A[Olist CSV Dataset] --> B[Python CSV Ingestion]
    B --> C[Raw Schema]
    C --> D[Staging Schema]
    D --> E[Data Quality Checks]
    E --> F[Audit and Reject Records]
    D --> G[Warehouse Star Schema]
    G --> H[Incremental ETL]
    G --> I[Hybrid Join Enrichment]
    G --> J[SCD Type 2 Product History]
    G --> K[Partitioning and Indexing]
    K --> L[Mart Views]
    L --> M[Power BI Dashboard]