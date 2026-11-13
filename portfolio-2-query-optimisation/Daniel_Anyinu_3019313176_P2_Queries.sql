-- Query 1: List order items for OPEN and COMPLETED orders on or after 2026-10-01
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    c.full_name,
    p.sku_code,
    p.product_name,
    oi.quantity,
    oi.unit_price_at_checkout,
    (oi.quantity * oi.unit_price_at_checkout) AS line_total
FROM public.order_items oi
JOIN public.orders o ON oi.order_id = o.order_id
JOIN public.customers c ON o.customer_id = c.customer_id
JOIN public.products p ON oi.product_id = p.product_id
WHERE o.order_status IN ('OPEN', 'COMPLETED')
  AND o.order_date >= TIMESTAMP '2026-10-01 00:00:00'
ORDER BY o.order_date ASC, p.sku_code ASC;

-- Query 2: Find available products (stock_quantity > 0) not in any OPEN or COMPLETED order
SELECT
    p.product_id,
    p.sku_code,
    p.product_name,
    cat.category_name,
    p.unit_price,
    p.stock_quantity
FROM public.products p
JOIN public.categories cat ON p.category_id = cat.category_id
WHERE p.stock_quantity > 0
  AND NOT EXISTS (
      SELECT 1
      FROM public.order_items oi
      JOIN public.orders o ON oi.order_id = o.order_id
      WHERE oi.product_id = p.product_id
        AND o.order_status IN ('OPEN', 'COMPLETED')
  )
ORDER BY p.sku_code ASC;

-- Query 3: Count total order lines per product, retaining products with zero orders
SELECT
    p.sku_code,
    p.product_name,
    cat.category_name,
    p.stock_quantity,
    COUNT(oi.order_item_id) AS order_line_count
FROM public.products p
JOIN public.categories cat ON p.category_id = cat.category_id
LEFT JOIN public.order_items oi ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.sku_code,
    p.product_name,
    cat.category_name,
    p.stock_quantity
ORDER BY order_line_count DESC, p.sku_code ASC;