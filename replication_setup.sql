-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 11: Distributed Systems & MySQL Asynchronous Replication Setup
-- Architecture: Primary-Replica Topology (Scale-Out Read Architecture)
-- ==============================================================================

-- ==============================================================================
-- PART 1: PRIMARY SERVER CONFIGURATION (Default Port: 3306)
-- Requirements in my.cnf / my.ini:
--   [mysqld]
--   server-id = 1
--   log_bin = mysql-bin
--   binlog_format = ROW
--   gtid_mode = ON
--   enforce_gtid_consistency = ON
-- ==============================================================================

-- 1. Create dedicated replication service account with restricted privilege
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY 'StrongRepl1!';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;

-- 2. Inspect Primary Binary Log Coordinates
-- Note the File name (e.g. mysql-bin.000001) and Position (e.g. 157)
SHOW MASTER STATUS;


-- ==============================================================================
-- PART 2: REPLICA SERVER CONFIGURATION (Replica Instance / Port: 3307)
-- Requirements in my.cnf / my.ini on Replica:
--   [mysqld]
--   server-id = 2
--   read_only = 1
--   super_read_only = 1
-- ==============================================================================

-- 1. Configure upstream replication source coordinates on Replica
-- (Replace coordinates with output from SHOW MASTER STATUS above)
/*
STOP REPLICA;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = '127.0.0.1',
    SOURCE_PORT = 3306,
    SOURCE_USER = 'repl',
    SOURCE_PASSWORD = 'StrongRepl1!',
    SOURCE_LOG_FILE = 'mysql-bin.000001',
    SOURCE_LOG_POS = 157,
    SOURCE_CONNECT_RETRY = 10;

-- 2. Start Replica threads (I/O thread and SQL SQL/applier thread)
START REPLICA;

-- 3. Verify healthy replication state (Both threads MUST display 'Yes')
-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
-- Seconds_Behind_Source: 0
SHOW REPLICA STATUS\G
*/


-- ==============================================================================
-- PART 3: READ/WRITE SPLIT ROUTING VERIFICATION
-- Operational check demonstrating primary write isolation and replica read safety
-- ==============================================================================

-- On Primary: execute transactional mutations
-- Example: CALL sp_place_order(26, 21, 1, 'Plot 10, Kololo');

-- On Replica: test read-only protection enforcement
-- A write attempt on replica should trigger:
-- ERROR 1290 (HY000): The MySQL server is running with the --read-only option so it cannot execute this statement.
