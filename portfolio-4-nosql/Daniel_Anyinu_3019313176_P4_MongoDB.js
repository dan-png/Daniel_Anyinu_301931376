// 1. Select the database and verify the collection is empty before inserting
use("super_mart_nosql");

db.store_events.countDocuments();

// 2. Insert four fictional Super Mart activity documents once
db.store_events.insertMany([
  {
    _id: "EVT-2026-001",
    event_type: "order_status_event",
    event_time: "2026-10-01T09:20:00Z",
    product: {
      sku_code: "SM-MILK-400G",
      product_name: "Peak Milk 400g",
      category_name: "Dairy"
    },
    actor: {
      role: "customer",
      name: "Amina Bello",
      email: "amina.bello@example.com"
    },
    details: {
      order_id: 1,
      new_status: "COMPLETED",
      quantity: 2,
      unit_price_at_checkout: 3500.00,
      payment_channel: "POS_CARD"
    }
  },
  {
    _id: "EVT-2026-002",
    event_type: "order_status_event",
    event_time: "2026-10-02T14:40:00Z",
    product: {
      sku_code: "SM-MILK-400G",
      product_name: "Peak Milk 400g",
      category_name: "Dairy"
    },
    actor: {
      role: "customer",
      name: "Chidi Okafor",
      email: "chidi.okafor@example.com"
    },
    details: {
      order_id: 2,
      new_status: "COMPLETED",
      quantity: 3,
      unit_price_at_checkout: 3500.00,
      payment_channel: "BANK_TRANSFER"
    }
  },
  {
    _id: "EVT-2026-003",
    event_type: "order_status_event",
    event_time: "2026-10-03T11:10:00Z",
    product: {
      sku_code: "SM-DIAP-XL",
      product_name: "SoftCare Diapers XL",
      category_name: "Baby Care"
    },
    actor: {
      role: "customer",
      name: "Tunde Adeyemi",
      email: "tunde.adeyemi@example.com"
    },
    details: {
      order_id: 3,
      new_status: "CANCELLED",
      quantity: 1,
      cancel_reason: "Customer changed size preference",
      stock_restored: true
    }
  },
  {
    _id: "EVT-2026-004",
    event_type: "stock_adjustment_event",
    event_time: "2026-10-04T08:00:00Z",
    product: {
      sku_code: "SM-YOG-1L",
      product_name: "FarmFresh Yoghurt 1L",
      category_name: "Dairy"
    },
    actor: {
      role: "store_staff",
      name: "Musa Ibrahim"
    },
    details: {
      adjustment_type: "RESTOCK_DELIVERY",
      previous_stock: 0,
      quantity_added: 24,
      new_stock: 24,
      supplier_batch: "BATCH-YOG-202610"
    }
  }
]);


// Query 1: Total count of documents in store_events
db.store_events.countDocuments();

// Query 2: Ordered event history for product SM-MILK-400G
db.store_events.find(
  { "product.sku_code": "SM-MILK-400G" },
  {
    _id: 1,
    event_type: 1,
    event_time: 1,
    "actor.name": 1,
    "details.order_id": 1,
    "details.new_status": 1,
    "details.quantity": 1
  }
).sort({ event_time: 1 });


// Query 3: Filter by nested field details.new_status for COMPLETED orders
db.store_events.find(
  { "details.new_status": "COMPLETED" },
  {
    _id: 1,
    event_time: 1,
    "product.sku_code": 1,
    "actor.email": 1,
    "details.order_id": 1,
    "details.payment_channel": 1
  }
).sort({ _id: 1 });