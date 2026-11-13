-- Super Mart Valid Sample Dataset (PostgreSQL 16)
-- Portfolio 1: Database Design and Modelling[cite: 3]

BEGIN;

-- 1. Insert parent records into customers (3 household customers)
INSERT INTO public.customers (full_name, phone_number, email, registered_at)
VALUES
    ('Amina Bello', '08031112222', 'amina.bello@example.com', '2026-10-01 08:30:00'),
    ('Chidi Okafor', '08053334444', 'chidi.okafor@example.com', '2026-10-01 10:00:00'),
    ('Tunde Adeyemi', '08075556666', 'tunde.adeyemi@example.com', '2026-10-02 09:15:00');

-- 2. Insert parent records into categories (3 store categories)
INSERT INTO public.categories (category_name)
VALUES
    ('Dairy'),
    ('Grains'),
    ('Baby Care');

-- 3. Insert records into products (looking up category_id by unique category_name)
-- Includes products with normal stock and one product with zero stock (valid under Rule 3).
INSERT INTO public.products (category_id, sku_code, product_name, unit_price, stock_quantity)
VALUES
    ((SELECT category_id FROM public.categories WHERE category_name = 'Dairy'), 'SM-MILK-400G', 'Peak Milk 400g', 3500.00, 40),
    ((SELECT category_id FROM public.categories WHERE category_name = 'Grains'), 'SM-RICE-5KG', 'Mama Gold Rice 5kg', 12000.00, 15),
    ((SELECT category_id FROM public.categories WHERE category_name = 'Baby Care'), 'SM-DIAP-XL', 'SoftCare Diapers XL', 8500.00, 20),
    ((SELECT category_id FROM public.categories WHERE category_name = 'Dairy'), 'SM-YOG-1L', 'FarmFresh Yoghurt 1L', 2500.00, 0);

-- 4. Insert records into orders (demonstrating all three valid states: COMPLETED, OPEN, CANCELLED)
-- Looks up customer_id using the unique email address.
INSERT INTO public.orders (customer_id, order_date, order_status, closed_at)
VALUES
    (
        (SELECT customer_id FROM public.customers WHERE email = 'amina.bello@example.com'),
        '2026-10-01 09:15:00',
        'COMPLETED',
        '2026-10-01 09:20:00'
    ),
    (
        (SELECT customer_id FROM public.customers WHERE email = 'chidi.okafor@example.com'),
        '2026-10-02 14:30:00',
        'OPEN',
        NULL
    ),
    (
        (SELECT customer_id FROM public.customers WHERE email = 'tunde.adeyemi@example.com'),
        '2026-10-03 11:00:00',
        'CANCELLED',
        '2026-10-03 11:10:00'
    );

-- 5. Insert records into order_items (looking up order_id and product_id via unique values)
INSERT INTO public.order_items (order_id, product_id, quantity, unit_price_at_checkout)
VALUES
    -- Two items for Amina's COMPLETED order
    (
        (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'amina.bello@example.com' AND o.order_date = '2026-10-01 09:15:00'),
        (SELECT product_id FROM public.products WHERE sku_code = 'SM-MILK-400G'),
        2,
        3500.00
    ),
    (
        (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'amina.bello@example.com' AND o.order_date = '2026-10-01 09:15:00'),
        (SELECT product_id FROM public.products WHERE sku_code = 'SM-RICE-5KG'),
        1,
        12000.00
    ),
    -- One item for Chidi's OPEN order
    (
        (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'chidi.okafor@example.com' AND o.order_date = '2026-10-02 14:30:00'),
        (SELECT product_id FROM public.products WHERE sku_code = 'SM-MILK-400G'),
        3,
        3500.00
    ),
    -- One item for Tunde's CANCELLED order
    (
        (SELECT o.order_id FROM public.orders o JOIN public.customers c ON o.customer_id = c.customer_id WHERE c.email = 'tunde.adeyemi@example.com' AND o.order_date = '2026-10-03 11:00:00'),
        (SELECT product_id FROM public.products WHERE sku_code = 'SM-DIAP-XL'),
        1,
        8500.00
    );

COMMIT;