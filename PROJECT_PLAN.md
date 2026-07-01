# Fintech BI Project — Master Plan

## Status Legend
✅ Complete
🔄 In Progress
⏳ Not Started

---

## Phase 1 — Data Foundation
Goal: Understand raw data, model it properly in SQL.

### Environment Setup
✅ Docker Desktop installed and running
✅ PostgreSQL 15 container running (fintech-db)
✅ DBeaver connected to fintech database
✅ Git initialized and connected to GitHub
✅ VS Code configured with Black formatter
✅ Python 3.14 installed and PATH configured

### Schema Design
✅ Star schema designed
✅ Fact table identified (fact_transactions)
✅ All dimension tables designed
✅ schema.md committed to GitHub

### Data Generation
✅ generate_data.py script created
✅ All tables created in Postgres
✅ dim_date populated (731 rows)
✅ dim_bank populated (20 rows)
✅ dim_customer populated (500 rows)
✅ dim_scheme populated (5 rows)
✅ dim_merchant populated (100 rows)
✅ dim_card populated (700 rows)
✅ fact_transactions populated (50,000 rows)

### Analytical SQL
✅ Net revenue per merchant query
✅ Monthly transaction volume and revenue trends
✅ Fraud rate by scheme
✅ Top 10 merchants by interchange revenue
✅ Chargeback rate by merchant category
✅ Period-over-period revenue comparison
✅ Queries committed to /sql/analysis/ folder on GitHub

**Phase 1 — Complete**

---

## Phase 2 — dbt Core
Goal: Transform raw data into clean, tested, documented models.

### Setup
✅ dbt Core installed (1.8.0, via Python 3.12 virtual environment)
✅ dbt project initialized (fintect_dbt)
✅ dbt connected to Postgres
✅ SQLFluff linter configured (postgres dialect, dbt templater)
⏳ VS Code dbt Power User extension installed
⏳ GitHub Actions CI configured (lint + dbt tests on push)

### Staging Layer
✅ stg_transactions.sql
✅ stg_customers.sql
✅ stg_merchants.sql
✅ stg_cards.sql
✅ stg_banks.sql
✅ stg_schemes.sql
✅ stg_dates.sql
⏳ All staging models tested and documented

### Intermediate Layer
✅ int_transactions_enriched.sql
(Note: int_merchant_metrics and int_card_metrics were refactored and promoted
to the mart layer as agg_merchant_metrics and agg_card_metrics — they are
pre-aggregated summary endpoints, not stepping-stone models.)

### Mart Layer
✅ fct_transactions.sql (+ net_revenue, is_fraud metric columns)
✅ dim_merchant.sql (retains bank_key; merchant→bank relationship left inactive in BI)
✅ dim_customer.sql
✅ dim_card.sql
✅ dim_date.sql (+ transaction_year_month label column for BI time grouping)
✅ dim_bank.sql
✅ dim_scheme.sql
✅ agg_merchant_metrics.sql (aggregated merchant summary, sources net_revenue from fct)
✅ agg_card_metrics.sql (aggregated card summary, sources net_revenue from fct)

### House Style
✅ Import / logic / final CTE structure on both agg models
✅ Role-named CTEs (not duplicating referenced model names)
✅ Both agg models linting clean

### Testing and Documentation
✅ Not-null tests on all primary keys
✅ Unique tests on all primary keys
✅ Accepted values tests on status columns (dim_card.card_status)
✅ Relationships tests on all fact foreign keys (orphaned-key guards)
✅ Full mart test suite passing (27 tests)
✅ Model and column descriptions (marts: grain-first, surrogate-key vocabulary in _marts.yml)
✅ dbt docs generated and reviewed (docs site renders, descriptions surface)
✅ DAG reviewed and clean (refactor wiring confirmed; leaf dims understood as BI endpoints)
⏳ Custom singular test: interchange_fee > 0
⏳ Staging layer tests and descriptions
⏳ Lint cleanup across remaining models (staging, fct, dims)

### Metrics Layer
✅ Net revenue defined once in fct_transactions (sourced by both agg models)
✅ Interchange revenue defined (interchange_fee, aggregated in agg_merchant_metrics)
✅ Chargeback rate defined (is_chargeback flag + chargeback_pct in agg_merchant_metrics)
🔄 Fraud rate (is_fraud flag on fct; surfaced as a DAX measure in Power BI — not yet in an agg model)

---

## Phase 3 — Power BI (Lite)
Goal: Build one solid semantic model and executive dashboard.

### Setup
✅ Power BI Desktop installed
✅ Connected to Postgres in Import mode (chose Import over DirectQuery — static data, full DAX surface)
✅ PBIP format enabled
⏳ Tabular Editor 3 installed (deferred, non-blocking)
⏳ DAX Studio installed (deferred, non-blocking)

### Semantic Model
✅ Star schema imported from dbt marts (7 tables from dbt_dev: fct + 6 dims)
✅ Relationships configured correctly (6x one-to-many dim→fact, single cross-filter direction)
✅ Removed ambiguous dim_bank→dim_merchant auto-detected relationship
✅ Marked dim_date as date table (on transaction_date) — required for time intelligence
⏳ Row-level security implemented (CFO vs merchant view)

### Report Pages
⏳ Executive KPI page
    ⏳ Net revenue
    ⏳ Total interchange
    ⏳ Fraud rate
    ⏳ Chargeback rate
    ⏳ Active cards
⏳ Merchant analysis page
    ⏳ Top 10 merchants by revenue
    ⏳ Revenue by merchant category
⏳ Risk page
    ⏳ Fraud by scheme
    ⏳ Chargeback trend

### DAX Measures
✅ NetRevenue = SUM(net_revenue) — dbt-defined metric, summed under filter context
✅ FraudRate = fraud transactions / total transactions
✅ ChargebackRate = chargebacks / total transactions
✅ TotalInterchange = SUM(interchange_fee)
✅ ActiveCards = count of dim_card where card_status = 'active'
✅ MoMRevenue (absolute) = CALCULATE([NetRevenue], PREVIOUSMONTH(dim_date[transaction_date]))
✅ MoMRevenueChange% = guarded pct change (BLANK when prior month ≤ 0)

### Version Control
✅ Power BI project in PBIP format
✅ Committed to GitHub

---

## Phase 4 — DE Infrastructure
Goal: Add orchestration and cloud warehouse.

### Airflow
⏳ Airflow installed via Docker
⏳ DAG built: truncate → generate → dbt run → dbt test
⏳ Schedule configured (nightly)
⏳ Failure alerting configured
⏳ Astronomer Cosmos installed

### Snowflake Migration
⏳ Snowflake free trial set up
⏳ Schema migrated to Snowflake
⏳ dbt pointed at Snowflake
⏳ Power BI connected to Snowflake

### Data Observability
⏳ Elementary dbt package installed
⏳ Freshness monitors configured
⏳ Volume monitors configured
⏳ Anomaly detection configured
⏳ Data quality report generated

### Docker Compose
⏳ docker-compose.yml created
⏳ Full stack spins up with one command

---

## Phase 5 — Portfolio Polish
Goal: Make the project hireable.

### Documentation
⏳ GitHub README tells the full story
⏳ Architecture Decision Record written
⏳ Metric catalog documented
⏳ Data lineage diagram created (lineage graph screenshot captured — ready to embed)

### Presentation
⏳ Loom walkthrough recorded (10-15 mins)
⏳ LinkedIn post drafted
⏳ CV updated with project

---

## Learning Log Status
✅ Session 1 — Environment setup
✅ Session 2 — Schema design
✅ Session 3 — Data generation script
✅ Session 4 — SQL analysis (Query 1: net revenue per merchant)
✅ Session 5 — SQL analysis (Queries 2 & 3: monthly trends, fraud rate)
✅ Session 6 — SQL analysis (Queries 4, 5 & 6) — Phase 1 complete
✅ Session 7 — dbt setup and first staging model
✅ Session 8 — Intermediate layer and ref()
✅ Session 9 — Mart layer and star schema design (+ mock interview, metrics refactor)
✅ Session 10 — dbt testing and completing the star schema (bank & scheme dims)
✅ Session 11 — Metrics layer, CTEs & import/logic/final house style, linting (SQLFluff), git recovery
✅ Session 12 — Documentation (model/column descriptions, dbt docs site, lineage review)
✅ Session 13 — Power BI: Import vs DirectQuery, atomic grain, semantic model & relationships
✅ Session 14 — DAX measures (net revenue, fraud/chargeback rate, interchange, active cards, MoM revenue + guarded pct); dim_date year-month label; date table marking
⏳ Sessions 15+ — Report pages (executive KPI, merchant, risk); RLS; staging tests & lint cleanup (deferred)

---

## DataCamp Courses
✅ Understanding Data Engineering
🔄 Introduction to dbt (in progress)
🔄 Introduction to Power BI (Phase 3 in progress)
⏳ Introduction to Airflow (start Phase 4)
⏳ Introduction to Snowflake (start Phase 4)
🔄 Associate Data Engineer in SQL (ongoing)

## Coursera
⏳ DeepLearning.AI Data Engineering Certificate (start after Phase 2)</document_content>