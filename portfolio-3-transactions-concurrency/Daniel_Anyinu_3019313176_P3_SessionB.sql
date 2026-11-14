-- Run in Session B
BEGIN;

SHOW transaction_isolation;

-- Check what Session B can see before Session A commits (uncommitted SM-RICE-5KG is not visible)
SELECT
    o.order_id,
    p.sku_code,
    oi.quantity,
    p.stock_quantity AS shelf_stock
FROM public.orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.order_items oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
WHERE c.email = 'chidi.okafor@example.com'
  AND o.order_date = TIMESTAMP '2026-10-04 10:00:00'
ORDER BY p.sku_code;

-- Attempt to insert the same product (SM-RICE-5KG) into the same order (this statement will WAIT)
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o
     JOIN public.customers c ON o.customer_id = c.customer_id
     WHERE c.email = 'chidi.okafor@example.com'
       AND o.order_date = TIMESTAMP '2026-10-04 10:00:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-RICE-5KG'),
    2,
    12000.00
);

-- Run in Session B to clear the aborted transaction state
ROLLBACK;

-- Final verification query: Prove SM-RICE-5KG appears only once with Session A's quantity (1)
SELECT
    o.order_id,
    c.email,
    o.order_status,
    p.sku_code,
    p.product_name,
    oi.quantity,
    oi.unit_price_at_checkout,
    p.stock_quantity AS shelf_stock
FROM public.orders o
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.order_items oi ON o.order_id = oi.order_id
JOIN public.products p ON oi.product_id = p.product_id
WHERE c.email = 'chidi.okafor@example.com'
  AND o.order_date = TIMESTAMP '2026-10-04 10:00:00'
ORDER BY p.sku_code;