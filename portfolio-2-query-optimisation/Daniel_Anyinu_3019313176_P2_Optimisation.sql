-- Create an isolated schema and synthetic history table (run once)
CREATE SCHEMA p2_benchmark;

CREATE TABLE p2_benchmark.order_item_history (
    history_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    sku_code VARCHAR(30) NOT NULL,
    order_date TIMESTAMP NOT NULL,
    order_status VARCHAR(20) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price_at_checkout NUMERIC(10,2) NOT NULL
);

-- Populate 100,000 plausible rows at 1-minute intervals starting 2026-01-01 (run once)
INSERT INTO p2_benchmark.order_item_history (
    order_id,
    customer_id,
    product_id,
    sku_code,
    order_date,
    order_status,
    quantity,
    unit_price_at_checkout
)
SELECT
    1000 + ((gs.n - 1) / 2) AS order_id,
    c.customer_id,
    p.product_id,
    p.sku_code,
    TIMESTAMP '2026-01-01 00:00:00' + ((gs.n - 1) * INTERVAL '1 minute') AS order_date,
    CASE
        WHEN gs.n % 10 = 0 THEN 'CANCELLED'
        WHEN gs.n % 5 = 0 THEN 'OPEN'
        ELSE 'COMPLETED'
    END AS order_status,
    (gs.n % 4) + 1 AS quantity,
    p.unit_price AS unit_price_at_checkout
FROM generate_series(1, 100000) AS gs(n)
JOIN public.customers c
    ON c.email = CASE (gs.n % 3)
        WHEN 1 THEN 'amina.bello@example.com'
        WHEN 2 THEN 'chidi.okafor@example.com'
        ELSE 'tunde.adeyemi@example.com'
    END
JOIN public.products p
    ON p.sku_code = CASE (gs.n % 4)
        WHEN 1 THEN 'SM-MILK-400G'
        WHEN 2 THEN 'SM-RICE-5KG'
        WHEN 3 THEN 'SM-DIAP-XL'
        ELSE 'SM-YOG-1L'
    END;

-- Update PostgreSQL statistics so the query planner knows row distribution
ANALYZE p2_benchmark.order_item_history;

-- Verify that exactly 100,000 synthetic records exist
SELECT COUNT(*) AS total_benchmark_rows
FROM p2_benchmark.order_item_history;

-- Selective lookup by SKU, status, and narrow date-time window
SELECT
    history_id,
    order_id,
    sku_code,
    order_date,
    order_status,
    quantity,
    unit_price_at_checkout
FROM p2_benchmark.order_item_history
WHERE sku_code = 'SM-MILK-400G'
  AND order_status = 'COMPLETED'
  AND order_date BETWEEN TIMESTAMP '2026-01-01 10:00:00'
                     AND TIMESTAMP '2026-01-01 10:20:00'
ORDER BY order_date ASC;

-- Baseline execution plan before indexing (run 1x warm-up, then 3x for measurement)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    order_id,
    sku_code,
    order_date,
    order_status,
    quantity,
    unit_price_at_checkout
FROM p2_benchmark.order_item_history
WHERE sku_code = 'SM-MILK-400G'
  AND order_status = 'COMPLETED'
  AND order_date BETWEEN TIMESTAMP '2026-01-01 10:00:00'
                     AND TIMESTAMP '2026-01-01 10:20:00'
ORDER BY order_date ASC;


-- Create composite B-tree index and refresh statistics (run once)
CREATE INDEX idx_order_item_history_sku_status_date
ON p2_benchmark.order_item_history (sku_code, order_status, order_date);

ANALYZE p2_benchmark.order_item_history;

-- Post-index execution plan (run 1x warm-up, then 3x for measurement)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    order_id,
    sku_code,
    order_date,
    order_status,
    quantity,
    unit_price_at_checkout
FROM p2_benchmark.order_item_history
WHERE sku_code = 'SM-MILK-400G'
  AND order_status = 'COMPLETED'
  AND order_date BETWEEN TIMESTAMP '2026-01-01 10:00:00'
                     AND TIMESTAMP '2026-01-01 10:20:00'
ORDER BY order_date ASC;