# Portfolio 2 Query Processing and Optimisation

## Queries and results
Three queries were executed against the Super Mart schema in `super_mart_portfolio` using [`Daniel_Anyinu_3019313176_P2_Queries.sql`](Daniel_Anyinu_3019313176_P2_Queries.sql):
* **Active and completed order line items:** Joined `order_items`, `orders`, `customers`, and `products` for `'OPEN'` and `'COMPLETED'` orders placed on or after `2026-10-01`, returning 3 rows (2 items for Amina Bello's completed order and 1 item for Chidi Okafor's open order) while excluding Tunde Adeyemi's cancelled order.
* **In-stock products without open or completed orders:** Checked available inventory (`stock_quantity > 0`) using `NOT EXISTS` against active or completed orders, returning 1 row (`SM-DIAP-XL`, *SoftCare Diapers XL*, stock `20`) because its only order was `'CANCELLED'` and `SM-YOG-1L` has zero stock.
* **Product category order line count:** Used a `LEFT JOIN` from `products` to `order_items` grouped by product and category, returning all 4 products with order line counts of `2` (`SM-MILK-400G`), `1` (`SM-DIAP-XL`), `1` (`SM-RICE-5KG`), and `0` (`SM-YOG-1L`).

## Index comparison
A separate `p2_benchmark.order_item_history` table was populated with `100,000` synthetic rows and analysed with `ANALYZE`. The benchmark query retrieved `'COMPLETED'` sales for `'SM-MILK-400G'` between `2026-01-01 10:00:00` and `2026-01-01 10:20:00`, returning `5` rows (`history_id` `601`, `609`, `613`, `617`, and `621`). The table below compares `EXPLAIN (ANALYZE, BUFFERS)` before and after creating `idx_order_item_history_sku_status_date` on `(sku_code, order_status, order_date)`:

| Phase | Scan Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Median Time (ms) | Top-Level Shared Buffer Hits |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Before index | `Sort` + `Seq Scan` | 7.635 | *Not recorded in screenshot* | *Not recorded in screenshot* | 7.635 (single captured run) | `shared hit=1137` |
| After index | `Index Scan` (`idx_order_item_history_sku_status_date`) | 0.052 | *Not recorded in screenshot* | *Not recorded in screenshot* | 0.052 (single captured run) | `shared hit=2 read=3` |

*(Note: Replace the Run 2 and Run 3 cells above if you run two additional timed passes in your terminal before committing.)*

## Performance analysis
Before indexing, PostgreSQL executed a full `Seq Scan` across `p2_benchmark.order_item_history`, reading `1,137` shared buffer blocks, discarding `99,995` non-matching rows via a filter, and applying an explicit `Sort` (`quicksort`, `25kB` memory) in `7.635 ms`. After creating the composite B-tree index `idx_order_item_history_sku_status_date` on `(sku_code, order_status, order_date)` and running `ANALYZE`, the planner switched to an `Index Scan` that satisfied both the filter predicates and the `ORDER BY order_date ASC` sort order directly, touching only `5` buffer pages (`shared hit=2 read=3`) and completing in `0.052 ms`. However, wall-clock execution timings on a small in-memory dataset inside a shared Codespaces container can fluctuate with CPU scheduling and cache state, and adding a B-tree index does not guarantee faster queries for non-selective filters. Indexes also require extra disk and memory storage and add write overhead to `INSERT`, `UPDATE`, and `DELETE` operations because index entries must be maintained alongside the table.

## Files

| File | Contents |
| :--- | :--- |
| [`Daniel_Anyinu_3019313176_P2_Queries.sql`](Daniel_Anyinu_3019313176_P2_Queries.sql) | Three analytical SQL queries (`JOIN`, `NOT EXISTS`, and `LEFT JOIN` with `GROUP BY`) on the Super Mart schema. |
| [`Daniel_Anyinu_3019313176_P2_Optimisation.sql`](Daniel_Anyinu_3019313176_P2_Optimisation.sql) | Setup for `p2_benchmark.order_item_history` (`100,000` rows), selective query, composite B-tree index, and `EXPLAIN (ANALYZE, BUFFERS)` statements. |
| [`Daniel_Anyinu_3019313176_P2_QueryResults.png`](Daniel_Anyinu_3019313176_P2_QueryResults.png) | Screenshot of executed Portfolio 2 query outputs. |
| [`Daniel_Anyinu_3019313176_P2_AfterIndex1.png`](Daniel_Anyinu_3019313176_P2_AfterIndex1.png) | Screenshot showing creation and seeding of `p2_benchmark.order_item_history` in PostgreSQL. |
| [`Daniel_Anyinu_3019313176_P2_AfterIndex2.png`](Daniel_Anyinu_3019313176_P2_AfterIndex2.png) | Screenshot showing the `100,000` row count, the `5` returned rows, and the baseline `Seq Scan` plan. |
| [`Daniel_Anyinu_3019313176_P2_AfterIndex3.png`](Daniel_Anyinu_3019313176_P2_AfterIndex3.png) | Screenshot showing baseline `Execution Time: 7.635 ms`, index creation, and post-index `Index Scan` (`0.052 ms`). |

## Reference
* PostgreSQL Global Development Group (2026) *PostgreSQL 16 Documentation: Chapter 11. Indexes and 14.1. Using EXPLAIN*. Available at: https://www.postgresql.org/docs/16/using-explain.html.