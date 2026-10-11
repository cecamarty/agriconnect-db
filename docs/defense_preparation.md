# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 13: Project Defense Preparation & Presentation Demo Guide

---

### Part 1: Live Presentation Demo Walkthrough (15-Minute Rehearsal Script)

Follow these 7 sequential steps during the live defense demonstration to prove every required database capability:

#### Step 1: Initial State & Product Catalog Inspection
- **Action:** Open MySQL Workbench / CLI terminal and run:
  ```sql
  SELECT * FROM v_catalog LIMIT 5;
  ```
- **Speaking Point:** *"Here we observe our catalog view. Products are linked to verified farmers in districts like Mbale and Mbarara with real-time stock availability and active statuses."*

#### Step 2: Mobile Money Wallet Top-Up
- **Action:** Execute deposit procedure for Buyer 27:
  ```sql
  CALL sp_cash_in(27, 500000.00);
  ```
- **Speaking Point:** *"We demonstrate our digital wallet top-up. The transaction atomically increments the user's balance and writes an immutable double-entry `CASH_IN` ledger record."*

#### Step 3: Happy-Path Checkout Execution
- **Action:** Execute atomic checkout for Buyer 26 purchasing 2 units of Matooke (Product 21):
  ```sql
  CALL sp_place_order(26, 21, 2.00, 'Plot 12, Ntinda Crescent, Kampala');
  ```
- **Speaking Point:** *"Notice what just occurred in a single atomic transaction:
  1. Product inventory decreased by 2 units.
  2. Buyer wallet was debited by 56,000 UGX.
  3. The platform retained a 5% commission (2,800 UGX).
  4. The farmer was credited the remaining 95% (53,200 UGX).
  5. Two balancing ledger entries were logged in `wallet_txns`.
  6. A delivery tracking record was scheduled automatically."*

#### Step 4: Atomicity & Rollback Failure Proof
- **Action:** Attempt to purchase more stock than exists:
  ```sql
  CALL sp_place_order(26, 21, 99999.00, 'Kampala');
  ```
- **Speaking Point:** *"The stored procedure intercepts the stock deficit and raises custom SQLSTATE 45000: 'Insufficient stock'. Our `EXIT HANDLER` triggers an immediate `ROLLBACK`. If we inspect orders and wallet balances, zero rows have changed. All or nothing—strict Atomicity in action."*

#### Step 5: Concurrency & Race Condition Proof
- **Action:** Open two separate MySQL connection tabs. Execute `sp_place_order` simultaneously on a product with exactly 1 unit left.
- **Speaking Point:** *"Using `SELECT ... FOR UPDATE`, Session 1 locks the commodity row. Session 2 is serialized behind it. Once Session 1 commits, Session 2 sees stock = 0 and gracefully aborts. We completely eliminate the lost-update overselling anomaly without needing external application locks."*

#### Step 6: Query Plan Optimization Proof (EXPLAIN Side-by-Side)
- **Action:** Run `EXPLAIN` before and after index on product search:
  ```sql
  EXPLAIN SELECT * FROM products WHERE category = 'FRUIT' AND unit_price <= 50000;
  ```
- **Speaking Point:** *"Without an index, the optimizer executes a full table scan (`type: ALL`). With our composite index on `(category, unit_price)`, the optimizer executes a targeted B-tree `range` scan, dramatically reducing I/O and latency."*

#### Step 7: Historical Partition Pruning Proof
- **Action:** Run `EXPLAIN` on the range-partitioned analytics table:
  ```sql
  EXPLAIN SELECT SUM(line_total) FROM fact_order_lines 
  WHERE order_date >= '2025-01-01' AND order_date < '2025-02-01';
  ```
- **Speaking Point:** *"Notice the `partitions` column: MySQL scans only partition `p2025` and completely bypasses `p2023`, `p2024`, and `pmax`. This partition pruning delivers near-instant analytics even over hundreds of thousands of historical rows."*

---

### Part 2: Comprehensive Answers to Defense Examination Questions

---

#### Question 1: Why is `order_items.unit_price` frozen instead of joined dynamically from `products`?
**Comprehensive Answer:**
"If we did not store `unit_price` in `order_items` and instead relied on joining `products.unit_price` dynamically, whenever a farmer adjusted their produce price (for example, raising Matooke from 25,000 UGX to 35,000 UGX due to seasonal inflation), the historical totals of all past completed orders would retroactively change! This would corrupt past accounting ledgers, invalidate tax records, and cause financial audits to fail. 
Storing `unit_price` in `order_items` at the moment of order placement captures an **immutable historical price snapshot** (Point-in-Time value). The generated column `line_total = qty * unit_price` guarantees mathematical consistency over time."

---

#### Question 2: Which ACID property does `SIGNAL` + `DECLARE EXIT HANDLER` implement, and how?
**Comprehensive Answer:**
"`SIGNAL` and `DECLARE EXIT HANDLER FOR SQLEXCEPTION` primarily implement **Atomicity** (and secondarily **Consistency**).
- **Atomicity:** In MySQL InnoDB, if a runtime failure occurs (such as insufficient wallet balance, stock shortages, or foreign key violations), the `EXIT HANDLER` intercepts the exception and executes an explicit `ROLLBACK`. This ensures that partial operations (e.g., an order created but wallet debit failing) are never left half-committed.
- **Consistency:** By raising a `SIGNAL SQLSTATE '45000'` when business invariants are violated (e.g., `balance < total` or `stock < qty`), the procedure enforces application-level consistency rules before any invalid state can be written to disk, keeping the database in a mathematically valid state across transactions."

---

#### Question 3: Your indexes speed up reads. What do they cost? When would you remove one?
**Comprehensive Answer:**
"Indexes trade write performance and disk storage for read speed:
1. **Write Amplification Penalty:** Every `INSERT`, `UPDATE`, and `DELETE` on a table requires the storage engine to update not only the clustered primary key index but also every secondary B-tree or fulltext index structure. As shown in our empirical benchmark (`benchmark_insert_cost`), maintaining 3 secondary indexes increased insert latency by over 150%.
2. **Buffer Pool Cache Contention:** Index pages consume precious RAM inside InnoDB's buffer pool, potentially evicting active data pages.
3. **When to Remove an Index:**
   - When an index has **low cardinality** (e.g., a boolean or status flag with few distinct values where the query optimizer prefers a full table scan anyway).
   - When index monitoring queries (`sys.schema_unused_indexes`) show that an index has had **zero read lookups** over an extended operational period.
   - On **write-heavy staging or logging tables** where write latency is critical and read queries are infrequent."

---

#### Question 4: Why can't the operational `orders` table be partitioned directly?
**Comprehensive Answer:**
"MySQL InnoDB imposes a fundamental architectural constraint on partitioned tables: **Every Unique Key and Primary Key on the table must contain every column used in the table's partitioning expression**.
If we partitioned `orders` by `RANGE (YEAR(order_date))`, the Primary Key would have to become the composite `(order_id, order_date)`. 
However, child tables in our normalized 3NF transactional core (such as `order_items` and `deliveries`) reference `orders(order_id)` as a single-column Foreign Key. MySQL does not permit foreign key references to composite keys using only a partial prefix. 
Furthermore, **MySQL partitioned tables do not support Foreign Key constraints pointing to foreign tables**. If we partitioned `orders` directly, we would be forced to drop the foreign key reference to `users(buyer_id)` and the referential integrity protecting `order_items` and `deliveries`. 
Therefore, the correct architectural design is to keep the operational `orders` table normalized and foreign-key protected, and extract history into the partitioned denormalized analytics table `fact_order_lines`."

---

#### Question 5: If 10,000 buyers order simultaneously, what fails first and how would replication/sharding help?
**Comprehensive Answer:**
"Under a sudden surge of 10,000 simultaneous order checkouts:
1. **What Fails First:**
   - **Row-Level Lock Contention:** If many buyers are competing for hot inventory items (e.g., high-demand Matooke or Kaiso Rice), transactions queue up behind the exclusive row lock (`FOR UPDATE`). When lock waits exceed `innodb_lock_wait_timeout` (default 50 seconds), transactions fail with Lock Wait Timeout errors.
   - **Connection Pool Exhaustion:** MySQL's `max_connections` (default 151) is instantly overwhelmed, causing the database to reject new TCP connections with `'Too many connections'`.
   - **Disk I/O Bottleneck:** Thousands of concurrent transaction commits saturate the write capacity of the redo log (`ib_logfile0`) and storage IOPS.
2. **How Replication and Sharding Resolve This:**
   - **Read-Write Replication:** Does *not* help with write checkout volume, but offloads all catalog browsing, search queries, and analytics to multiple Read Replicas, freeing up 100% of the Primary server's CPU, buffer pool, and IOPS exclusively for checkout transactions.
   - **Horizontal Sharding (Application-Level Partitioning):** Divides the transactional data across multiple independent database nodes. For example, sharding by `farmer_id` or geographical `district` (e.g., Eastern Uganda shard vs Western Uganda shard) splits the locking queues and write traffic so that transactions for Mbale produce never contend for locks with transactions for Mbarara produce."

---

#### Question 6: Why did you keep the core relational and only the catalog semi-structured?
**Comprehensive Answer:**
"This represents a deliberate **Polyglot Hybrid Architecture**:
- **Why Core Relational:** The financial and transactional core (wallets, double-entry ledger logs, orders, line items, deliveries) represents a strict system of record. It requires ACID transactional atomicity, declarative `CHECK` constraints (e.g., wallet balance never negative), and strict Foreign Key cascades that guarantee zero orphaned records.
- **Why Catalog Semi-Structured (JSON):** Agricultural produce is fundamentally polymorphic: grains require moisture content and bag size; cattle require breed, live weight, and ear tag numbers; milk requires cold chain status and expiry days; coffee requires cupping scores and elevation. Modeling this in relational columns would result in an anti-pattern of 40+ sparse nullable columns or complex EAV tables. 
By utilizing MySQL native `JSON` columns with **Virtual Generated Columns and Secondary B-Tree Indexes**, we achieve the schema flexibility of a NoSQL document database while retaining full ACID relational integrity across the transactional core."
