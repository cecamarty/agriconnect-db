# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 6: Normalization Audit & Justified Denormalization Analysis

---

### 1. The Naive Denormalized Anti-Pattern: `bad_orders`

Consider the single monolithic table design proposed by an inexperienced teammate:

```sql
CREATE TABLE bad_orders (
    order_id INT, 
    buyer_name VARCHAR(100), 
    buyer_phone VARCHAR(13),
    farmer_name VARCHAR(100), 
    product_name VARCHAR(100), 
    category VARCHAR(20),
    unit_price DECIMAL(10,2), 
    qty DECIMAL(10,2), 
    town VARCHAR(60)
);
```

While superficially simple, this flat relation violates fundamental normalization principles and exhibits catastrophic data anomalies in a production environment:

#### A. Modification / Update Anomaly
- **The Issue:** Farmer and buyer attributes (such as names, phone numbers, and town locations) are replicated across every single order row in which they participate.
- **Consequence:** If Farmer Okello changes his telephone number from `256772100002` to a new line, the database must execute an update across hundreds or thousands of historical rows. If any row is missed due to a system interruption or partial write, the database enters an inconsistent state where the same farmer has multiple conflicting contact numbers.

#### B. Insertion Anomaly
- **The Issue:** The candidate primary key for `bad_orders` must include the transaction identifier (`order_id`).
- **Consequence:** A newly registered farmer who lists a fresh crop of *Mpologoma Matooke* cannot have their produce recorded in the database until an order is placed by a buyer! You cannot insert a product without creating an artificial or `NULL`-filled `order_id`, which violates Entity Integrity.

#### C. Deletion Anomaly
- **The Issue:** The entity life cycles of buyers, farmers, catalog products, and orders are artificially coupled together.
- **Consequence:** If a buyer cancels their order, or if an administrator purges a test transaction that happens to be the only order for an exotic product (e.g., *Bourbon Vanilla Beans*), deleting that single row completely erases the product and the farmer's listing from the system entirely.

---

### 2. Rigorous 3NF Normalization Proof of Phase 3 Schema

The production schema defined in `schema.sql` eliminates all three anomalies by decomposing the schema into Third Normal Form (3NF).

#### Step 1: First Normal Form (1NF) Compliance
- **Rule:** All attribute values must be atomic (no repeating groups, comma-separated lists, or arrays). Every row must have a unique identifier.
- **Proof:** Every table has an explicit Primary Key (`user_id`, `product_id`, `order_id`, etc.). Attributes contain strictly atomic scalar types (`VARCHAR`, `INT`, `DECIMAL`). The multi-item order relationship is decoupled into individual scalar rows within `order_items`.

#### Step 2: Second Normal Form (2NF) Compliance
- **Rule:** The relation must be in 1NF, and **no non-prime attribute may be partially functionally dependent on any candidate key**.
- **Proof:** In `order_items`, the candidate key is `(order_id, product_id)`. Non-key attributes like `qty` and `unit_price` depend upon the *entire* combination of the order and the product line. Product master data (`category`, `farmer_id`) does not belong in `order_items` because it depends solely on `product_id`; thus, it is properly isolated in `products`. Hence, zero partial key dependencies exist.

#### Step 3: Third Normal Form (3NF) Compliance
- **Rule:** The relation must be in 2NF, and **no non-prime attribute may be transitively dependent on the primary key** (i.e., for every non-trivial functional dependency $X \rightarrow Y$, $X$ is a superkey or $Y$ is a prime attribute).
- **Proof of Functional Dependencies (FDs):**
  - $\text{users}: \quad user\_id \rightarrow full\_name, phone, role, town\_id$
  - $\text{towns}: \quad town\_id \rightarrow town\_name, district$
  - If `town_name` and `district` were embedded inside `users`, we would have the transitive dependency $user\_id \rightarrow town\_id \rightarrow (town\_name, district)$. By decomposing `towns` into a distinct relation, this transitive dependency is eliminated.
  - $\text{products}: \quad product\_id \rightarrow farmer\_id, product\_name, category, unit, unit_price$
  - $\text{orders}: \quad order\_id \rightarrow buyer\_id, order\_date, status, total\_amount$
  - In all relations, every determinant is a candidate key. Therefore, the schema is strictly in **3NF**.

---

### 3. Justified Denormalization Analysis: `fact_order_lines`

In Phase 10, AgriConnect introduces a specialized analytics table: `fact_order_lines`. This table intentionally duplicates `category`, `unit_price`, and `line_total` alongside historical dimensional identifiers.

#### Architectural Trade-off Paragraph:
While normalized 3NF schemas represent the optimal architecture for online transaction processing (OLTP)—guaranteeing strict ACID integrity, locking efficiency, and eliminating update anomalies—they incur severe performance penalties on high-throughput analytical workloads (OLAP). Calculating yearly sales aggregations across millions of orders in 3NF requires complex 4-table joins (`orders` $\bowtie$ `order_items` $\bowtie$ `products` $\bowtie$ `users`). 

Denormalizing order lines into `fact_order_lines` trades away disk storage redundancy to gain dramatic read query acceleration (often 10x–50x speedups). Furthermore, because MySQL InnoDB enforces that the partitioning key of a partitioned table must be part of its Primary Key and cannot maintain traditional Foreign Key constraints, maintaining this denormalized table as an asynchronous reporting copy allows AgriConnect to partition large historical datasets across calendar years (`PARTITION BY RANGE (YEAR(order_date))`) without sacrificing the strict referential constraints governing the live transactional OLTP tables.
