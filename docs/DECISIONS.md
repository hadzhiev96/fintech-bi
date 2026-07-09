# Architecture Decisions

Non-default choices in this project, and why. Obvious defaults aren't listed.

---

## Import mode over DirectQuery

Import trades freshness for full DAX support and speed; DirectQuery keeps
data live but restricts time-intelligence/CALCULATE patterns and is slower.
Data here is static synthetic data with a deliberate focus on the full DAX
surface (MTD/QTD/YoY) — Import had no downside.

*Would flip for:* genuine real-time needs, or data too large for memory.

---

## Surrogate keys for every join and grouping — never names

The generator independently produced two distinct merchants both named
"Ortega Inc." Any visual grouping by `merchant_name` silently merged their
revenue and fraud numbers into one row. The same bug shape hit
`dim_scheme`: 5 scheme keys, 3 distinct names — grouping by name collapsed
a 5-bar chart to 3.

**Fix, pushed upstream into dbt (not per-report):** a display-name column
on each dimension. Merchants (accidental collision) got the key appended
— `"Ortega Inc (47)"`. Schemes (a real business attribute doing the
colliding) got the attribute appended instead — `"Visa (Europe)"`.
Disambiguate with the attribute that explains the collision, when one
exists; fall back to the key when it's arbitrary.

---

## Row-level security: regional framing, not "CFO vs. merchant"

The initial brief called for "CFO view vs. merchant view" — doesn't map to
reality; processors don't give external merchants logins to internal
dashboards. Rebuilt as 6 static per-country roles on
`dim_merchant.merchant_country` (a Bulgaria manager sees only Bulgarian
merchants), matching how a multi-market processor actually operates. No
"sees everything" role exists — RLS only narrows, so an unassigned user
already sees everything by default.

**Static, not dynamic** (`USERNAME()` + mapping table): no real user
accounts exist behind a portfolio demo, so dynamic RLS buys nothing.
Static roles are fully testable locally via "View as roles."

**Verified** by predicting an order of magnitude first (Bulgaria = 12/100
merchants → ~12% of revenue expected), then confirming the actual number
and that the filter propagates to every page, not just one visual.

---

## Data-realism bug hunt: fraud loss magnitude

Monthly net revenue was going negative in some months (e.g. −£8,708 in
Aug 2023), with swings up to ±£49K month to month.

**Root cause:** interchange revenue ≈ 2% of a transaction; the original
fraud-loss draw was 50–100% of transaction value. One fraud case could
erase 25–50 clean transactions' worth of interchange — implausible at the
~2% fraud incidence rate generated.

**Fix:** loss draw rebounded to 5–20% of transaction amount.

| | Before | After |
|---|---|---|
| Negative months | Several | 0 (all 24 months) |
| Monthly revenue range | £15K–£40K, erratic | £69K–£87K, stable |
| Largest MoM swing | ~£49K | ~£13K |

Verified independently in DBeaver (SQL, not just the Power BI report).

**Same pass:** `card_status` moved from uniform random (~25% active) to
weighted (`[70,10,10,10]`) for a realistic ~70% active card base.

---

## Time intelligence: measure home table is cosmetic

All time-intelligence measures (`MTD_Revenue`, `QTD_Revenue`,
`PY_Revenue`, `YoY_Change%`, `MoMRevenue`) are homed on `dim_date`,
authored in Tabular Editor.

DAX resolves a measure by its globally-unique name, not by table — unlike
a column, which needs table-qualification because names repeat. So a
measure's home table is a purely organizational label; moving it never
changes what it computes. That's what made it safe to consolidate every
time-based measure onto one table for findability.

**Modeling nuance:** `TOTALMTD`/`TOTALQTD` accumulate from the start of a
period to the current point in context. At the period's own grain, a
to-date measure equals a plain sum — it only earns its place at a finer
grain (MTD by day, showing the within-month accumulation and reset).