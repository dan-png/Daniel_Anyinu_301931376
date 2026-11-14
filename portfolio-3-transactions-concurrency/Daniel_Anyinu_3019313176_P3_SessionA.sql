-- Setup (run once in Session A): Create an OPEN order with one initial item (SM-DIAP-XL)
BEGIN;

INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (
    (SELECT customer_id FROM public.customers WHERE email = 'chidi.okafor@example.com'),
    TIMESTAMP '2026-10-04 10:00:00',
    'OPEN',
    NULL
);

INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o
     JOIN public.customers c ON o.customer_id = c.customer_id
     WHERE c.email = 'chidi.okafor@example.com'
       AND o.order_date = TIMESTAMP '2026-10-04 10:00:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-DIAP-XL'),
    1,
    8500.00
);

COMMIT;

-- Starting-data check 1: View items currently in the new OPEN order
SELECT
    o.order_id,
    c.email,
    o.order_status,
    p.sku_code,
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

-- Starting-data check 2: Verify product stock for SM-RICE-5KG (product_id 2) and SM-DIAP-XL (product_id 3)
SELECT product_id, sku_code, product_name, unit_price, stock_quantity
FROM public.products
WHERE sku_code IN ('SM-MILK-400G', 'SM-RICE-5KG', 'SM-DIAP-XL')
ORDER BY product_id;


-- Run in Session A
BEGIN;

SHOW transaction_isolation;

INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o
     JOIN public.customers c ON o.customer_id = c.customer_id
     WHERE c.email = 'chidi.okafor@example.com'
       AND o.order_date = TIMESTAMP '2026-10-04 10:00:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-RICE-5KG'),
    1,
    12000.00
);