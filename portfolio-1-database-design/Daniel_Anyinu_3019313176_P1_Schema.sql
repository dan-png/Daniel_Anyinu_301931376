-- Super Mart Database Schema (PostgreSQL 16)
-- Portfolio 1: Database Design and Modelling

BEGIN;

-- 1. Customers table (Rule 1: unique customer ID, phone number, and email)
CREATE TABLE public.customers (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Categories table (Rule 2: unique category names to organise products)
CREATE TABLE public.categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE
);

-- 3. Products table (Rule 2: unique SKU and single category; Rule 3: valid price and stock)
CREATE TABLE public.products (
    product_id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES public.categories(category_id),
    sku_code VARCHAR(30) NOT NULL UNIQUE,
    product_name VARCHAR(120) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

-- 4. Orders table (Rule 4: belongs to one customer; Rule 8: valid order statuses)
-- closed_at is optional (NULL) while order_status is 'OPEN'.
CREATE TABLE public.orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES public.customers(customer_id),
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) NOT NULL DEFAULT 'OPEN'
        CHECK (order_status IN ('OPEN', 'COMPLETED', 'CANCELLED')),
    closed_at TIMESTAMP NULL,
    CHECK (
        (order_status = 'OPEN' AND closed_at IS NULL) OR
        (order_status IN ('COMPLETED', 'CANCELLED') AND closed_at IS NOT NULL AND closed_at >= order_date)
    )
);

-- 5. Order Items table (Rule 5: links product and order with valid quantity and checkout price)
-- Rule 6: UNIQUE (order_id, product_id) prevents duplicate product rows in the same order.
CREATE TABLE public.order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES public.orders(order_id),
    product_id INTEGER NOT NULL REFERENCES public.products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_at_checkout NUMERIC(10,2) NOT NULL CHECK (unit_price_at_checkout > 0),
    UNIQUE (order_id, product_id)
);

-- Note on limits of table definitions:
-- 1. Rule 4 (every order contains at least one line item) cannot be enforced by table keys alone;
--    checkout transactions must insert the order and its first item together.
-- 2. Rule 7 (order item quantity cannot exceed available product stock) compares values across two
--    tables and requires checkout transaction logic or a trigger alongside the stock_quantity >= 0 check.
-- 3. Rule 8 (locking completed/cancelled orders against item changes and restoring stock only once
--    on cancellation) requires transaction logic or triggers rather than static table constraints.

COMMIT;