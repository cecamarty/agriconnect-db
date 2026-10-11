# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 11: Distributed Replication Design & Consistency Analysis

---

### 1. Architectural Topology: Primary-Replica Scale-Out

As AgriConnect expands across Uganda, read query volume (catalog browsing, administrative reports, inventory search) rapidly outpaces write mutations (order checkout, wallet deposits).

```
                 [ Web / Mobile Clients ]
                            |
                     (Reverse Proxy)
                     /             \
        [Writes & Checkout]    [Reads & Analytics]
                   /                 \
                  v                   v
          +---------------+   Async   +---------------+
          |  PRIMARY (W)  | --------> |  REPLICA (R)  |
          |   Port 3306   | Replication|   Port 3307   |
          +---------------+           +---------------+
```

- **Primary Instance (Port 3306):** Handles all mutating DML (`INSERT`, `UPDATE`, `DELETE`) and critical transactional checkout procedures (`sp_place_order`, `sp_cash_in`).
- **Replica Instance (Port 3307):** Configured with `read_only = 1`. Offloads intensive analytical reporting queries (`v_farmer_earnings`, `queries_advanced.sql`, search filters).

---

### 2. Asynchronous Replication & Stale Read Risks

Standard MySQL replication is asynchronous:
1. Primary commits a transaction to its local InnoDB storage engine and writes the events to its Binary Log (`log_bin`).
2. Primary immediately returns success to the client without waiting for acknowledgement from replicas.
3. The Replica's **I/O Thread** reads the binlog over the network and writes it to a local Relay Log.
4. The Replica's **SQL Thread** sequentially applies relay log events to the replica's local tables.

#### The Replication Lag Window:
If network latency spikes or the replica is executing an intensive analytics query, the parameter `Seconds_Behind_Source` increases. During this lag window, reading from the replica yields **stale reads** (unreplicated past state).

---

### 3. Stale Read Tolerance Classification Matrix

| Workflow / Report | Query Target | Can it tolerate Stale Reads? | Consequence of Inconsistency | Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| **Buyer Checkout** | `products.stock_qty`, `wallets.balance` | **NO (Zero Tolerance)** | Overselling stock or double-spending money. | **Route strictly to PRIMARY** with `FOR UPDATE`. |
| **Immediate Post-Order Screen** | "Order Placed! Order ID #X" | **NO (Read-Your-Own-Writes)** | Buyer sees blank order list right after payment, panics, and calls support. | Read from Primary or leverage pinning session cookies for 5 seconds. |
| **Public Produce Catalog** | `v_catalog`, search by category | **YES (High Tolerance)** | Buyer sees a product that was sold out 2 seconds ago; inventory check catches it at checkout anyway. | Route to **REPLICA**. |
| **Monthly Executive Sales Report** | `v_monthly_financial_summary` | **YES (Complete Tolerance)** | Financial metrics aggregated across historical months do not change minute-by-minute. | Route to **REPLICA**. |
| **Farmer Earnings Leaderboard** | `v_farmer_earnings` | **YES (Moderate Tolerance)** | A 5-second lag in rank calculation does not cause operational damage. | Route to **REPLICA**. |

---

### 4. Distributed Systems Reasoning: The CAP Theorem

According to Eric Brewer's **CAP Theorem**, a distributed data store can guarantee at most two out of three guarantees in the event of a Network Partition (**P**):
1. **Consistency (C):** Every read receives the most recent write or an error.
2. **Availability (A):** Every non-failing node returns a non-error response for every request (without guaranteeing latest data).
3. **Partition Tolerance (P):** The system continues to operate despite arbitrary dropped or delayed network packets.

#### Application to AgriConnect:

- **The Asynchronous Read Replica is an AP Choice:**
  If a network partition disconnects Kampala (Primary) from an agricultural hub replica in Gulu, the Gulu replica continues serving read traffic to local buyers and farmers (preserving **Availability**), but returns data that may lag behind Kampala's latest writes (sacrificing strict **Consistency**).
  
- **The Financial Core is a CP Choice:**
  For wallet money movement and stock deduction, AgriConnect refuses to sacrifice Consistency. If network isolation prevents a node from guaranteeing atomic agreement on wallet balances, transactions must be blocked or aborted to prevent financial fraud.
  
- **Conclusion:** AgriConnect utilizes a **hybrid consistency tier**: Strong Serialized Consistency (**CP**) for the double-entry financial core, and Eventual Consistency (**AP**) for public produce discovery and historical analytics.
