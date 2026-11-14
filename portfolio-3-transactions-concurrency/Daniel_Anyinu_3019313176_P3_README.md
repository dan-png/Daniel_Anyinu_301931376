# Portfolio 3: Transactions and Concurrency — Commit and Rollback Exercise

Database setup matters because these statements modify live state in `super_mart_portfolio`. Run the entire sequence once in order and capture the terminal output in one screenshot. All results shown below are predictions until executed in PostgreSQL.

---

## 1. Starting-Data Check

This query checks the starting status of Order 2 (`Chidi Okafor`) and the current stock levels of `SM-MILK-400G` and `SM-RICE-5KG` before any transaction begins.

```sql
-- Step 1: Check starting state of Order 2 and products 1 and 2
SELECT
    o.order_id,
    o.order_status,
    o.closed_at,
    oi.order_item_id,
    p.product_id,
    p.sku_code,
    oi.quantity AS ordered_qty,
    p.stock_quantity AS shelf_stock
FROM public.orders o
JOIN public.order_items oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
WHERE o.order_id = 2
ORDER BY oi.order_item_id;

SELECT product_id, sku_code, product_name, stock_quantity
FROM public.products
WHERE product_id IN (1, 2)
ORDER BY product_id;
```

**Expected Result (Order 2 check):**

| order_id | order_status | closed_at | order_item_id | product_id | sku_code | ordered_qty | shelf_stock |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 2 | OPEN | | 3 | 1 | SM-MILK-400G | 3 | 40 |

**Expected Result (Products check):**

| product_id | sku_code | product_name | stock_quantity |
| :--- | :--- | :--- | :--- |
| 1 | SM-MILK-400G | Peak Milk 400g | 40 |
| 2 | SM-RICE-5KG | Mama Gold Rice 5kg | 15 |

---

## 2. Successful Transaction (`BEGIN`, Meaningful Update, `COMMIT`, and Repeat Check)

This transaction completes Order 2 (`'OPEN'` to `'COMPLETED'` at a fixed timestamp) and deducts its 3 ordered units of `SM-MILK-400G` from stock, using `WHERE order_status = 'OPEN'` so the checkout cannot be applied twice.

```sql
-- Step 2a: Complete Order 2 and deduct its 3 units of SM-MILK-400G atomically
BEGIN;

UPDATE public.products p
SET stock_quantity = p.stock_quantity - oi.quantity
FROM public.order_items oi
JOIN public.orders o ON oi.order_id = o.order_id
WHERE o.order_id = 2
  AND o.order_status = 'OPEN'
  AND p.product_id = oi.product_id
  AND p.stock_quantity >= oi.quantity;

UPDATE public.orders
SET order_status = 'COMPLETED',
    closed_at = TIMESTAMP '2026-10-02 14:40:00'
WHERE order_id = 2
  AND order_status = 'OPEN';

COMMIT;
```

**Expected Result:**
```text
BEGIN
UPDATE 1
UPDATE 1
COMMIT
```

This repeat check runs the exact same order-completion update outside a transaction to prove that the `WHERE order_status = 'OPEN'` guard prevents completing or deducting stock for Order 2 a second time.

```sql
-- Step 2b: Repeat check showing a completed order cannot be completed again
UPDATE public.orders
SET order_status = 'COMPLETED',
    closed_at = TIMESTAMP '2026-10-02 15:00:00'
WHERE order_id = 2
  AND order_status = 'OPEN';
```

**Expected Result:**
```text
UPDATE 0
```

---

## 3. Failed Transaction (`BEGIN`, Valid Change, Constraint Violation, and `ROLLBACK`)

This transaction first makes a valid restock update to `SM-RICE-5KG` (`stock_quantity` from `15` to `25`), then deliberately violates `products_stock_quantity_check` (`CHECK (stock_quantity >= 0)`) on `SM-MILK-400G`, and finally issues `ROLLBACK` to undo the entire transaction.

```sql
-- Step 3: Valid restock on product 2 followed by invalid negative stock on product 1
BEGIN;

-- Valid change inside the transaction (increases SM-RICE-5KG from 15 to 25)
UPDATE public.products
SET stock_quantity = stock_quantity + 10
WHERE product_id = 2;

-- Deliberate violation of CHECK (stock_quantity >= 0) on SM-MILK-400G (37 - 50 = -13)
UPDATE public.products
SET stock_quantity = stock_quantity - 50
WHERE product_id = 1;

-- Clear the aborted transaction state and undo the valid change to product 2
ROLLBACK;
```

**Expected Result:**
```text
BEGIN
UPDATE 1
ERROR:  new row for relation "products" violates check constraint "products_stock_quantity_check"
DETAIL:  Failing row contains (1, 1, SM-MILK-400G, Peak Milk 400g, 3500.00, -13).
ROLLBACK
```

---

## 4. Final Verification Queries

These queries confirm that the committed checkout from Step 2 remains saved (`Order 2` is `'COMPLETED'` and `SM-MILK-400G` stock is `37`), while the valid restock from the rolled-back transaction in Step 3 is gone (`SM-RICE-5KG` stock remains `15`).

```sql
-- Step 4: Verify committed changes remain and rolled-back changes are undone
SELECT order_id, order_status, closed_at
FROM public.orders
WHERE order_id = 2;

SELECT product_id, sku_code, product_name, stock_quantity
FROM public.products
WHERE product_id IN (1, 2)
ORDER BY product_id;
```

**Expected Result (Order 2 verification):**

| order_id | order_status | closed_at |
| :--- | :--- | :--- |
| 2 | COMPLETED | 2026-10-02 14:40:00 |

**Expected Result (Products verification):**

| product_id | sku_code | product_name | stock_quantity |
| :--- | :--- | :--- | :--- |
| 1 | SM-MILK-400G | Peak Milk 400g | 37 |
| 2 | SM-RICE-5KG | Mama Gold Rice 5kg | 15 |

# Portfolio 3 Transactions and Concurrency

## Commit and rollback
In `super_mart_portfolio`[cite: 2, 3, 4], the first transaction used `BEGIN` and `COMMIT` to complete Chidi Okafor's open order (`order_id = 2`, `closed_at = '2026-10-02 14:40:00'`) and deduct 3 ordered units of `SM-MILK-400G`, reducing its `stock_quantity` from `40` to `37`. A guard condition (`WHERE order_status = 'OPEN'`) prevented repeating the checkout (`UPDATE 0`). A second transaction increased `SM-RICE-5KG` stock from `15` to `25`, then attempted to subtract `50` units from `SM-MILK-400G`, triggering `products_stock_quantity_check` (`CHECK (stock_quantity >= 0)`). Issuing `ROLLBACK` cleared the aborted state and undid the restock on `SM-RICE-5KG` (`stock_quantity` remained `15`) while preserving the earlier committed changes on Order 2 and `SM-MILK-400G`.

## Isolation and concurrency control
Two independent PostgreSQL sessions running under `READ COMMITTED` isolation tested concurrent item additions to a new open order (`order_id = 4`) containing `SM-DIAP-XL`. After Session A inserted `SM-RICE-5KG` (`quantity = 1`) without committing, Session B's `SELECT` query saw only the committed `SM-DIAP-XL` row, preventing a dirty read. When Session B attempted to insert `SM-RICE-5KG` into the same order, PostgreSQL forced Session B to wait on the index lock for the composite unique constraint `order_items_order_id_product_id_key` (`UNIQUE (order_id, product_id)`). Once Session A ran `COMMIT`, Session B immediately failed with a duplicate key violation and ran `ROLLBACK`, leaving a single `SM-RICE-5KG` row on the order.

## Conclusion
PostgreSQL transactions, `CHECK` constraints, and unique index locks together protect Super Mart inventory and order integrity during failures and concurrent checkouts. While `READ COMMITTED` hides uncommitted changes, isolation alone does not prevent all conflicting operations without explicit table constraints, `WHERE` status guards, or row-level locks (`SELECT ... FOR UPDATE`) when multiple sessions deduct stock concurrently.

## Files

| File | Contents |
| :--- | :--- |
| [`Daniel_Anyinu_3019313176_P3_Transactions.sql`](Daniel_Anyinu_3019313176_P3_Transactions.sql) | Single-session `BEGIN`, `COMMIT`, repeat-guard check, constraint violation, and `ROLLBACK` SQL statements. |
| [`Daniel_Anyinu_3019313176_P3_Concurrency.sql`](Daniel_Anyinu_3019313176_P3_Concurrency.sql) | Two-session (`Session A` and `Session B`) `READ COMMITTED` isolation and unique constraint locking test. |
| [`screenshots/`](screenshots/) | Terminal screenshots showing the commit/rollback verification, Session B waiting state, and final concurrency outcome. |