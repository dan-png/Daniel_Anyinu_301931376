# Portfolio 4 NoSQL and Advanced Data Models

## Document model
The `store_events` collection in the `super_mart_nosql` database stores separate fictional activity documents that reuse existing Super Mart identifiers (`sku_code`, `email`, and `order_id`) without automatically extracting or modifying the PostgreSQL records. Each document shares top-level `_id`, `event_type`, and `event_time` fields, embeds related `product` and `actor` objects, and uses a flexible `details` sub-document whose fields vary between `"order_status_event"` and `"stock_adjustment_event"` records:

```json
{
  "_id": "EVT-2026-001",
  "event_type": "order_status_event",
  "event_time": "2026-10-01T09:20:00Z",
  "product": {
    "sku_code": "SM-MILK-400G",
    "product_name": "Peak Milk 400g",
    "category_name": "Dairy"
  },
  "actor": {
    "role": "customer",
    "name": "Amina Bello",
    "email": "amina.bello@example.com"
  },
  "details": {
    "order_id": 1,
    "new_status": "COMPLETED",
    "quantity": 2,
    "unit_price_at_checkout": 3500.00,
    "payment_channel": "POS_CARD"
  }
}
```

## Implementation and results
Using `mongosh` connected to local MongoDB (`mongodb://127.0.0.1:27017`), [`Daniel_Anyinu_3019313176_P4_MongoDB.js`](Daniel_Anyinu_3019313176_P4_MongoDB.js) selected `super_mart_nosql`, confirmed `db.store_events.countDocuments()` returned `0`, and inserted four event documents (`EVT-2026-001` to `EVT-2026-004`) in a single `insertMany` call. The total count query returned `4` documents. The product history query filtering on `"product.sku_code": "SM-MILK-400G"` sorted by `event_time` returned `2` chronological checkout events (`EVT-2026-001` for Amina Bello, quantity `2`, and `EVT-2026-002` for Chidi Okafor, quantity `3`). The nested-field query filtering on `"details.new_status": "COMPLETED"` returned the `2` completed order events (`POS_CARD` and `BANK_TRANSFER`) while excluding the cancelled diaper order (`EVT-2026-003`) and the staff yoghurt restock event (`EVT-2026-004`).

## Why MongoDB fits
MongoDB suits Super Mart's append-only activity log because different store events (`order_status_event` for checkouts and cancellations versus `stock_adjustment_event` for supplier restocks) carry different metadata inside `details` without requiring sparse nullable columns or multi-table joins. However, embedding product names and customer details inside event documents duplicates data and does not enforce relational foreign keys or stock-level `CHECK` constraints automatically, so core inventory balances and order checkouts remain better suited to PostgreSQL.

## Files

| File | Contents |
| :--- | :--- |
| [`Daniel_Anyinu_3019313176_P4_MongoDB.js`](Daniel_Anyinu_3019313176_P4_MongoDB.js) | `mongosh` commands to select `super_mart_nosql`, verify an empty collection, insert four activity documents, and run three queries. |
| [`screenshots/`](screenshots/) | Terminal screenshot showing the `insertMany` acknowledgement and the outputs of the three MongoDB queries. |

## References
* MongoDB, Inc. (2026) *MongoDB Manual: Insert Documents and Query Embedded Documents*. Available at: https://www.mongodb.com/docs/manual/tutorial/query-embedded-documents/.