-- 1. Check current products, prices, and available stock quantities
SELECT
    product_id,
    sku_code,
    product_name,
    unit_price,
    stock_quantity
FROM public.products
ORDER BY product_id ASC;

-- 2. Check current orders, their statuses, and linked order items
SELECT
    o.order_id,
    c.full_name,
    c.email,
    o.order_date,
    o.order_status,
    o.closed_at,
    oi.order_item_id,
    p.sku_code,
    oi.quantity,
    oi.unit_price_at_checkout
FROM public.orders o
JOIN public.customers c ON o.customer_id = c.customer_id
LEFT JOIN public.order_items oi ON o.order_id = oi.order_id
LEFT JOIN public.products p ON oi.product_id = p.product_id
ORDER BY o.order_id ASC, oi.order_item_id ASC;

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

-- Step 2b: Repeat check showing a completed order cannot be completed again
UPDATE public.orders
SET order_status = 'COMPLETED',
    closed_at = TIMESTAMP '2026-10-02 15:00:00'
WHERE order_id = 2
  AND order_status = 'OPEN';

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

-- Step 4: Verify committed changes remain and rolled-back changes are undone
SELECT order_id, order_status, closed_at
FROM public.orders
WHERE order_id = 2;

SELECT product_id, sku_code, product_name, stock_quantity
FROM public.products
WHERE product_id IN (1, 2)
ORDER BY product_id;