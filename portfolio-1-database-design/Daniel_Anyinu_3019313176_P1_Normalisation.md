# Super Mart Normalisation

**Normalisation** is the step-by-step process of organising data into separate, linked tables so that facts are not repeated unnecessarily and changes do not cause mistakes (**update anomalies**).

---

## Starting Record (Unnormalised Form - UNF)

At the start, a checkout sheet keeps an entire customer order on one row, packing multiple bought items into repeated lists inside single cells.

| order_id | order_date | order_status | customer_id | full_name | phone_number | product_id | sku_code | product_name | category_id | category_name | unit_price | stock_quantity | quantity | unit_price_at_checkout |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | 2026-10-01 09:15 | COMPLETED | 1 | Amina Bello | 08031112222 | 10, 20 | SM-MILK-400G, SM-RICE-5KG | Peak Milk 400g, Mama Gold Rice 5kg | 1, 2 | Dairy, Grains | 3500.00, 12000.00 | 40, 15 | 2, 1 | 3500.00, 12000.00 |
| 102 | 2026-10-02 14:30 | OPEN | 2 | Chidi Okafor | 08053334444 | 10 | SM-MILK-400G | Peak Milk 400g | 1 | Dairy | 3500.00 | 40 | 3 | 3500.00 |

**Problems in this starting table:**
* Cells contain comma-separated lists of products, prices, and quantities, making it difficult to search or sum individual product sales.
* Product details for *Peak Milk 400g* are repeated across orders.

---

## First Normal Form (1NF)

A table is in **First Normal Form (1NF)** when every cell holds a single (**atomic**) value and there are no repeating lists inside a row.

To reach 1NF, each item on Order 101 is split onto its own row. Because `order_id` alone is no longer unique, the table uses a **composite primary key** (a key made from two fields together): `(order_id, product_id)`. This matches Business Rule 6, which allows a product to appear at most once per order.

### `order_records_1nf`
* **Primary Key (PK):** `(order_id, product_id)`

| order_id (PK) | product_id (PK) | order_date | order_status | customer_id | full_name | phone_number | sku_code | product_name | category_id | category_name | unit_price | stock_quantity | quantity | unit_price_at_checkout |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | 10 | 2026-10-01 09:15 | COMPLETED | 1 | Amina Bello | 08031112222 | SM-MILK-400G | Peak Milk 400g | 1 | Dairy | 3500.00 | 40 | 2 | 3500.00 |
| 101 | 20 | 2026-10-01 09:15 | COMPLETED | 1 | Amina Bello | 08031112222 | SM-RICE-5KG | Mama Gold Rice 5kg | 2 | Grains | 12000.00 | 15 | 1 | 12000.00 |
| 102 | 10 | 2026-10-02 14:30 | OPEN | 2 | Chidi Okafor | 08053334444 | SM-MILK-400G | Peak Milk 400g | 1 | Dairy | 3500.00 | 40 | 3 | 3500.00 |

**What changed and what problems remain:**
* **Removed:** Multi-value lists inside single cells.
* **Remaining problem (Partial Dependencies):** Order and customer details (`order_date`, `order_status`, `customer_id`, `full_name`, `phone_number`) repeat on every line of Order 101, and product details (`sku_code`, `product_name`, `unit_price`, `stock_quantity`, `category_id`, `category_name`) repeat every time the same product is ordered. If *Peak Milk 400g* stock changes from 40 to 37, updating only one row leaves inconsistent stock numbers.

---

## Second Normal Form (2NF)

A table is in **Second Normal Form (2NF)** when it is in 1NF and every non-key field depends on the **whole** composite key, not just part of it (no **partial dependencies**).

In `order_records_1nf`, the key is `(order_id, product_id)`:
1. **Depends only on `order_id`:** `order_date`, `order_status`, `customer_id`, `full_name`, `phone_number`. These move to an `orders_2nf` table.
2. **Depends only on `product_id`:** `sku_code`, `product_name`, `unit_price`, `stock_quantity`, `category_id`, `category_name`. These move to a `products_2nf` table.
3. **Depends on both `(order_id, product_id)` together:** `quantity` and `unit_price_at_checkout` (the price locked in for that specific item on that specific order). These stay in `order_items_2nf`.

### `orders_2nf`
* **PK:** `order_id`

| order_id (PK) | order_date | order_status | customer_id | full_name | phone_number |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | 2026-10-01 09:15 | COMPLETED | 1 | Amina Bello | 08031112222 |
| 102 | 2026-10-02 14:30 | OPEN | 2 | Chidi Okafor | 08053334444 |

### `products_2nf`
* **PK:** `product_id`

| product_id (PK) | sku_code | product_name | unit_price | stock_quantity | category_id | category_name |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 10 | SM-MILK-400G | Peak Milk 400g | 3500.00 | 40 | 1 | Dairy |
| 20 | SM-RICE-5KG | Mama Gold Rice 5kg | 12000.00 | 15 | 2 | Grains |

### `order_items_2nf`
* **PK:** `(order_id, product_id)`
* **Foreign Keys (FK):** `order_id` references `orders_2nf(order_id)`, `product_id` references `products_2nf(product_id)`

| order_id (PK, FK) | product_id (PK, FK) | quantity | unit_price_at_checkout |
| :--- | :--- | :--- | :--- |
| 101 | 10 | 2 | 3500.00 |
| 101 | 20 | 1 | 12000.00 |
| 102 | 10 | 3 | 3500.00 |

**What moved and why:**
* Order header facts moved to `orders_2nf` so Order 101's date and customer appear once instead of repeating per item.
* Product facts moved to `products_2nf` so *Peak Milk 400g* price and stock are stored in one row; updating stock now happens in one place.
* **Remaining problem (Transitive Dependencies):** In `orders_2nf`, `full_name` and `phone_number` belong to `customer_id`, not `order_id` (if Amina places a second order, her phone number repeats, and a new customer cannot be registered before placing an order). In `products_2nf`, `category_name` belongs to `category_id`, not `product_id` (a new category cannot exist without a product).

---

## Third Normal Form (3NF)

A table is in **Third Normal Form (3NF)** when it is in 2NF and no non-key field depends on another non-key field (no **transitive dependencies**).

1. From `orders_2nf`, `full_name` and `phone_number` depend on `customer_id`, so they move to `customers`. `orders` keeps `customer_id` as a **Foreign Key (FK)** to stay linked.
2. From `products_2nf`, `category_name` depends on `category_id`, so it moves to `categories`. `products` keeps `category_id` as a Foreign Key.

### `customers`
* **PK:** `customer_id` | **Unique (UK):** `phone_number`

| customer_id (PK) | full_name | phone_number (UK) |
| :--- | :--- | :--- |
| 1 | Amina Bello | 08031112222 |
| 2 | Chidi Okafor | 08053334444 |

### `categories`
* **PK:** `category_id` | **UK:** `category_name`

| category_id (PK) | category_name (UK) |
| :--- | :--- |
| 1 | Dairy |
| 2 | Grains |

### `products`
* **PK:** `product_id` | **FK:** `category_id` -> `categories(category_id)` | **UK:** `sku_code`

| product_id (PK) | category_id (FK) | sku_code (UK) | product_name | unit_price | stock_quantity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 10 | 1 | SM-MILK-400G | Peak Milk 400g | 3500.00 | 40 |
| 20 | 2 | SM-RICE-5KG | Mama Gold Rice 5kg | 12000.00 | 15 |

### `orders`
* **PK:** `order_id` | **FK:** `customer_id` -> `customers(customer_id)`

| order_id (PK) | customer_id (FK) | order_date | order_status |
| :--- | :--- | :--- | :--- |
| 101 | 1 | 2026-10-01 09:15 | COMPLETED |
| 102 | 2 | 2026-10-02 14:30 | OPEN |

### `order_items`
* **PK:** `order_item_id` | **FKs:** `order_id` -> `orders(order_id)`, `product_id` -> `products(product_id)` | **UK:** `(order_id, product_id)`

| order_item_id (PK) | order_id (FK) | product_id (FK) | quantity | unit_price_at_checkout |
| :--- | :--- | :--- | :--- | :--- |
| 1 | 101 | 10 | 2 | 3500.00 |
| 2 | 101 | 20 | 1 | 12000.00 |
| 3 | 102 | 10 | 3 | 3500.00 |

---

## Alignment with Final Database Design

* **Fields omitted from example tables for readability:**
  * `customers`: `email` (`VARCHAR(120)`, UNIQUE, required) and `registered_at` (`TIMESTAMP`, required) both depend solely on `customer_id`.
  * `orders`: `closed_at` (`TIMESTAMP`, optional) depends solely on `order_id` (`2026-10-01 09:20` for Order 101; `NULL` for Order 102).
* **Why `unit_price_at_checkout` stays in `order_items`:** Although `products.unit_price` holds the current shelf price, `unit_price_at_checkout` records the historical price paid on that specific order so future shelf price updates do not alter completed receipts.
* **Surrogate key on `order_items`:** In the 1NF and 2NF steps, `(order_id, product_id)` served as the natural composite primary key. The final agreed design adds an automatically generated ID (`order_item_id SERIAL PRIMARY KEY`) for simpler row referencing while keeping `UNIQUE (order_id, product_id)` to enforce Business Rule 6. Adding an automatic ID alone does not make a table 3NF; 3NF is achieved because every non-key attribute in `order_items` (`quantity` and `unit_price_at_checkout`) depends solely on the `(order_id, product_id)` combination and nothing else.