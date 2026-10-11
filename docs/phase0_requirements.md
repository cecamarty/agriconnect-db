# AgriConnect: Farm-to-Market Platform with Mobile Money Wallet
## Phase 0: System Requirements Specification & Business Problem

---

### 1. Executive Summary & The Problem Domain

In rural Uganda, smallholder farmers face severe structural market inefficiencies:
- **Value Loss:** Farmers lose between 30% and 40% of their produce value because they sell to exploitative intermediary brokers ("middlemen") directly at the farm gate.
- **Information Asymmetry:** A matooke farmer in Mbale or Mbarara lacks real-time visibility into prevailing wholesale prices in Kampala or Entebbe.
- **Supplier Reliability & Counterparty Risk:** Commercial buyers (urban hotels, restaurants, supermarkets) struggle to locate vetted suppliers, and conventional trade relies heavily on unrecorded cash payments with zero legal or financial traceability.

### 2. The Solution Architecture

**AgriConnect** is an integrated digital marketplace and transactional clearing system. It connects farmers with retail and institutional buyers across Uganda, backed by a simulated mobile money escrow wallet (modeled after MTN Mobile Money and Airtel Money). The platform enforces a 5% commission on all completed transactions, provides real-time logistics fulfillment tracking, and maintains a strict double-entry ledger.

---

### 3. The 10 Core Business Rules (Refined Requirements)

1. **User Identity & Roles:**
   A user is registered with a unique Ugandan telephone number formatted under E.164 (`256XXXXXXXXX`). Users can act as **FARMER**, **BUYER**, or **BOTH** (dual-role actor, e.g., an agro-dealer who buys inputs and sells crops).

2. **Strict Wallet Invariant:**
   Every registered user has exactly one digital wallet created upon registration (1:1 strict cardinality). The wallet balance can **never fall below zero** (`balance >= 0`). Credit overdrafts are prohibited at the database constraint level.

3. **Immutable Financial Audit Log:**
   All monetary transactions (`CASH_IN`, `CASH_OUT`, `PAYMENT`, `RECEIPT`) must be permanently and immutably recorded in a transaction ledger (`wallet_txns`). No transaction log row may ever be modified or deleted.

4. **Frozen Purchase Price:**
   An order may consist of multiple line items. The unit price recorded on each order item is **permanently frozen at the moment of order placement**. Subsequent price updates by the farmer to the product catalog must never alter historical order lines.

5. **Pessimistic Inventory Allocation:**
   The system must never allow overselling or negative inventory stock, even if multiple buyers concurrently attempt to purchase the final bag of produce in the same millisecond.

6. **Atomicity of Checkout:**
   Checkout is strictly atomic. Buyer wallet debit, farmer net wallet credit (after commission), platform commission deduction, stock reduction, order item logging, and delivery initialization must all succeed together or roll back completely with zero state changes.

7. **Platform Commission:**
   The platform retains an automatic **5% commission** on every fulfilled order line, crediting the seller 95% of the gross sale amount.

8. **Verified Buyer Reviews:**
   Buyers may rate products on a scale of **1 to 5 stars** with an optional textual comment. Reviews are restricted to products the buyer has actually purchased, and only one review per buyer per product is allowed.

9. **Polymorphic Product Attributes (Semi-Structured Catalog):**
   Product attributes vary significantly across commodity types (e.g., grain specifies moisture content and variety; livestock specifies breed and weight; dairy specifies cold-chain and expiry). The schema must flex without requiring continuous structural DDL migrations or dozens of sparse nullable columns.

10. **Administrative Analytics & Reporting:**
    The system must generate operational and executive reports: monthly sales GMV, farmer earnings leaderboards, regional trade volume, delivery SLA adherence, and customer lifetime value.

---

### 4. Stakeholder Role-Play Interview Summary

- **Interviewee:** Mr. Okello John Peter, Matooke & Groundnuts Farmer, Mbale District.
- **Key Insight:** *"Middlemen arrive at my farm offering cash, but they pay less than half of what Nakasero Market charges. I need immediate notification on my phone when an order is placed, and guaranteed payment into my mobile money wallet before I release the bunch to the truck driver."*
- **Technical Implication:** Requires pessimistic row-locking on inventory and atomic escrow settlement so that money is transferred simultaneously with order confirmation.
