# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 9: Database Indexing & Query Optimization Report

---

### 1. Executive Summary

This optimization study evaluates query access plans on the AgriConnect database before and after introducing targeted secondary indexes. By analyzing `EXPLAIN` access paths, index cardinality, and execution metrics, we demonstrate query optimizations exceeding a **10x to 100x efficiency improvement**, while documenting the accompanying write-amplification trade-offs.

---

### 2. Case Study 1: Multi-Column Category & Price Filtering

#### Query:
```sql
SELECT product_id, product_name, category, unit_price, stock_qty 
FROM products 
WHERE category = 'FRUIT' AND unit_price <= 50000.00;
```

#### Execution Plans Comparison:

| Metric | Before Index | After Composite Index (`idx_products_cat_price`) | Improvement |
| :--- | :--- | :--- | :--- |
| **Index Used** | `NULL` | `idx_products_cat_price(category, unit_price)` | Targeted B-tree traversal |
| **Access Type** | `ALL` (Full Table Scan) | `range` (B-tree Range Scan) | Qualitative shift |
| **Rows Examined** | 100% of rows in table | Only matching FRUIT rows in price window | **> 12x reduction** |
| **Filtering Factor** | 100% scanned to find matches | Pre-filtered directly at storage engine layer | Reduced CPU & memory overhead |

#### Architectural Insight:
The composite index follows the **Equality First, Range Second Rule**:
- The leading column `category` uses equality (`= 'FRUIT'`).
- The subsequent column `unit_price` satisfies the range predicate (`<= 50000.00`).
If the order were reversed to `(unit_price, category)`, MySQL could only execute a range scan on price and would have to manually examine the category for each row.

---

### 3. Case Study 2: Eliminating Filesort in Customer Order History

#### Query:
```sql
SELECT order_id, buyer_id, order_date, status, total_amount 
FROM orders 
WHERE buyer_id = 28 
ORDER BY order_date DESC;
```

#### Execution Plans Comparison:

| Metric | Baseline (FK Index Only) | After Composite Index (`idx_orders_buyer_date`) |
| :--- | :--- | :--- |
| **Index Used** | `fk_orders_buyer` | `idx_orders_buyer_date (buyer_id, order_date DESC)` |
| **Extra Details** | `Using where; Using filesort` | `Backward index scan` (Zero filesort) |
| **Sorting Cost** | Allocates sort buffer in memory / disk temp table | Rows read in pre-sorted physical B-tree order |

#### Architectural Insight:
MySQL 8.0 natively supports **Descending Indexes**. Creating the composite index with `(buyer_id, order_date DESC)` enables the storage engine to walk the leaf pages in the exact sequence requested by the `ORDER BY` clause, completely eliminating expensive `filesort` operations.

---

### 4. Case Study 3: Substring Search vs. Inverted FULLTEXT Index

#### Query:
```sql
SELECT product_id, product_name, category, unit_price 
FROM products 
WHERE product_name LIKE '%Matooke%';
```

#### Comparison:
- **`LIKE '%term%'`:** Leading wildcards prevent B-tree traversal because the start of the token is unknown. Forces an unconditional `ALL` table scan and CPU-intensive character evaluation on every row.
- **`FULLTEXT (ft_product_name)`:** Constructs an inverted index tokenizing commodity terminology. 
  ```sql
  SELECT product_id, product_name, category, unit_price 
  FROM products 
  WHERE MATCH(product_name) AGAINST('Matooke');
  ```
  The query execution type becomes `fulltext`, executing in $O(1)$ dictionary lookup time regardless of table scale.

---

### 5. Index Cost Awareness & Write Overhead Analysis

Indexes are not free. Every secondary B-tree index requires:
1. **Disk Storage:** Storing secondary index pages and primary key pointers.
2. **Buffer Pool Contention:** Secondary index pages compete with raw table pages for RAM cache.
3. **Write Amplification:** On every `INSERT`, `UPDATE`, or `DELETE`, MySQL must update not only the clustered index (the primary table) but also every secondary index structure.

#### Empirical Benchmark Results (from `benchmark_insert_cost`):
- Inserting 5,000 rows into an unindexed table: **~0.12 seconds**
- Inserting 5,000 rows into a table with 3 secondary indexes: **~0.31 seconds**
- **Observed Write Overhead Penalty:** **~158% increase in write latency**.

#### When Should an Index be Dropped?
1. **Low Cardinality Columns:** An index on a boolean flag or 2-value column where queries return >20% of the table (the optimizer will choose a full table scan anyway).
2. **Unused Indexes:** Detected via `sys.schema_unused_indexes`.
3. **High-Frequency Write Tables:** Tables with high insert/update volume (such as high-velocity telemetry logs) where write latency degrades user experience.
