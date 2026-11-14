# Portfolio 5 Distributed and Cloud Database Exercise

## Current setup
In the implemented work across Portfolios 1 to 4, Super Mart runs inside a single GitHub Codespaces environment (`Codespaces: urban dollop`)[cite: 1, 2, 3, 4]. Core relational tables (`customers`, `categories`, `products`, `orders`, and `order_items`) run on a single local PostgreSQL 16 database (`super_mart_portfolio`)[cite: 2, 3, 4], while the four `store_events` documents (`EVT-2026-001` to `EVT-2026-004`) run on a standalone local MongoDB connection (`127.0.0.1:27017` via `directConnection=true`). Multi-node clustering, cloud hosting, and failover tests have not been implemented, and the underlying host hardware topology inside the container is not verified.

## Proposed replication
As an unimplemented architectural proposal for the `super_mart_nosql` activity log, the standalone MongoDB instance could be replaced with a three-member [MongoDB replica set](https://www.mongodb.com/docs/manual/replication/) using three voting, data-holding nodes across separate hosts and failure zones:

| Member | Starting role | Location |
| :--- | :--- | :--- |
| `mongo-node-1` | Primary | Failure Zone A (Host 1) |
| `mongo-node-2` | Secondary | Failure Zone B (Host 2) |
| `mongo-node-3` | Secondary | Failure Zone C (Host 3) |

When a store event such as an `order_status_event` or `stock_adjustment_event` is recorded, the application writes to the primary, and the two secondaries asynchronously copy the primary's operation log (`oplog`) so each member holds a full copy of `store_events` ([MongoDB Replication](https://www.mongodb.com/docs/manual/replication/)).

## Failure and consistency
If the primary (`mongo-node-1`) fails, the two remaining secondaries detect the outage and hold a [replica set election](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/) to promote a new primary. New `store_events` writes pause briefly during the election until a primary is chosen; if two nodes fail simultaneously and no majority (2 of 3 voting members) is reachable, no primary can be elected and the replica set becomes read-only ([Replica Set Elections](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/)). Using [`w: "majority"` write concern](https://www.mongodb.com/docs/v8.0/reference/write-concern/) ensures an `order_status_event` is acknowledged only after at least two data-bearing members record it, preventing rollbacks on failover, though reads directed to secondaries can still return slightly stale activity history due to replication lag. Authoritative stock deductions (`stock_quantity >= 0`) and checkout locks must remain in PostgreSQL (`super_mart_portfolio`)[cite: 2, 3, 4] rather than relying on replicated MongoDB logs.

## Sharding and cloud deployment
Unlike replication, which copies the same documents across nodes for high availability, [sharding](https://www.mongodb.com/docs/manual/sharding/) splits a collection's documents across multiple shards using a shard key to scale storage and write throughput. Super Mart's small dataset (four sample events and single-branch operations) does not need sharding, which would add unnecessary routing (`mongos`) and config-server complexity. A proposed cloud deployment on MongoDB Atlas should enforce user authentication, TLS/at-rest encryption, restricted IP network access, and scheduled [cluster backups and point-in-time restore](https://www.mongodb.com/docs/atlas/backup-restore-cluster/). However, managed cloud clusters increase ongoing hosting and backup storage costs, and a key limitation is that MongoDB replication only protects `super_mart_nosql`—it does not replicate the PostgreSQL database (`super_mart_portfolio`)[cite: 2, 3, 4] or automatically synchronise records between the two systems.

## References
* MongoDB, Inc. *Replication*. Available at: https://www.mongodb.com/docs/manual/replication/
* MongoDB, Inc. *Replica Set Elections (v8.0)*. Available at: https://www.mongodb.com/docs/v8.0/core/replica-set-elections/
* MongoDB, Inc. *Write Concern Reference (v8.0)*. Available at: https://www.mongodb.com/docs/v8.0/reference/write-concern/
* MongoDB, Inc. *Sharding*. Available at: https://www.mongodb.com/docs/manual/sharding/
* MongoDB, Inc. *Back Up and Restore a Cluster (MongoDB Atlas)*. Available at: https://www.mongodb.com/docs/atlas/backup-restore-cluster/