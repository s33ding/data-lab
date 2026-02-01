# PostgreSQL Commands Guide

## Connection
```bash
psql -h hostname -p port -U username -d database
psql postgres://username:password@hostname:port/database
```

## Meta Commands
```sql
\l                    -- List databases
\c database_name      -- Connect to database
\dt                   -- List tables
\d table_name         -- Describe table
\du                   -- List users
\q                    -- Quit
\?                    -- Help
```

## Database Operations
```sql
CREATE DATABASE db_name;
DROP DATABASE db_name;
```

## Table Operations
```sql
CREATE TABLE table_name (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

DROP TABLE table_name;
ALTER TABLE table_name ADD COLUMN column_name data_type;
```

## Data Operations
```sql
INSERT INTO table_name (column1, column2) VALUES ('value1', 'value2');
SELECT * FROM table_name WHERE condition;
UPDATE table_name SET column1 = 'new_value' WHERE condition;
DELETE FROM table_name WHERE condition;
```

## User Management
```sql
CREATE USER username WITH PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE db_name TO username;
ALTER USER username WITH SUPERUSER;
```

## Backup & Restore
```bash
pg_dump database_name > backup.sql
psql database_name < backup.sql
```
