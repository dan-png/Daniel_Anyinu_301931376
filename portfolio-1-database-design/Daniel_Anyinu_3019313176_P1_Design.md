# Super Mart Database Design
## 1. Entities
The database keeps records of five core entities that support store operations:

customers: Registered households that shop at the store.

categories: Product groups used to organise shelves (for example, Baby Care or Grains).

products: Household items available for sale and tracked in stock.

orders: Checkout records created when a customer buys goods.

order_items: Individual product lines belonging to a specific order.

## 2. Attributes and keys
A Primary Key (PK) uniquely identifies each row in a table. A Foreign Key (FK) links a row to a primary key in another table to keep references valid.

### Customers

```customer_id: SERIAL, PK, required.```

```full_name: VARCHAR(100), required.```

```phone_number: VARCHAR(20), UNIQUE, required.```

```email: VARCHAR(120), UNIQUE, required.```

```registered_at: TIMESTAMP, required (defaults to current time).```

### Categories

```category_id: SERIAL, PK, required.```

```category_name: VARCHAR(80), UNIQUE, required.```

### Products

```product_id: SERIAL, PK, required.```

```category_id: INTEGER, FK to categories(category_id), required.```

```sku_code: VARCHAR(30), UNIQUE, required (for example, 'SM-MILK-400G').```

```product_name: VARCHAR(120), required.```

```unit_price: NUMERIC(10,2), required.```

```stock_quantity: INTEGER, required.```

### Orders

```order_id: SERIAL, PK, required.```

```customer_id: INTEGER, FK to customers(customer_id), required.```

```order_date: TIMESTAMP, required.```

```order_status: VARCHAR(20), required ('OPEN', 'COMPLETED', or 'CANCELLED').```

```closed_at: TIMESTAMP, optional (empty while the order is 'OPEN').```

```order_items```

```order_item_id: SERIAL, PK, required.```

```order_id: INTEGER, FK to orders(order_id), required.```

```product_id: INTEGER, FK to products(product_id), required.```

```quantity: INTEGER, required.```

```unit_price_at_checkout: NUMERIC(10,2), required.```

## 3. Relationships
categories to products (One-to-Many): One category can contain zero or many products (a newly added category may have no products yet). Each product must belong to exactly one category.

customers to orders (One-to-Many): One registered customer can have zero or many orders over time. Each order must belong to one existing customer.

orders to products via order_items (Many-to-Many resolved): One order can include many products, and one product can appear in many orders over time (or zero orders if never sold). The linking table order_items splits this into two One-to-Many links: one order has one or more order_items, and one product appears in zero or many order_items.

## 4. Business rules and constraints
Unique customer identifiers: Enforced by PRIMARY KEY (customer_id) and UNIQUE constraints on phone_number and email in customers.

Product SKU and single category: Enforced by UNIQUE (sku_code) and a NOT NULL foreign key category_id on products referencing categories.

Valid price and stock: Enforced by `CHECK (unit_price > 0)` and `CHECK (stock_quantity >= 0)` on products.

Order customer link and minimum items: A NOT NULL foreign key customer_id links each order to an existing customer. Keys alone cannot force an order to have at least one item at the exact moment the order header is created; the checkout transaction enforces this by inserting the order and its first item together before completing.

Valid line items: Enforced by `NOT NULL foreign keys order_id and product_id on order_items`, plus `CHECK (quantity > 0)` and `CHECK (unit_price_at_checkout > 0)`.

No duplicate product rows per order: Enforced by a composite Unique Constraint UNIQUE (order_id, product_id) on order_items, which stops the same product from being inserted twice into one order.

Prevent overselling: Foreign keys cannot compare values across two tables. A checkout transaction or database trigger (an automatic rule run before insert/update) checks that `order_items.quantity <= products.stock_quantity and deducts the stock`, while `CHECK (stock_quantity >= 0)` blocks negative stock.

Locked completed/cancelled orders and single stock return: `CHECK (order_status IN ('OPEN', 'COMPLETED', 'CANCELLED'))` restricts status values. A database trigger blocks changes to order_items when orders.order_status is 'COMPLETED' or 'CANCELLED' and prevents a 'CANCELLED' order from being cancelled a second time.

## 5. Design assumptions
No stored order total: The orders table omits a total amount column because the total can always be calculated accurately using ```SUM(quantity * unit_price_at_checkout) from order_items```.

Stored checkout unit price: I chose to store unit_price_at_checkout in order_items because shelf prices in products.unit_price change over time, and past receipts must keep their original sale price.

Open order state: Orders start as 'OPEN' while line items are added and move to 'COMPLETED' or 'CANCELLED' at checkout conclusion to satisfy Rule 4 and Rule 8 cleanly.