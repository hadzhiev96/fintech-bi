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