# Portfolio 1 Database Design and Modelling

## Case study
Super Mart is a retail system that stores registered household customers, product categories, inventory items, customer orders, and order line items. Customers purchase family and household goods, while store staff manage stock levels and fulfill orders. Staff can monitor real-time product availability and review daily sales records.

## Users
Customers browse available products, place orders, and view their purchase history. Store staff register household customers, maintain the product catalogue, update stock quantities, process order checkouts, and track order fulfilment.

## Main operations
Register a household customer; add a product category and inventory items; update product stock quantities; create a customer order with multiple line items; complete or cancel an order; view low-stock products and customer order history.

## Business rules
1. Each household customer has a unique customer ID, phone number, and email address.

2. Each product has a unique SKU code and belongs to exactly one product category. A category can contain multiple products.

3. Every product must have a unit price greater than zero and a stock quantity of zero or more.

4. Each order belongs to one existing customer and contains at least one order line item.

5. An order line item links one product to one order and records the quantity purchased and unit price at checkout.

6. A product can appear at most once per order; purchasing multiple units increases the line item quantity rather than creating duplicate rows.

7. An order item quantity cannot exceed the product's available stock at checkout, preventing overselling.

8. Completed or cancelled orders are locked against further item modifications, and cancellation restores the deducted stock once.

## Scope
One physical Super Mart branch for household inventory, customer orders, and stock tracking. Supplier procurement, external payment gateway processing, home delivery logistics, staff payroll, and user authentication are excluded.

## Design and implementation files

| File | Contents |
| :--- | :--- |
| [Daniel_Anyinu_301931376_P1_Design.md](Daniel_Anyinu_301931376_P1_Design.md) | Entities, attributes, keys, relationships, business rules, and design assumptions. |
| [Daniel_Anyinu_301931376_P1_ERDiagram.md](Daniel_Anyinu_301931376_P1_ERDiagram.md) | Mermaid entity-relationship diagram and key/cardinality explanations. |
| [Daniel_Anyinu_301931376_P1_Normalisation.md](Daniel_Anyinu_301931376_P1_Normalisation.md) | Step-by-step normalisation from unnormalised records through 1NF, 2NF, and 3NF. |
| [Daniel_Anyinu_301931376_P1_Schema.sql](Daniel_Anyinu_301931376_P1_Schema.sql) | PostgreSQL 16 `CREATE TABLE` statements with primary keys, foreign keys, `UNIQUE`, and `CHECK` constraints. |
| [Daniel_Anyinu_301931376_P1_SampleData.sql](Daniel_Anyinu_301931376_P1_SampleData.sql) | Transactional valid sample data inserts for all five Super Mart tables. |
| [Daniel_Anyinu_301931376_P1_ConstraintTests.sql](Daniel_Anyinu_301931376_P1_ConstraintTests.sql) | Deliberately invalid `INSERT` statements and row-count verification query. |
| [screenshots/](screenshots/) | Terminal screenshots showing database connection, table creation, valid inserts, constraint checks, and final record counts. |

## Implementation

The database `super_mart_portfolio` was created and tested in PostgreSQL 16 within a GitHub Codespaces environment using `psql`. Running `Daniel_Anyinu_301931376_P1_Schema.sql` inside a `BEGIN ... COMMIT` transaction created the five core tables in the `public` schema: `customers`, `categories`, `products`, `orders`, and `order_items`. Each table uses a `SERIAL` primary key, required `NOT NULL` columns, foreign key references linking child records to parent records, `UNIQUE` constraints (`phone_number`, `email`, `category_name`, `sku_code`, and composite `(order_id, product_id)`), and `CHECK` constraints enforcing positive prices, non-negative stock, valid quantities, and valid order statuses and closure timestamps.

After verifying the created tables and constraint definitions, `Daniel_Anyinu_301931376_P1_SampleData.sql` was executed in a transaction to populate parent records (`customers` and `categories`) followed by dependent records (`products`, `orders`, and `order_items`) using subqueries on unique values rather than hardcoded IDs. Selected negative test statements from `Daniel_Anyinu_301931376_P1_ConstraintTests.sql` were then executed outside a transaction block so each expected failure could be observed independently without aborting subsequent commands.

## Test results

All valid sample records in `Daniel_Anyinu_301931376_P1_SampleData.sql` were accepted and committed cleanly across all three order states (`COMPLETED`, `OPEN`, and `CANCELLED`). The executed negative constraint tests were rejected as expected: inserting a customer with a `NULL` `full_name` failed with a `NOT NULL` violation (`Daniel_Anyinu_301931376_P1_TestRequiredFullName.png`), inserting a product with a `NULL` `sku_code` failed with a `NOT NULL` violation (`Daniel_Anyinu_301931376_P1_TestRequiredSku_code.png`), and inserting a customer with an existing `phone_number` (`08031112222`) failed with a `UNIQUE` constraint violation on `customers_phone_number_key` (`Daniel_Anyinu_301931376_P1_TestDuplicatePhoneNo.png`). Table-level constraint rules were also inspected and captured across all five tables in `screenshots/`.

After the valid inserts succeeded and the executed invalid inserts were rejected, the verification count query (`Daniel_Anyinu_301931376_P1_RecordCount.png`) confirmed the exact expected final row counts: `categories` = 3, `customers` = 3, `orders` = 3, `products` = 4, and `order_items` = 4.

The remaining negative `INSERT` statements included in `Daniel_Anyinu_301931376_P1_ConstraintTests.sql` (covering the additional duplicate key checks, foreign key lookup failures, and negative/status `CHECK` violations) are provided in the SQL script for reference but were not individually executed in the terminal screenshots. In addition, cross-table and multi-step operational rules—specifically forcing every new order header to include at least one item at creation (Rule 4), comparing `order_items.quantity` against `products.stock_quantity` before deducting inventory (Rule 7), and locking completed or cancelled orders against line-item edits or repeated stock restoration (Rule 8)—require transaction logic or triggers rather than static table keys.