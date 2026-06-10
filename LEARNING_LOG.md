## Session Checklist

### Before every session
1. Start Docker container: `docker start fintech-db`
2. Navigate to project folder: `cd /c/Users/hadzh/OneDrive/Desktop/BI\ Project`
3. Activate virtual environment: `source dbt-env/Scripts/activate`
4. Navigate to dbt project: `cd fintect_dbt`


# Learning Log

## Session 1 — Environment Setup

### Docker

```powershell
docker run --name fintech-db -e POSTGRES_PASSWORD=admin123 -e POSTGRES_USER=analyst -e POSTGRES_DB=fintech -p 5432:5432 -d postgres:15
```
**What it does:** Creating an postgress db image with docker. Setting credentials and port.

---

```powershell
docker ps
```
**What it does:** Provides overview of running docker containers

---

### Git & GitHub

```powershell
git init
```
**What it does:** initializing git repo locally 

---

```powershell
git remote add origin https://github.com/hadzhiev96/fintech-bi.git
```
**What it does:** connecting local repo to remote one

---

```powershell
git pull origin main --allow-unrelated-histories
```
**What it does:** syncronizing local and remote repos, the additional specifications are required due the repos being crated independently one of another 

---

```powershell
git add LEARNING_LOG.md
```
**What it does:** adding files to the staging area, waiting to be commited

---

```powershell
git commit -m "initial commit: add learning log"
```
**What it does:** commiting files from the staging area

---

```powershell
git push origin main
```
**What it does:** uploading files to the remote repo, specifying which branch exactly

---

```powershell
git pull origin main --rebase
```
**What it does:** pulling everything from the remote repo and putting my files on top of it

---

```powershell
git branch -m master main
```
**What it does:** renaming my branch

---

```powershell
git push origin main --force
```
**What it does:** --force tells GitHub "ignore whatever you have, replace it with exactly what I'm sending you." Normally Git rejects a push if the remote has commits your local doesn't — it protects you from overwriting someone else's work. Force bypasses that protection.

## Session 2 — Schema Design

### Key Concepts

**Star Schema**
What it is: A denormalized data model suited for analytics. 
Fewer, wider tables mean less joins and faster queries.
Why we use it instead of normalized tables: Normalized tables 
are optimized for writing data consistently. Star schema is 
optimized for reading and aggregating data fast. 
Rule to remember: normalize to write, denormalize to analyze.

**Fact Table**
What it is: The table containing the main event we report on. 
Holds foreign keys to all dimensions and the numeric measures 
(amounts, fees, losses).
Why transaction is our fact table: It is the event that connects 
every other entity simultaneously — customer, card, merchant, 
bank, scheme. Everything we aggregate is ultimately a transaction.

**Dimension Tables**
What they are: The descriptive context around the fact. 
Who, where, what type, through which network.
How they connect to the fact table: Via foreign keys. 
The fact table holds the key, the dimension holds the description. 
They are the lenses through which we slice and analyze.

**How Paynetics makes money**
Interchange: A % fee on every transaction, paid by the 
merchant's bank to Paynetics. The main revenue stream.
Scheme fees: Fees paid TO Visa/Mastercard for using their 
network. This is a cost, not revenue. 
Net interchange = interchange earned minus scheme fees paid.
FX margin: A markup applied to cross-currency transactions. 
Customer pays slightly above the real exchange rate — 
Paynetics keeps the difference.
Card program fees: B2B revenue. Companies like Payhawk pay 
Paynetics to issue and manage cards on their behalf — 
setup fees, monthly program fees, per-card fees.
Chargebacks/fraud: Losses, not revenue. When a customer 
disputes a fraudulent transaction, Paynetics refunds them 
and absorbs the loss unless it can be recovered.

### Question for next session
Why does dim_date exist as a separate table instead of 
just a date column in fact_transactions?
My answer: To slice and analyze data at any granularity 
we need — day, week, month, quarter, year — without 
recalculating those attributes every time we query.


## Session 3 — Data Generation Script

### Key Concepts

**Docker Volume**
What it is: A mechanism, mapping a specific directory on my machine to a directory on the container, so data survives the deletion of the container
Why it matters: In case of real data, we secure it against the eventual loss of a container

**psycopg2 Connection vs Cursor**
Connection: The main connection between postgress db and python. We use it to persist data and keep the connection open.
Cursor: The object that allows query exectuion and data retrival from the postgress db
Why commit() belongs to connection:  Because it goes beyond the scope of just querying data, where we want the information to be persisted we need to use connection

**Atomicity**
What it is: The fail-save mechanism that ensures that all part of a transaction have passed, in the other case we call rollback
Why it matters for our pipeline: For the same reason it matters in all data pipelines, to ensure data integrity

**PEP 8**
What it is: Python style code
Key rules we follow: functions, variables follow snake_case. WE always use 4 identations 

**SQL Injection**
What it is: A way to abuse not smart versions of sql 
How %s placeholders protect us: It sanitazes inputs so they are never treated as executable commands. 

**cursor.fetchall()**
What it returns: Provides the whole result set of the last executed query.
Why we use list comprehension on it: Because it returns a list of tupples, having the values for each column in that row so we unpack it

**Ternary Expression**
What it is: A short one-line if statement
Example from our code: random.choice(block_reasons) if is_blocked else None

### Business Logic in fact_transactions
Fraud rate assumption: 2% of transactions are fraudulent
Chargeback rate assumption: 60% of fraudulent transactions get disputed
Fraud loss assumption: between 50-100% of transaction amount is lost
FX rate assumption: 30% of transactions are cross-currency

### Dependency Order
Why order matters when populating tables: Because some tables have foreign key dependencies, and in order to be populated, we need to have data to populate them.
Our load order and why: Our order is exactly tailored to that.

### CFO Question for next session
What is the first business question a Paynetics CFO 
would ask about this transaction data?
My answer: % of fraudulent transactions 

## Session 4 — SQL Analysis (Query 1)

### Key Concepts

**LEFT JOIN vs INNER JOIN in analytical queries**
LEFT JOIN: Keeps all rows from the left table, fills NULL for unmatched rows on the right.
INNER JOIN: Only keeps rows that have a match on both sides.
Rule to remember: Use INNER JOIN in analytical queries where you only want attributable results. Use LEFT JOIN separately as a data quality check to surface orphaned records.

**Why you never GROUP BY or JOIN on names**
Names are dirty — duplicates, typos, capitalisation differences can collapse rows silently.
Always join and group on surrogate keys (merchant_key, customer_key etc.).
Real example from our data: Two merchants named "Ortega Inc" with different merchant_keys collapsed into one row when we grouped by name — we lost a merchant silently.

**Aliased columns in SELECT**
SQL evaluates the SELECT list all at once — you cannot reference an alias you defined in the same SELECT.
Wrong: (interchange_fee - scheme_fee - fraud_loss) AS net_revenue
Right: (SUM(ft.interchange_fee) - SUM(ft.scheme_fee) - SUM(ft.fraud_loss)) AS net_revenue

**Data integrity checks belong in a separate layer**
Analytical queries assume clean data and report metrics.
Data quality checks (orphaned keys, NULL foreign keys) belong in separate queries or dbt tests — not baked into every analytical query.
We confirmed: 0 orphaned transactions in our dataset.

**GROUP BY without SELECT**
You can GROUP BY a column without selecting it. But if it's a key that makes rows unique, you should select it anyway — you'll need it for future joins.

**COUNT(*) vs COUNT(column)**
COUNT(*) counts all rows including NULLs.
COUNT(ft.transaction_key) is more explicit — makes clear you are counting transactions, not just rows. Better habit.

### Git Commands Learned
mkdir -p sql/analysis — creates nested folders in one command. -p means parents, creates the full path even if none of it exists yet.
cd .. — go up one directory
cd ../.. — go up two directories
git add sql/ — stage a specific folder instead of everything
git status — shows staged (green), unstaged (red), and untracked files

### Business Insight from Query 1
27 out of 100 merchants have negative net revenue.
This means fraud losses exceed interchange revenue for those merchants.
In a real fintech this triggers: enhanced monitoring, potential offboarding, or fraud investigation.

### CFO Question — Answered
First question a Paynetics CFO would ask: what is our net revenue per merchant?
That is exactly what we built in query 1.

### Query committed
net_revenue_per_merchant.sql → /sql/analysis/


## Session 5 — SQL Analysis (Queries 2 & 3)

### Key Concepts

**SQL Execution Order**
SQL executes in this order, which affects how you write queries:
FROM → JOIN → WHERE → GROUP BY → SELECT → ORDER BY
Write queries in this order too — start with FROM, build outward.
Why it matters: You cannot reference a SELECT alias in a WHERE clause
because WHERE runs before SELECT is evaluated.

**Reserved Words as Column Names**
year and month are reserved words in SQL — Postgres uses them in
functions like EXTRACT(YEAR FROM date).
Quoting them with "" tells Postgres they are column names, not keywords.
Better practice: name columns transaction_year, transaction_month in
your schema to avoid this entirely. We will fix this in dbt.

**Integer Division**
Dividing two integers in Postgres truncates the decimal — 21 / 1000 = 0.
Always cast to decimal when calculating rates or percentages:
SUM(...)::decimal / COUNT(...)::decimal
Rule to remember: any time you calculate a rate, cast first.

**COUNT vs SUM for conditional counting**
COUNT(column) counts all non-NULL values regardless of the value.
SUM(CASE WHEN condition THEN 1 ELSE 0 END) counts only rows
where the condition is true.
Use SUM with CASE when you need to count a subset of rows.

**Identifying fraud without a boolean flag**
Our fact_transactions table has no is_fraud column — it was used
in the Python script to calculate fraud_loss but never inserted.
Lesson: fraud_loss > 0 is our proxy for a fraudulent transaction.
Broader lesson: always check what columns actually exist in the table
before assuming the data you need is there.

**Naming conventions**
Alias columns clearly — fraud_rate_pct not fraud_rate when the
value is a percentage. Makes output self-documenting.
File naming: match the project plan description, snake_case,
no unnecessary words. fraud_rate_by_scheme.sql not
fraud_percentage_per_scheme_fee.sql.

### Git Commands Learned
touch filename — creates an empty file via Git Bash
mv old_name new_name — renames a file (or moves it)

### Queries Committed
monthly_volume_and_revenue_trends.sql → /sql/analysis/
fraud_rate_by_scheme.sql → /sql/analysis/

## Session 6 — SQL Analysis (Queries 4, 5 & 6)

### Key Concepts

**Window Functions**
Perform calculations across rows related to the current row without
collapsing them like GROUP BY does.
Basic syntax: FUNCTION() OVER (PARTITION BY ... ORDER BY ...)
PARTITION BY: resets the calculation per group, rows stay separate
ORDER BY: defines the order of rows within the partition

**LAG()**
Returns the value from the previous row in the defined order.
LAG(net_revenue) OVER (ORDER BY year, month)
First row always returns NULL — no previous row exists. This is correct behavior.

**Chaining CTEs**
When you need to reference a SELECT alias in further calculations,
wrap it in a second CTE and build on top of it.
Pattern we used:
CTE 1 → aggregate base metrics
CTE 2 → apply window function on aggregated result
Final SELECT → calculate derived metrics from CTE 2
This is the same mental model as dbt layers — each step builds on the previous.

**Integer Division Reminder**
Dividing two integers truncates the decimal in Postgres.
Always cast to decimal before dividing: value::decimal / total::decimal

**Guarding Against Bad Denominators**
When calculating percentages, always guard against:
NULL — no previous value exists
Zero — division by zero throws an error
Negative — percentage becomes mathematically misleading
Pattern: CASE WHEN prev_value IS NULL OR prev_value <= 0 THEN NULL
ELSE ROUND(... * 100, 2) END

**Boolean Columns in SQL**
Can filter directly: WHERE is_chargeback = TRUE
Or shorthand: WHERE is_chargeback
For conditional aggregation use CASE WHEN is_chargeback = TRUE THEN 1 ELSE 0 END

**Subquery vs CTE for Denominators**
Wrong: using a subquery SELECT COUNT(*) FROM fact_transactions as denominator
gives total across all groups, not per group.
Right: COUNT(ft.transaction_id) in the same GROUP BY context calculates
per group automatically.


### Business Insights
Top 10 merchants by interchange revenue identified.
Chargeback rates by merchant category all below 2% — consistent with
60% of 2% fraud rate from data generation logic.
MoM revenue swings are volatile due to random fraud distribution in
synthetic data — noted as known limitation in period-over-period query.

### Queries Committed
top_10_merchants_by_interchange_revenue.sql → /sql/analysis/
chargeback_rate_by_merchant_category.sql → /sql/analysis/
period_over_period_revenue_comparison.sql → /sql/analysis/

### Phase 1 — Complete
All 6 analytical SQL queries written and committed.
Star schema designed, data generated, queries cover:
net revenue, monthly trends, fraud rate, top merchants,
chargeback rate, and period-over-period comparison.
Ready for Phase 2 — dbt Core.


## Session 7 — dbt Setup and First Staging Model

### Key Concepts

**Virtual Environment**
An isolated Python installation for a specific project.
Packages installed inside it don't affect your global Python.
Uses exactly the Python version you specify.
Must be activated every new terminal session.
Why it matters: prevents version conflicts between projects.

**dbt Project Structure**
models/ — where you write SQL transformations. 90% of your time.
staging/ — one model per source table, clean and rename only
intermediate/ — join staging models, apply business logic
marts/ — final analytical tables, what Power BI connects to
seeds/ — small CSV reference data loaded directly into the database
tests/ — custom data quality tests
macros/ — reusable Jinja/SQL helper functions
snapshots/ — SCD Type 2 slowly changing dimensions
logs/ — dbt run logs, don't touch

**Medallion Architecture**
Three layer approach to data transformation.
Raw → Staging (bronze) → Intermediate (silver) → Marts (gold)
Each layer only references the layer directly below it. Never skip layers.
Staging: clean and rename raw data, no business logic
Intermediate: join and enrich, apply business logic
Marts: aggregated, business ready, CFO readable

**sources.yml**
Declares your raw source tables to dbt.
dbt reads all yml files automatically — no explicit import needed.
Tells dbt the database, schema, and table names for raw data.
Acts as a contract between dbt and your database.

**Jinja and dbt Functions**
Double curly braces {{ }} are Jinja syntax — tells dbt to execute
the function and replace it with the result.
source('source_name', 'table_name') — references a raw source table.
dbt resolves it to the full path: database.schema.table
ref('model_name') — references another dbt model. Used in intermediate
and mart layers. Never hardcode table paths in dbt.
Both source() and ref() are how dbt builds the lineage graph.

**Materializations**
Controls how dbt builds a model in your database.
view — stores only the query, data computed on every query. Default.
table — physically stores data, computed once at run time.
incremental — only processes new or changed rows, efficient for large tables.
ephemeral — not built in database, interpolated as CTE into referencing models.
Staging and intermediate → view. Marts → table.
Configured in dbt_project.yml per folder.

**dbt run**
Compiles SQL models and executes them against your database.
dbt run --select model_name — runs a specific model only.
Output format to read: PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1

### Commands Learned
py "-3.12" -m venv dbt-env — create virtual environment with Python 3.12
source dbt-env/Scripts/activate — activate virtual environment
dbt init project_name — initialize a new dbt project
dbt debug — test dbt connection to database
dbt run --select model_name — run a specific model

### Progress
dbt installed and connected to Postgres.
Project structure created: staging, intermediate, marts folders.
sources.yml declared all 7 raw tables.
stg_transactions.sql — first staging model created and
running as view in dbt_dev schema.
More precisely — dbt is a Python tool that:

Takes your SQL SELECT statements
Wraps them in the right CREATE TABLE or CREATE VIEW commands automatically
Uses ref() and source() to understand dependencies and build in the right order
Uses YAML files for configuration, testing, and documentation
Brings software practices to SQL — version control, testing, documentation, modularity

You write only the SELECT. dbt handles everything else.

# Session 8 — Intermediate Layer and ref()

### Key Concepts

**ref()**
The dbt function for referencing other dbt models (as opposed to source()
which references raw tables).
Syntax: {{ ref('model_name') }} — argument is the filename without .sql
Compiles to the full path where dbt built that model: database.schema.model
Two reasons to use it:
1. Portability — never hardcode schema names. If models move (e.g. to
   Snowflake), ref() resolves to the new location automatically.
2. Dependency tracking — every ref() call tells dbt "this model depends on
   that one." dbt uses all ref() calls to build the DAG and determine build
   order automatically. You never specify order manually.
Rule: source() appears only in staging. Everywhere above staging, use ref().

**CTE-per-source pattern for multi-join models**
For a model that joins many tables, structure it with one CTE per source
using ref(), then a final SELECT that joins the CTEs.
Keeps each input isolated and readable.
Same chained-CTE mental model as analytical SQL, now across dbt models.

**Enriched fact table**
An intermediate model that takes the fact table and joins dimensional
context onto it (names, categories) so downstream models and analysts
get descriptive attributes without re-joining.
Drive from the fact table; join each dimension onto it by its key.

**Chained INNER JOIN row loss**
With multiple INNER JOINs, a row must match in EVERY joined table to survive.
Failing even one join drops the row entirely.
Think of each INNER JOIN as a filter gate stacked in sequence — fail any
gate and the row is gone, taking its measures with it.

**LEFT JOIN as the fail-safe default for fact tables**
For a fact-grain model, losing a row means losing its measures (revenue,
fees, losses) from every downstream aggregation — the worst failure mode
because it is silent.
LEFT JOIN (driving from the fact) keeps every transaction regardless of
dimension matches. Unmatched dimension columns come back NULL.
A NULL dimension attribute is a visible, debuggable problem.
A missing transaction is an invisible one.
Tradeoff: LEFT lets dirty data (NULLs) through, so you need tests
(not_null, relationships) to catch it. INNER hides dirt by dropping rows,
which feels clean but is more dangerous.
LEFT is the correct default posture for a fact table — it fails safe.

**Materialization recap for layers**
Staging → view. Intermediate → view. Marts → table.
Configured per folder in dbt_project.yml.

### Commands Used
dbt run --select model_name — build a single model
dbt run --select staging — build all models in a folder