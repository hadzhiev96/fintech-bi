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