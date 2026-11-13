-- Super Mart Deliberate Constraint Tests (PostgreSQL 16)
-- Portfolio 1: Database Design and Modelling[cite: 3]
-- Note: Run each statement outside a transaction block so one failure does not abort subsequent tests.

-- ============================================================================
-- SECTION A: REQUIRED FIELDS (NOT NULL CONSTRAINTS)
-- ============================================================================

-- Test 1: Missing required full_name in customers.
-- Expected error: ERROR: null value in column "full_name" of relation "customers" violates not-null constraint
INSERT INTO public.customers (full_name, phone_number, email)
VALUES (NULL, '08090001111', 'null.name@example.com');

-- Test 2: Missing required sku_code in products.
-- Expected error: ERROR: null value in column "sku_code" of relation "products" violates not-null constraint
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES (
    (SELECT category_id FROM public.categories WHERE category_name = 'Dairy'),
    NULL,
    'Unlabelled Butter 250g',
    1800.00,
    10
);

-- ============================================================================
-- SECTION B: UNIQUE CONSTRAINTS (RULES 1, 2, AND 6)
-- ============================================================================

-- Test 3 (Rule 1): Duplicate phone_number in customers.
-- Expected error: ERROR: duplicate key value violates unique constraint "customers_phone_number_key"
INSERT INTO public.customers (full_name, phone_number, email)
VALUES ('Bola Musa', '08031112222', 'bola.musa@example.com');

-- Test 4 (Rule 1): Duplicate email in customers.
-- Expected error: ERROR: duplicate key value violates unique constraint "customers_email_key"
INSERT INTO public.customers (full_name, phone_number, email)
VALUES ('Bola Musa', '08098887777', 'amina.bello@example.com');

-- Test 5 (Rule 2): Duplicate category_name in categories.
-- Expected error: ERROR: duplicate key value violates unique constraint "categories_category_name_key"
INSERT INTO public.categories (category_name)
VALUES ('Dairy');

-- Test 6 (Rule 2): Duplicate sku_code in products.
-- Expected error: ERROR: duplicate key value violates unique constraint "products_sku_code_key"
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES (
    (SELECT category_id FROM public.categories WHERE category_name = 'Dairy'),
    'SM-MILK-400G',
    'Duplicate SKU Milk Tin',
    3600.00,
    25
);

-- Test 7 (Rule 6): Duplicate product row within the same order (UNIQUE (order_id, product_id)).
-- Expected error: ERROR: duplicate key value violates unique constraint "order_items_order_id_product_id_key"
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'chidi.okafor@example.com' AND o.order_date = '2026-10-02 14:30:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-MILK-400G'),
    1,
    3500.00
);

-- ============================================================================
-- SECTION C: FOREIGN KEY CONSTRAINTS (RULES 2, 4, AND 5)
-- ============================================================================

-- Test 8 (Rule 2): Product referencing a non-existent category_id.
-- Expected error: ERROR: insert or update on table "products" violates foreign key constraint "products_category_id_fkey"
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES (-999, 'SM-SOAP-100G', 'Fresh Bath Soap', 900.00, 30);

-- Test 9 (Rule 4): Order referencing a non-existent customer_id.
-- Expected error: ERROR: insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (-999, '2026-10-04 12:00:00', 'OPEN', NULL);

-- Test 10 (Rule 5): Order item referencing a non-existent order_id.
-- Expected error: ERROR: insert or update on table "order_items" violates foreign key constraint "order_items_order_id_fkey"
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    -999,
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-MILK-400G'),
    1,
    3500.00
);

-- Test 11 (Rule 5): Order item referencing a non-existent product_id.
-- Expected error: ERROR: insert or update on table "order_items" violates foreign key constraint "order_items_product_id_fkey"
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'chidi.okafor@example.com' AND o.order_date = '2026-10-02 14:30:00'),
    -999,
    1,
    3500.00
);

-- ============================================================================
-- SECTION D: CHECK CONSTRAINTS (RULES 3, 5, AND 8)
-- ============================================================================

-- Test 12 (Rule 3): Product with unit_price equal to zero (must be > 0).
-- Expected error: ERROR: new row for relation "products" violates check constraint "products_unit_price_check"
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES (
    (SELECT category_id FROM public.categories WHERE category_name = 'Grains'),
    'SM-OAT-500G',
    'Morning Oats 500g',
    0.00,
    20
);

-- Test 13 (Rule 3): Product with negative stock_quantity (must be >= 0).
-- Expected error: ERROR: new row for relation "products" violates check constraint "products_stock_quantity_check"
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES (
    (SELECT category_id FROM public.categories WHERE category_name = 'Grains'),
    'SM-BEANS-2KG',
    'Honey Beans 2kg',
    4500.00,
    -5
);

-- Test 14 (Rule 8): Order with an invalid order_status value outside ('OPEN', 'COMPLETED', 'CANCELLED').
-- Expected error: ERROR: new row for relation "orders" violates check constraint "orders_order_status_check"
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (
    (SELECT customer_id FROM public.customers WHERE email = 'amina.bello@example.com'),
    '2026-10-04 10:00:00',
    'PROCESSING',
    NULL
);

-- Test 15 (Rule 8): OPEN order that wrongly includes a non-null closed_at timestamp.
-- Expected error: ERROR: new row for relation "orders" violates check constraint "orders_check"
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (
    (SELECT customer_id FROM public.customers WHERE email = 'amina.bello@example.com'),
    '2026-10-04 10:00:00',
    'OPEN',
    '2026-10-04 10:05:00'
);

-- Test 16 (Rule 8): COMPLETED order missing a closed_at timestamp (closed_at is NULL).
-- Expected error: ERROR: new row for relation "orders" violates check constraint "orders_check"
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (
    (SELECT customer_id FROM public.customers WHERE email = 'amina.bello@example.com'),
    '2026-10-04 10:00:00',
    'COMPLETED',
    NULL
);

-- Test 17 (Rule 8): COMPLETED order where closed_at is earlier than order_date.
-- Expected error: ERROR: new row for relation "orders" violates check constraint "orders_check"
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES (
    (SELECT customer_id FROM public.customers WHERE email = 'amina.bello@example.com'),
    '2026-10-04 10:00:00',
    'COMPLETED',
    '2026-10-04 09:00:00'
);

-- Test 18 (Rule 5): Order item with quantity equal to zero (must be > 0).
-- Expected error: ERROR: new row for relation "order_items" violates check constraint "order_items_quantity_check"
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'chidi.okafor@example.com' AND o.order_date = '2026-10-02 14:30:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-RICE-5KG'),
    0,
    12000.00
);

-- Test 19 (Rule 5): Order item with negative unit_price_at_checkout (must be > 0).
-- Expected error: ERROR: new row for relation "order_items" violates check constraint "order_items_unit_price_at_checkout_check"
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES (
    (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'chidi.okafor@example.com' AND o.order_date = '2026-10-02 14:30:00'),
    (SELECT product_id FROM public.products WHERE sku_code = 'SM-RICE-5KG'),
    1,
    -500.00
);

-- ============================================================================
-- SECTION E: VERIFICATION ROW COUNT QUERY
-- ============================================================================
-- Expected row counts after SampleData.sql succeeds and all 19 invalid inserts above fail:
--   categories  : 3
--   customers   : 3
--   orders      : 3
--   products    : 4
--   order_items : 4

SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM public.categories
UNION ALL
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM public.customers
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM public.orders
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM public.products
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM public.order_items;