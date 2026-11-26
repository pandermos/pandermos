Task: database health. Read-only unless stated.

Use the read-only connection described in CLAUDE.md.

PostgreSQL:
- Connections vs max_connections, idle-in-transaction sessions older than 10 minutes.
- Queries running longer than 5 minutes (`pg_stat_activity`).
- Biggest tables and their growth since the last report (store sizes in the state directory).
- Tables with many dead tuples and old last_autovacuum.
- Replication lag if there is a replica.

MySQL/MariaDB:
- Threads_connected vs max_connections, slow query count growth.
- Long running queries (`information_schema.processlist`, time > 300).
- Biggest tables and growth; crashed/corrupt tables reported by the error log.

Redis: memory used vs maxmemory, evicted keys growth, rejected connections.

Never run VACUUM FULL, OPTIMIZE, ALTER, DELETE or kill queries unless CLAUDE.md allows it. Recommend instead, with the exact statement.
