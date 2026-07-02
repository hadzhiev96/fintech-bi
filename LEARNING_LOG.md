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

## Session 9 — Mart Layer and Star Schema Design

### Key Concepts

**Fact vs Dimension — measures vs attributes**
A measure is a numeric value you aggregate (sum, average) — revenue, fees,
amounts, counts. Measures belong on the FACT table.
An attribute is a descriptive property you filter and group BY — name,
category, status, location. Attributes belong on DIMENSION tables.
A status flag like is_blocked is an attribute, not a measure — you filter
by it, you don't sum it.
Clean fact table = grain key + foreign keys + measures only. No descriptive
bloat.
Clean dimension = one row per entity + descriptive attributes only. No measures.

**Why marts materialize as tables (not views)**
Materialization controls WHEN the work happens.
View = the query re-runs every time someone queries it (work at read time).
Table = computed once when dbt runs, then physically stored (work at build time).
A view-only chain forces the database to walk the entire chain of joins and
aggregations on every single query.
Marts are queried constantly by BI tools and users, so you pay the expensive
computation once at build time and read instantly thereafter.
Staging and intermediate stay views — only dbt queries them, briefly, while
building. Marts become tables — the faucet people actually use.
Nuance: a heavy intermediate model that many marts depend on can also be
materialized as a table. Materialization is a per-model performance decision,
not a rigid layer rule.

**Star schema — single-path rule**
In a star schema, every dimension connects directly to the fact table, and
dimensions do NOT connect to each other. The fact is the central hub.
A dimension should not carry foreign keys to other dimensions (e.g. dropping
bank_key from dim_merchant, customer_key from dim_card), because the fact
already links to those dimensions directly.

**Ambiguous-path risk**
If there is more than one route from the fact to a dimension (e.g. a direct
fact->customer link AND an indirect fact->card->customer link), the BI engine
cannot tell which path you mean.
Result: either it refuses with an "ambiguous relationship" error, or it
silently picks one path and may produce wrong (e.g. double-counted) numbers.
A clean star guarantees exactly one path from fact to each dimension, so
aggregations are deterministic.
Snowflake schema = dimensions linking to other dimensions; avoided here in
favour of a clean fact-centric star.

**DRY — why centralize joins**
A join encodes a business rule ("this is how a transaction connects to a
merchant"). Repeating that join across many models repeats the rule.
Repeated logic drifts out of sync (one model uses LEFT, another INNER; one
filters blocked customers, another forgets) and is painful to change.
Centralizing joins in a foundational model (int_transactions_enriched) gives
one source of truth: every downstream model is consistent by construction,
and there is a single place to maintain when logic changes.
This is the software-engineering principle DRY — Don't Repeat Yourself —
applied to analytics. Same idea as base classes / inheritance.
(Performance is a secondary benefit: the join is computed once, not many times.
Lead with single-source-of-truth and consistency, not performance.)

**dbt as the T in ELT**
dbt is a transformation tool, not an analysis tool.
Extract -> Load (raw into warehouse) -> Transform (dbt) -> Analyze (Power BI).
dbt prepares trustworthy, analysis-ready tables; it does not produce the
insight itself. This transformation layer is what defines the analytics
engineer role versus the analyst role.

**Naming conventions across layers**
Staging mirrors the source — named after the raw tables it lightly cleans.
Marts use Kimball convention: dimensions named singular (dim_merchant — each
row IS one merchant), facts named for the business process/event
(fct_transactions).
Conventions are not laws; what matters is consistency within a layer and
following the dominant industry pattern so the repo reads as standard.

### Commands Used
dbt run --select model_name — build one model
dbt run --select marts — build all models in the marts folder
rm path/to/file — delete a file (permanent, no recycle bin — read the path
  carefully before running)
  ### Layer Placement — Endpoint vs Stepping Stone

The layer a model belongs in is decided by its ROLE, not by when you built it.

Intermediate model = a stepping stone. Reusable building block consumed by
OTHER models, never directly by a BI tool or analyst.
Example: int_transactions_enriched — nobody reports off it; it exists so other
models can build on it.

Mart model = an endpoint. A finished, business-ready table consumed DIRECTLY
by a BI tool or analyst.

The test: "Does anything downstream consume this, or is it an endpoint?"
- Consumed by another model → intermediate.
- Read directly by Power BI / an analyst → mart.

A pre-aggregated summary table (one row per merchant with KPIs) is an endpoint,
so it belongs in the mart layer — even though it is an aggregation built on top
of an intermediate model. Putting it in intermediate just because of build order
is a design smell.

Naming: aggregated summary marts use a prefix that signals their nature —
e.g. agg_ (agg_merchant_metrics) or mart_ (mart_merchant_summary).

### dbt Connection Architecture

The database connection is NOT stored in the project. It lives in:
  ~/.dbt/profiles.yml
(~ = home directory; .dbt is a hidden folder, dot-prefix hides it from ls)

Why outside the project: profiles.yml holds credentials (host, port, user,
password). The project folder is committed to GitHub and shared. Keeping
credentials in a separate home-directory file keeps secrets out of version
control.

Two files link by NAME:
1. dbt_project.yml (in the project) has:  profile: 'project_name'
2. profiles.yml (in ~/.dbt) has a matching block of the same name, containing
   type, host, port, user, password, dbname, schema, threads, and a target.

target (e.g. dev) selects which output block is active. You can keep separate
dev and prod connection blocks under one profile.

Connection flow on a run:
dbt reads dbt_project.yml → finds profile name → opens ~/.dbt/profiles.yml →
finds the matching block → reads the active target → connects to the database →
builds models into the configured schema.

dbt debug tests this entire chain end to end.

### dbt Tests — Overview

Tests turn a set of models into a trustworthy pipeline. Same purpose as unit
tests in software, but they assert DATA state, not code logic.

Generic tests — reusable, declared in YAML, applied to columns:
- unique          — no duplicate values
- not_null        — no NULLs
- accepted_values — value must be from a defined list (good for status columns)
- relationships   — every value must exist in another table's column
                    (guards against orphaned foreign keys: e.g. every
                    merchant_key in the fact must exist in dim_merchant)

Singular tests — custom SQL queries for one specific check (e.g.
interchange_fee > 0). Stored as .sql files in the tests/ folder.

Tests are declared in a YAML schema file alongside the models. One per layer
or one per folder.

### Renaming / Refactoring dbt Models

A dbt model's name IS its filename. Renaming the file renames the model.
Renaming breaks any other model that referenced the old name via ref().

Workflow for a safe rename/move:
1. Move + rename the file (mv).
2. Search for stale references before running:  grep -r "old_name" models/
   (grep searches text inside files; -r = recursive through subfolders)
   Empty result = nothing references it, safe to proceed.
3. Re-run and verify (a model moved into marts/ will now build as a table,
   per the folder's materialization config).
4. Clean up orphans: dbt does NOT auto-drop database objects you stop managing.
   A renamed model leaves its old view/table behind in the schema. Drop stale
   objects manually (DROP VIEW IF EXISTS schema.name) — dbt has no built-in
   "delete what I no longer manage" command out of the box.


## Session 10 — dbt Testing and Completing the Star Schema

### Key Concepts

**Why tests matter**
Tests turn a collection of models into a trustworthy pipeline. Same purpose as
unit tests in software, but they assert DATA state, not code logic.
They codify checks you would otherwise run by hand (e.g. hunting for duplicate
keys or orphaned foreign keys) so they run automatically on every build.
A test only protects you if the test itself is correct — a wrong test (e.g.
pointing at the wrong field) gives false confidence.

**Two kinds of tests**
Generic tests — reusable, declared in YAML, applied to columns.
Singular tests — custom SQL queries for one specific check, stored as .sql
files in the tests/ folder (e.g. interchange_fee > 0).

**The four built-in generic tests**
unique          — no duplicate values in a column.
not_null        — no NULLs.
accepted_values — value must come from a defined list. Only meaningful on
                  columns the database does NOT already constrain (e.g. a
                  varchar status column). Redundant on a true boolean, because
                  the column type already guarantees true/false.
relationships   — every value in a column must exist in another table's column.
                  Guards foreign keys against orphans (e.g. every merchant_key
                  in the fact must exist in dim_merchant).

**Test plan for a star schema**
Every dimension primary key: unique + not_null.
Every fact foreign key: not_null + relationships (to its dimension's key).
Status/category columns with a fixed value set: accepted_values.
not_null on a foreign key is a business decision — it asserts "this link is
always present." Only apply it where that is genuinely required.

**Layer placement — endpoint vs stepping stone (revisited)**
Completing the test suite surfaced a gap: the fact referenced bank_key and
scheme_key, but no dim_bank / dim_scheme existed in the mart layer.
Writing tests forces every foreign key to have a dimension to point at, which
is why testing exposes incomplete star schemas.

**relationships tests should stay within the layer**
A relationships test can technically point at any model, including staging.
But a mart fact should relate to mart dimensions, not reach back into staging.
Keeping references within the curated layer preserves clean layer separation
and matches how a BI tool will later build its star schema.
Principle: a mart fact relates to mart dimensions; do not reach back down a layer.

**Dimension attribute vs reference data**
A numeric value like interchange_rate is borderline. If the computed result
(interchange_fee) already lives on the fact, the rate in the dimension is
reference data you may not use. Keep a column only if it will be filtered,
grouped, or displayed; otherwise drop it to keep the dimension lean.
Make the inclusion decision consciously, not by reflex.

**run vs test vs build**
dbt run   — builds models (views/tables). Does NOT execute tests.
dbt test  — executes the declared tests. Does NOT build models.
dbt build — runs and tests in dependency order in one pass (build a model,
            test it, then proceed). The common everyday command.
dbt run --select marts runs only that folder; dbt test --select marts tests
only that folder.

**YAML schema file**
Tests are declared in a schema YAML alongside the models (e.g. _marts.yml;
leading underscore sorts it to the top of the folder).
Structure: models is a list; each model has columns; each column has tests.
A simple test is just its name (- unique). A test with arguments is a key with
nested parameters (- relationships: then indented to:/field:).
YAML is whitespace-sensitive: spaces not tabs, 2 spaces per level, "- " for
list items, "key: value" with a space after the colon. Arguments of a test
indent PAST the dash of the test name.

**Deprecation note**
In dbt 1.8 the YAML key `tests:` is being renamed to `data_tests:`. Both work
for now, but data_tests: is the current syntax.

**Test count reflects parsed state**
dbt only counts tests it has fully parsed. A partially written schema file
registers fewer tests; completing it registers all of them.


# Session 11 — Metrics Layer, CTEs & House Style, Linting, Git Recovery

---

## 1. The Metrics Layer

### The problem it solves
A business metric like *net revenue* is a **definition**, not just a number. If that
definition lives in several different queries and models, then changing it (e.g.
excluding a new fee type) means hunting down and editing every copy. Divergent copies
drift apart silently. This is the **DRY principle applied to business definitions**,
not just to SQL joins — the same instinct as extracting a reused calculation into a
single method rather than copy-pasting it.

### The ideal: define once, reference everywhere
The conceptual goal is a single authoritative place where a metric's formula lives,
which any downstream consumer (another model, Power BI, an ad-hoc query) references by
name instead of re-deriving.

### The dbt Core reality
dbt's native semantic/metrics layer has changed significantly across versions and is
limited in dbt Core without additional packages. The **pragmatic portfolio approach**
is to define each metric **once as a well-named column at the lowest sensible grain** —
the fact table — so every consumer aggregates the same pre-defined value.

- `net_revenue = interchange_fee - scheme_fee - fraud_loss`, computed once in
  `fct_transactions` at the transaction grain.
- Downstream models then `SUM(net_revenue)` rather than re-writing the formula.

### Row-level vs. aggregated metrics
- **Additive measures** (net revenue, fraud loss) can live as a row-level column and be
  summed at any grain.
- **Rates** (fraud rate, chargeback rate) are *counts divided by totals* — they only
  exist after aggregation. At the row grain you store the **boolean ingredients**
  (`is_chargeback`, `is_fraud`) and compute the rate when you aggregate.
- `is_fraud` is derived as `CASE WHEN fraud_loss > 0 THEN TRUE ELSE FALSE END`, kept as
  a clean flag consistent with `is_chargeback`.

### Endpoint models and descriptive attributes
When an aggregate model is an **endpoint** (consumed directly, not a stepping stone),
it should carry its descriptive names (`merchant_name`, `card_type`) so consumers don't
have to join back to a dimension. Because a clean fact table holds only **keys and
measures**, those descriptive attributes must be **joined in from the dimension** inside
the aggregate model — fact for the numbers, dimension for the names.

---

## 2. CTEs and the Import / Logic / Final House Style

### Why CTEs (independent of dbt)
1. **Readability** — name each transformation stage and read top-to-bottom instead of
   decoding nested subqueries inside-out.
2. **Avoiding repetition** — define an intermediate result once, reference it by name.
   (Note: most warehouses still re-execute each reference under the hood — the benefit
   is code clarity, not query speed.)
3. **Debuggability** — temporarily change the final `SELECT` to read from an
   intermediate CTE to inspect exactly what that stage produced.

CTEs are **not** a performance feature. In Postgres and most warehouses they don't make
queries faster; older Postgres versions even treated them as optimization fences. You
use them for *human* reasons.

### The dbt house style: import / logic / final
Every model follows the same shape so any file is instantly navigable:

- **Import CTEs** (top) — one per `ref()` / `source()`, doing nothing but pulling in an
  upstream model. Kept pure: one ref, no logic.
- **Logic CTEs** (middle) — the actual joins and transformations.
- **Final SELECT** (bottom) — the model's output, typically `SELECT * FROM <last_cte>`.

### Naming convention
Name a CTE for its **role**, not by duplicating the model it reads from. A CTE that
selects from `fct_transactions` is named `transactions` / `base` / `source`, never
`fct_transactions` — duplicating the name creates ambiguity between the CTE and the
underlying model in the `FROM` clause.

### The CTE comma rule
In a `WITH` chain, **every CTE gets a comma after its closing `)` except the last one
before the final SELECT**. The two failure modes are mirror images:
- missing comma after a middle CTE, and
- a stray trailing comma after the last CTE.

### Alias qualification in joins
Inside a join, **always qualify columns with their table alias** (`SUM(t.net_revenue)`,
not `SUM(net_revenue)`). A bare reference works only while the name is unique; if a
joined table later gains a same-named column the reference becomes ambiguous and errors.

---

## 3. Linting and SQLFluff

### What linting is
**Linting** is automated checking of code against rules *without running it*. The name
comes from an old Unix `lint` tool (picking "fluff" off code — hence SQL**Fluff**).
Two categories of finding:
- **Style** — works but inconsistent (mixed keyword casing, indentation, trailing
  whitespace). Cosmetic, but consistency is what reads as professional.
- **Correctness / safety** — risky or ambiguous patterns (ambiguous joins, implicit
  column lists). The more valuable catches.

### Linter vs. formatter
- A **formatter** (e.g. Black for Python) silently rewrites code into one style.
- A **linter** can both *report* problems (`lint` mode) and *fix* them (`fix` mode).
  The reporting mode teaches the conventions by naming them, rather than fixing silently.

### SQLFluff modes
- `sqlfluff lint <path>` — read-only; reports violations, touches nothing.
- `sqlfluff fix <path>` — rewrites the file to resolve fixable violations.
  Always re-open the file and eyeball what `fix` changed — never trust an auto-fixer
  blindly. (`fix` only touches formatting, so model logic is unchanged.)

### Rule families seen
- **LT (layout)** — `LT01` spacing, `LT02` indentation, `LT05` long lines,
  `LT09` select-target placement, `LT12` trailing newline.
- **CP (capitalisation)** — `CP01` keyword casing, `CP03` function-name casing. The
  point is *consistency*: pick one case and apply it everywhere (default: uppercase).
- **JJ (Jinja)** — `JJ01` padding: braces should "breathe" —
  `{{ ref('x') }}`, not `{{ref('x')}}`.

### Config and the working-directory lesson
SQLFluff needs a `.sqlfluff` config declaring the **dialect** (`postgres`) and
**templater** (`dbt`). The dbt templater compiles Jinja *through dbt* so `ref()` /
`source()` resolve to real SQL before linting; it requires the `sqlfluff-templater-dbt`
bridge package.

**Command-line tools resolve their config relative to the current working directory,
not relative to the file being operated on.** SQLFluff specifically refuses to honor
the `templater = dbt` setting unless `.sqlfluff` is in the *current working directory*
(not a subdirectory). dbt behaves the same way — it self-locates by searching the
current directory for `dbt_project.yml`. The unifying habit: **run both dbt and
sqlfluff from inside the dbt project root**, where each finds its config automatically.

### Build with tests in one step
`dbt build --select <model>` runs the model **and** its tests together in DAG order —
the production-style alternative to running `dbt run` then `dbt test` separately.

---

## 4. Git: Rewriting and Recovering History

### `git commit --amend`
Replaces the **most recent** commit rather than adding a new one; the old commit is
discarded and a new one with a **different hash** takes its place.
- `--amend -m "..."` — replace the message.
- `--amend --no-edit` — fold newly-staged changes into the last commit, keep the message.

**The amend gotcha:** `--amend` absorbs *whatever is currently staged*. If an unrelated
file is staged, it silently joins the commit. Always check `git status` before amending.

### Inspecting a commit
`git show --stat HEAD` — shows the files and per-file insertion/deletion counts of the
latest commit without the full diff. Use it to verify exactly what a commit contains.

### `git reset` modes
Moves `HEAD` back (`HEAD~1` = one commit before HEAD), un-committing — but the mode
determines what happens to the file changes:
- `--soft` — keeps changes **staged**.
- `--mixed` (default) — keeps changes in the working dir, **unstaged**.
- `--hard` — **permanently discards** the changes on disk. Destructive.

To **re-split** a bad bundled commit into separate commits, use `--mixed`: it unstages
everything so you can `git add` each file individually. **Never** use `--hard` here — it
would wipe the very edits you want to re-commit.

### Force-push: when and how
- A **normal push** appends new commits onto history the remote already shares
  (a fast-forward) — accepted without force.
- A **force push** is needed only when you've **rewritten** commits the remote already
  has, causing the histories to **diverge**. The remote rejects a normal push to avoid
  silently overwriting work.
- Prefer `git push --force-with-lease` over `--force`. `--force-with-lease` aborts if
  the remote moved since you last saw it (protecting someone else's pushed work);
  raw `--force` overwrites unconditionally.

**Rule of thumb:** rewriting history that exists *only locally* is cheap and safe;
rewriting history *already pushed* requires a force-push and is only safe when no one
else has pulled it.

### Commit hygiene principles
- **One coherent change per commit** — if the message needs "and" to join two unrelated
  actions, it's probably two commits.
- **Prefix must match the verb:** `feat:` adds, `refactor:` restructures, `fix:` repairs,
  `chore:` handles tooling/config, `docs:` handles documentation.
- **Present-tense imperative** — "add", "source", "update" (not past tense).
- **Specific over vague**, and **full names over shorthand** in messages (greppable,
  unambiguous in a permanent record).
- **Order commits by dependency** — commit the thing others build on first.
- Parallel changes to parallel models should use **parallel message phrasing**.

### Harmless Windows note
`warning: LF will be replaced by CRLF` is Git normalizing Unix vs. Windows line endings.
Cosmetic, not an error; configurable via `.gitattributes` if desired.

# Session 12 — Documentation, Dimensional Modeling Vocabulary, Lineage

---

## 1. dbt Documentation

### Where descriptions live
Model and column descriptions live in the **YAML schema files** (e.g. `_marts.yml`) —
the same files that hold tests. Documentation is not separate infrastructure; it is
`description:` keys added alongside existing config.

### Placement (YAML is whitespace-sensitive)
- A **model description** is a sibling of `name:` and `columns:` at the model level.
- A **column description** is a sibling of `name:` and `data_tests:` at the column level.

```yaml
  - name: dim_merchant
    description: "One row per merchant. Merchant dimension"
    columns:
      - name: merchant_key
        description: "Surrogate primary key of the merchant dimension"
        data_tests:
          - unique
          - not_null
```

### Schema file placement and naming
Schema YAML files are discovered anywhere under `models/`, but the convention is to
**co-locate one schema file per layer** with the models it documents
(`models/marts/_marts.yml`, `models/staging/_staging.yml`). The leading underscore
sorts the file to the top of the folder and signals "config, not a model."

### What to write
- **Model description** — state the **grain first** ("one row per X"), then purpose.
  The grain is the single most useful fact a model description can carry.
- **Column description** — the column's **business meaning and role**, not a restatement
  of its name. "Surrogate foreign key linking to the merchant dimension," not "the
  merchant key."
- Make load-bearing facts **explicit** rather than relying on the reader to infer them.
  "The code/tests imply it" puts the burden on the reader; documentation exists to
  remove that burden. (But don't document the trivially obvious — restating the column
  name adds nothing.)

---

## 2. Dimensional Modeling Vocabulary (precision matters)

### Grain
The **grain** of a model is what a single row represents ("one row per transaction",
"one row per merchant"). Defining grain first disambiguates everything else.

### Surrogate key vs. natural key
- A **surrogate key** is a system-generated, meaningless integer that uniquely
  identifies a dimension row. It has no business meaning; it exists purely as a stable,
  compact join key.
- A **natural key** (business key) is a real-world identifier (tax ID, card PAN, email).
- Surrogate-vs-natural is an **independent axis** from primary/unique. A natural key can
  also be a tested, unique primary key — so `unique` + `not_null` does **not** imply a
  key is surrogate. The distinction must be stated, not inferred.
- Joining on the **surrogate key** rather than a natural attribute (e.g. a name) is what
  prevents distinct rows that share a name from collapsing together.

### Surrogate foreign keys in the fact
A fact table relates to dimensions through their **surrogate keys**. Each foreign key
value in the fact is therefore a surrogate-key value — "surrogate foreign key" is the
precise description, and it signals that the star schema joins fact-to-dimension via
surrogates, not natural keys.

### Conformed dimension (use only when earned)
A **conformed dimension** is a dimension **shared across multiple fact tables / data
marts** with identical meaning and content in each (e.g. one `dim_date` used by both a
sales fact and an inventory fact, so the two can be compared along the same axis).
With a **single fact table**, no dimension is "conformed" — there is nothing to conform
across. Using the term prematurely claims an architectural property the model lacks, and
an interviewer will ask "conformed across what?". Precise vocabulary is a strength only
when accurate.

---

## 3. The dbt Docs Site

### Generating
`dbt docs generate` compiles the project and produces two artifacts in `target/`:
- **manifest.json** — the lineage metadata (built from `ref()` / `source()` calls).
- **catalog.json** — real table/column metadata, obtained by **querying the warehouse**.

Because it queries the warehouse, the database must be up and models must already be
built. It bundles these artifacts with the YAML descriptions into a static site.

### Serving
`dbt docs serve` starts a local web server (default `http://localhost:8080`) that
renders the artifacts as a navigable site: model pages, column detail, tests, and the
interactive **lineage graph (DAG)**. The command **holds the terminal** until stopped
with `Ctrl+C`. Use `--port <n>` if the default port is busy.

---

## 4. Lineage / The DAG

### What it shows
The lineage graph visualizes **dbt-to-dbt dependencies only**, derived automatically
from `ref()` / `source()`. It reads left-to-right through the medallion layers:
sources → staging → intermediate → marts. It is both a portfolio artifact and a
**correctness check** — misweired or disconnected models are obvious visually in a way
reading SQL is not.

### Leaf dimensions are endpoints, not dead models
A dimension with **nothing downstream of it in the dbt graph** is not unused. Its
consumer is the **BI layer** (Power BI), which dbt cannot see. The fact-to-dimension
joins for slicing metrics happen in the semantic model, not in dbt. A leaf dimension is
an **endpoint**, the same way an aggregated summary model is an endpoint.

---

## 5. Source vs. Derived Artifacts in Version Control

**Only source belongs in version control; derived/build artifacts do not.**
- dbt's `target/` (manifest, catalog, compiled SQL) is **regenerated** by every
  `dbt run` / `dbt docs generate` — it is derived, not source. It belongs in
  `.gitignore` (dbt's default).
- Same principle as never committing a compiled `target/` / `build/` of `.class` files
  in Java: commit the source, let consumers regenerate the build output.
- Committing derived artifacts causes unreviewed machine-generated diffs, instant
  staleness, and repo bloat.

### Making docs visible without committing artifacts
Wanting an interviewer to see the docs is a separate concern from committing build
output. Surface the **output** without versioning the **artifacts**:
- **GitHub Pages** — host the generated docs site and link it from the README.
- **A screenshot** of the lineage graph embedded in the README.

# Session 13 — Power BI: Connection Modes, Atomic Grain, and the Semantic Model

---

## 1. Connection Modes: Import vs. DirectQuery

When connecting Power BI to a database, it asks how to consume the data.

- **Import mode** — Power BI pulls a *copy* of the data into its in-memory columnar
  engine (VertiPaq). Queries run against that local copy. Fast, full DAX feature
  support, but the data is a **snapshot** — only as fresh as the last refresh.
- **DirectQuery mode** — data stays in the source; Power BI sends live queries on every
  interaction. Always current, no copy, but slower and **restricts** parts of the DAX
  surface (notably some time-intelligence and CALCULATE patterns).

### When to choose which
- **Import** is the default for analytical models: faster, full DAX, scheduled refresh.
  Correct for static / synthetic data and for *learning DAX* (no feature restrictions).
- **DirectQuery** is for genuine real-time needs or datasets too large to fit in memory
  (often paired with pre-aggregated tables for performance).

Most production analytical models are Import with periodic refresh, not live-connected.

---

## 2. Import the Atomic Fact, Not the Pre-Aggregated Tables

A BI semantic model should be built on the **atomic fact** (`fct_transactions`, one row
per transaction), not on pre-aggregated summary tables.

### Grain: fixed vs. atomic
- **Grain** = what one row represents ("one row per transaction", "one row per merchant").
- A pre-aggregated table sits at a **fixed grain** decided at build time (e.g.
  `agg_merchant_metrics` is one row per merchant). The detail that fed those totals is
  summed away and **cannot be recovered** — you can't slice it by month or scheme,
  because that detail no longer exists in the table.
- The **atomic fact** sits at the finest grain. Every transaction keeps its full detail
  (date, scheme, amount, fraud flag), so it can be rolled **up** to any coarser grain on
  demand.

**Core principle: you can always aggregate up from a fine grain, but never disaggregate
down from a coarse one.** Pre-aggregated = fast but rigid; atomic fact = flexible,
because every coarser grain is still reachable.

### Why both layers still earn their place
- **Aggregate models (in the warehouse)** = ready-to-serve answers at a fixed grain for
  *any* warehouse consumer (SQL client, notebook, another BI tool), independent of Power
  BI. Also a performance pattern for very large datasets.
- **Atomic fact (in Power BI)** = flexible foundation where DAX computes metrics
  dynamically at whatever grain the user's filters imply.
They are two artifacts for two jobs, not duplicated work.

### Loading discipline
Import only the clean, tested mart models (the dbt `dbt_dev` schema), not the raw source
schema and not the staging/intermediate models. No Power Query cleaning is needed —
that work was already done upstream in dbt. ("Load", not "Transform Data".)

---

## 3. The Semantic Model — Relationships

The **semantic model** is the set of relationships connecting fact and dimensions inside
Power BI. A correct star schema here is what makes every downstream measure and visual
compute correctly.

### Cardinality (one-to-many)
Each dimension relates to the fact as **one-to-many**:
- **One** side = the dimension (one row per merchant — its grain).
- **Many** side = the fact (that merchant appears in many transactions).
Power BI marks the ends of the relationship line: **`1`** on the dimension end, **`*`**
(many) on the fact end. This is the canonical star-schema relationship.

### Cross-filter direction (Single, dimension → fact)
- Filters should flow **one way**: from dimensions *down* to the fact. Selecting a
  dimension value narrows the fact rows.
- Set cross-filter direction to **Single**, not **Both**. Bidirectional (Both)
  re-introduces ambiguity, can produce incorrect numbers, and hurts performance.

### Verifying direction is correct
1. **`1` / `*` markers** (definitive) — `1` on the dimension side, `*` on the fact side.
   Filtering always flows from the `1` side to the `*` side.
2. **Arrowhead** — points toward the fact (the direction the filter flows).
3. **Sanity test** — "picking a dimension value narrows the transactions" should feel
   like the natural behavior.

---

## 4. Dimension-to-Dimension Relationships and Ambiguous Filter Paths

In a clean star, dimensions connect to the **fact**, not to each other. A
dimension-to-dimension relationship is a warning sign — often Power BI auto-detecting a
link from a shared column name.

### Why it's a problem: ambiguous filter paths
If a dimension can filter the fact through **two different routes** (e.g.
`dim_bank → fct` directly, *and* `dim_bank → dim_merchant → fct` indirectly), DAX has
more than one path to propagate a filter. This produces ambiguous or wrong results, and
Power BI may refuse to activate one path.

### Resolving it
If the dimension already connects to the fact directly, the dim-to-dim link adds an
ambiguous second path **without adding analytical capability** — every fact row already
knows its bank through the fact's own key. Remove the redundant path.

### Delete vs. Deactivate
- **Delete** — removes the relationship entirely. Cleanest when the path is never wanted.
- **Deactivate** — keeps it defined but dormant; advanced DAX can invoke it on demand via
  `USERELATIONSHIP()`. Useful for role-playing dimensions, not for simple redundancy.

### Where to fix it: model vs. source
Whether a foreign key *belongs* in a dimension (a source/dbt question) is separate from
whether the relationship should be **active in the Power BI model**. A redundant filter
path can be fixed cleanly in Power BI (delete the relationship) without rebuilding the
upstream warehouse model — a faster, reversible fix than changing dbt schema and tests.



## Session 14 — DAX Measures & Time Intelligence

### DAX evaluation context
- A measure aggregates under whatever filter context is active (slicer, visual row, card). Same measure, different value per context.
- Measures aggregating fact columns live on the fact table; measures counting a dimension live on that dimension.

### Core measure patterns
- Simple aggregation: SUM(table[column])
- Conditional count (COUNTIF equivalent): COUNTROWS(FILTER(table, condition))
- Safe ratio: DIVIDE(numerator, denominator) — returns BLANK on divide-by-zero
- DIVIDE third argument = alternate result when denominator is zero/blank

### Time intelligence
- PREVIOUSMONTH(dateColumn) returns a table of dates shifted back one month; it needs a real date column, not a month label.
- PREVIOUSMONTH cannot stand alone — wrap it in CALCULATE to modify the filter context of a measure.
- CALCULATE(expression, filter) evaluates the expression under a modified filter context.
- Time intelligence requires the date table to be marked "Mark as date table" on its date column.

### Guarding a percentage-change measure
- Percentage change (current − previous) / previous is only meaningful when the denominator is a positive baseline.
- A negative or near-zero denominator flips the sign and explodes the magnitude, producing meaningless figures.
- Guard with IF(previous > 0, DIVIDE(...), BLANK()). Use BLANK() in DAX, not NULL.

### dim_date year-month label
- A sortable year-month text label ("2023-08") belongs in dbt (property of a date, reusable across consumers), not in a single BI tool.
- "2023-08" sorts chronologically under alphabetical sort; "August 2023" does not.
- PostgreSQL: CONCAT(year, '-', LPAD(month::text, 2, '0')) — LPAD pads on the left; its pad argument must be a string ('0'), not an integer.

### Commands
- dbt run -s dim_date   (-s / --select runs only the named model)
- dbt test -s dim_date  (run tests for one model)
- cat ~/.dbt/profiles.yml  (profiles live in the home dir, not the project)


## Session 15 — Report Page Construction (Power BI)

### Match visual type to question shape
The core principle of the session. Every visual answers a *shape* of question:
- **Headline value → card.** A single number sized for a 5-second glance. Recognition, not reading.
- **Compare discrete categories → bar.** Bars share a common baseline, so the eye compares *length* — the one visual comparison humans do accurately. Reliable even for close values.
- **Change over an ordered sequence (time) → line.** A line connects consecutive points; the connection *is* the message. The eye follows slope (rising/falling/spiky) as a continuous trajectory. Time is continuous and ordered, so connecting matches the data's nature.

### Bar vs pie for composition
Both show parts of a whole, but humans read *length* well and *angle/area* poorly. Two close pie slices look identical; two close bars don't. Default to bars. Pie earns its place only for 2–3 slices where the message is "one dominates."

### Format on the measure, not the visual
Set number format (currency symbol, %, decimals) on the measure itself, in the Data pane / ribbon — not per-visual. The format then travels with the measure everywhere it appears. Define-once, authoritative — the DAX analogue of defining a metric once in dbt. Currency *symbol* must match the data's denomination (£, not the default $).

### Grouping by name can silently merge distinct entities
A visual groups by whatever field sits on its axis. Put a *name* on the axis and any rows sharing that name collapse into one — even when they're distinct keys. Always ask: **"does grouping by name hide something?"** Two shapes of this:
- Accidental collision — two unrelated entities happen to share a name (e.g. two "Ortega Inc" with different keys). Collapsing is always wrong.
- Legitimate variant — same entity split by an attribute (e.g. Visa Europe vs Visa Global). Collapsing is a *choice* that depends on the question (network-level vs region-split).
The robust fix is upstream: a unique display name in the dimension (dbt), not a per-report patch.

### Text YYYY-MM sorts chronologically because it's zero-padded
A `YYYY-MM` string column sorts alphabetically, and zero-padding makes alphabetical order equal chronological order ("2023-02" < "2023-11" < "2024-01"). Non-padded ("2024-3") or worded ("March 2024") formats break the time axis. The label-format choice in dbt is what makes the BI time axis sort correctly.

### Rate vs raw count answer different questions
Fraud *rate* (fraud ÷ transactions) = proportional risk — which segment is riskiest. Fraud *count* = absolute volume — where the most cases land. A high-volume segment can top the count while having a low rate. Choose per the question the page is asking.

### A uniform / flat chart is itself a finding
When a breakdown comes out near-uniform (e.g. fraud rate ~2% across every scheme), that *rules a factor out* — "this dimension doesn't discriminate risk; look elsewhere." Ruling something out is legitimate analytical output, not a failed visual.

### Top N filtering
A ranked "top 10" list is produced by a visual-level filter: Filter type → Top N → show top 10 by a chosen measure. The visual then auto-sorts descending on that ranking measure.