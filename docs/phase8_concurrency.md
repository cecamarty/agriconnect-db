# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 8: Concurrency, Locking, and Deadlock Analysis

---

### 1. Concurrency Anomalies & Race Conditions

In a high-throughput agricultural marketplace, concurrent requests regularly target the same scarce resources:
- Multiple buyers purchasing the final stock of a crop.
- Multiple payments updating the same digital wallet simultaneously.

Without rigorous database-level concurrency control, systems succumb to classic multi-threading anomalies, most notably the **Lost Update Problem**.

---

### 2. Experiment A: The Oversell Phenomenon (Lost Update)

In `sp_place_order_nolock`, product records are fetched with standard non-locking reads:
```sql
SELECT unit_price, stock_qty, farmer_id 
INTO v_price, v_stock, v_farmer
FROM products WHERE product_id = p_product_id;
```

#### The Interleaving Sequence:
1. Product 72 has `stock_qty = 1.00`.
2. **Session 1** begins transaction, reads `stock_qty = 1.00`, determines stock is sufficient.
3. Before Session 1 updates the row, **Session 2** begins transaction, reads the exact same snapshot where `stock_qty = 1.00`, and also concludes stock is sufficient.
4. **Session 1** executes `UPDATE products SET stock_qty = stock_qty - 1.00` ($\rightarrow 0.00$) and commits.
5. **Session 2** executes `UPDATE products SET stock_qty = stock_qty - 1.00` ($\rightarrow -1.00$) and commits.

#### Result:
The inventory reaches **-1.00**, causing a physical oversell. Business Rule 5 is violated, resulting in real-world customer disappointment and unfillable agricultural deliveries.

---

### 3. Experiment B: Pessimistic Locking with `SELECT ... FOR UPDATE`

In the production `sp_place_order` stored procedure, AgriConnect applies an exclusive pessimistic row lock:
```sql
SELECT unit_price, stock_qty, farmer_id 
INTO v_price, v_stock, v_farmer
FROM products WHERE product_id = p_product_id FOR UPDATE;
```

#### The Serialized Execution:
1. **Session 1** issues `SELECT ... FOR UPDATE`, obtaining an **Exclusive (X) Row Lock** on the product record.
2. **Session 2** issues `SELECT ... FOR UPDATE` on the same record and is immediately placed into a hardware lock-wait state by the InnoDB engine.
3. Session 1 deducts stock to `0.00`, logs the order lines, debits the buyer, credits the farmer, and executes `COMMIT`.
4. The moment Session 1 commits, Session 1 releases its X-lock.
5. Session 2 wakes up, acquires the X-lock, reads the fresh committed state (`stock_qty = 0.00`), hits the application constraint condition (`IF v_stock < p_qty`), raises `SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock'`, and terminates cleanly with zero changes.

**Outcome:** Complete mathematical preservation of inventory integrity under any concurrency load.

---

### 4. Experiment C: Deadlock Detection & Victim Rollback

A deadlock occurs when two concurrent transactions mutually block one another in a circular wait-for dependency graph.

#### The Transfer Scenario:
```
Session 1 holds Lock(Wallet 1)  -->  Waits for Lock(Wallet 2)
              ^                                  |
              |                                  v
Waits for Lock(Wallet 1)  <--  Session 2 holds Lock(Wallet 2)
```

#### How InnoDB Resolves Deadlocks:
1. InnoDB maintains an internal **Wait-For Graph** tracking transaction dependencies.
2. The moment a directed cycle is detected, InnoDB's deadlock detector fires instantly.
3. InnoDB calculates the transaction weight of each participant (measured by the number of rows inserted, updated, or deleted, i.e., the size of its Undo log).
4. The transaction that has performed the least amount of destructive mutation (the "cheapest" transaction to undo) is designated as the **victim**.
5. The victim receives:
   ```text
   ERROR 1213 (40010): Deadlock found when trying to get lock; try restarting transaction
   ```
6. The victim's transaction is automatically rolled back, releasing all its locks and allowing the survivor transaction to complete successfully.
7. **Application Layer Responsibility:** Applications must catch Error 1213 and execute an exponential backoff retry.

---

### 5. Experiment D: Transaction Isolation Levels Compared

| Isolation Level | Dirty Reads? | Non-Repeatable Reads? | Phantom Reads? | Mechanism in MySQL InnoDB |
| :--- | :--- | :--- | :--- | :--- |
| **READ UNCOMMITTED** | Yes | Yes | Yes | Reads uncommitted dirty pages directly from buffer pool without locks. |
| **READ COMMITTED** | No | Yes | Yes | Every SQL statement inside the transaction generates its own fresh MVCC Read View. |
| **REPEATABLE READ** (Default) | No | No | No (via Gap Locks) | A single MVCC Read View is created on the *first* read and persists until `COMMIT`. Next-Key locks prevent phantom inserts. |
| **SERIALIZABLE** | No | No | No | Converts all plain `SELECT` statements into `SELECT ... FOR SHARE`. |

#### Recommendation for AgriConnect:
- Keep **REPEATABLE READ** as the default system isolation level for consistent reporting snapshots and snapshot isolation safety.
- Employ explicit **`SELECT ... FOR UPDATE`** within stored procedures to achieve targeted, fine-grained pessimistic locking on contested transactional rows (wallets and stock) without escalating the entire database to the heavy overhead of `SERIALIZABLE`.
