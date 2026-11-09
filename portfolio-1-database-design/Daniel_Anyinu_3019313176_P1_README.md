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