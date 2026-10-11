# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet

[![MySQL Version](https://img.shields.io/badge/MySQL-8.0%2B-blue.svg)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()

> A production-grade relational database capstone project built phase-by-phase across the semester. AgriConnect powers a digital agricultural marketplace connecting smallholder Ugandan farmers with institutional and retail buyers, backed by an atomic mobile money escrow wallet.

---

## 1. The Business Problem & Solution

In rural Uganda, farmers lose 30–40% of their produce value to farm-gate middlemen, buyers struggle to find vetted suppliers, and conventional trade relies on unrecorded, risky cash payments. 

**AgriConnect** solves this with:
- A digital produce catalog across 6 agricultural commodity categories.
- An integrated digital wallet with double-entry immutable ledgers.
- An atomic 5-table checkout procedure with pessimistic concurrency locking.
- A 5% platform commission clearing model.
- Real-time logistics fulfillment and delivery tracking.
- Verified buyer review ratings.
- A semi-structured JSON product attribute catalog with virtual column indexing.
- A partitioned historical reporting engine.

---

## 2. Repository Architecture & File Index

| Deliverable File | Phase | Course Objective | Purpose & Description |
| :--- | :---: | :---: | :--- |
| [`schema.sql`](schema.sql) | Phase 3 | C1, C2 | Complete 9-table DDL schema with constraints, ENUMs, checks, & generated columns. |
| [`seed.sql`](seed.sql) | Phase 3 | C1, C2 | Realistic dataset: 17 Ugandan towns, 50 users, 50 wallets, 100 products, 30 orders, reviews, & ledger txns. |
| [`queries_basic.sql`](queries_basic.sql) | Phase 4 | C3 | 16 core business queries: INNER JOINs, anti-joins, aggregations, subqueries, & SLA metrics. |
| [`queries_advanced.sql`](queries_advanced.sql) | Phase 5 | C3 | Window functions (`ROW_NUMBER`, `RANK`, `LAG`), CTEs, running totals, and 4 admin views. |
| [`procedures.sql`](procedures.sql) | Phase 7 | C5 | 5-table ACID checkout procedure (`sp_place_order`), wallet deposit (`sp_cash_in`), & withdrawal (`sp_cash_out`). |
| [`concurrency_experiments.sql`](concurrency_experiments.sql) | Phase 8 | C5 | Concurrency lab scripts: lost update race condition, `FOR UPDATE` fix, deadlock (1213), & isolation levels. |
| [`indexing_optimization.sql`](indexing_optimization.sql) | Phase 9 | C6, C7 | Composite indexes, sort elimination, FULLTEXT search, and write-amplification benchmark. |
| [`partitioning.sql`](partitioning.sql) | Phase 10 | C6, C7 | Sargable query rewrites, RANGE partitioned `fact_order_lines`, ETL, pruning proof, & load generator. |
| [`replication_setup.sql`](replication_setup.sql) | Phase 11 | C8 | Primary-Replica distributed setup, replication user provisioning, binlogs, and read/write splitting. |
| [`nosql_json_catalog.sql`](nosql_json_catalog.sql) | Phase 12 | C9 | JSON attributes, path extraction (`->>`), generated virtual columns, & secondary indexing. |
| [`run_all.sql`](run_all.sql) | Master | All | End-to-end master runner executing the complete database build and health check. |

---

## 3. Academic Deliverables & Research Reports (`docs/`)

- [**Phase 0 Requirements Document**](docs/phase0_requirements.md): Business context, farmer interview summary, and the 10 refined business rules.
- [**Phase 1 ER Diagram & Modeling**](docs/phase1_erd.md): Conceptual entities, cardinality matrix, weak entity definitions, and complete Mermaid ER diagram.
- [**Phase 2 Relational Algebra Worksheet**](docs/phase2_relational_algebra.md): ER-to-relational mapping rules, formal relational algebra expressions (Q1–Q5), and verified SQL.
- [**Phase 6 Normalization Audit**](docs/phase6_normalization_audit.md): Anomalies in `bad_orders`, formal 1NF/2NF/3NF proofs with functional dependencies, and denormalization trade-offs.
- [**Phase 8 Concurrency Analysis**](docs/phase8_concurrency.md): Lost updates, race conditions, pessimistic lock serialization, InnoDB deadlock cycle graphs, and isolation levels.
- [**Phase 9 Optimization & EXPLAIN Report**](docs/phase9_optimization_report.md): Before-and-after `EXPLAIN` query plans, composite index left-to-right rules, and index write overhead benchmarking.
- [**Phase 11 Replication Design Doc**](docs/phase11_replication_design.md): Primary-Replica read/write split, replication lag, stale read tolerance matrix, and CAP theorem reasoning.
- [**Phase 12 NoSQL Extension Report**](docs/phase12_nosql_extension.md): Architectural justification for keeping transactional core relational while using JSON for product catalogs.
- [**Phase 13 Presentation & Defense Preparation**](docs/defense_preparation.md): Step-by-step 15-minute live demo walkthrough script and in-depth answers to all 6 defense questions.

---

## 4. Quickstart: Installation & Execution

### Prerequisites
- MySQL 8.0 or higher
- MySQL Workbench, DBeaver, or the standard MySQL CLI (`mysql`)

### One-Command Full Database Build
Execute [`run_all.sql`](run_all.sql) from the repository root:

```bash
mysql -u root -p < run_all.sql
```

Alternatively, from within the MySQL interactive shell:
```sql
SOURCE run_all.sql;
```

---

## 5. Live Demonstration Verification Commands

```sql
USE agriconnect;

-- 1. Inspect live catalog
SELECT * FROM v_catalog LIMIT 5;

-- 2. Test wallet cash-in (deposit 500,000 UGX)
CALL sp_cash_in(27, 500000.00);

-- 3. Execute successful atomic checkout (2 bunches of Mpologoma Matooke)
CALL sp_place_order(26, 21, 2.00, 'Plot 12, Ntinda Crescent, Kampala');

-- 4. Test failure rollback (huge quantity exceeds stock)
-- Will raise: "Error Code: 1644. Insufficient stock for requested quantity"
CALL sp_place_order(26, 21, 99999.00, 'Kampala');

-- 5. Verify query optimization on product search
EXPLAIN SELECT * FROM products WHERE category = 'FRUIT' AND unit_price <= 50000;

-- 6. Verify partition pruning on analytics table
EXPLAIN SELECT SUM(line_total) FROM fact_order_lines 
WHERE order_date >= '2025-01-01' AND order_date < '2025-02-01';
```
