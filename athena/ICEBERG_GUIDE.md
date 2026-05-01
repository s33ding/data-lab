# Iceberg Environment Guide

## Overview
This environment uses Apache Iceberg tables in Athena for CDC (Change Data Capture) data from Kafka topics.

## Architecture
- **Raw Layer**: JSON data from Kafka topics stored in S3
- **Bronze Layer**: Iceberg tables with CDC fields (op, ts_ms, before, after, record_hash)
- **Silver Layer**: Cleaned/processed data
- **Gold Layer**: Business-ready aggregated data

## Setup

### 1. Create Databases
```bash
python create_databases.py
```
Creates: bronze, silver, gold databases

### 2. Create Bronze Iceberg Tables
```bash
cd bronze
python create_all_tables.py
```
Creates Iceberg tables for:
- mcdonalds_sales_bronze
- mcdonalds_inventory_bronze
- mcdonalds_employees_bronze

### 3. Verify Setup
```bash
python list_databases.py
cd bronze
python check_tables.py
```

## Working with Iceberg Tables

### Key Features
- **Time Travel**: Query historical data snapshots
- **ACID Transactions**: Atomic commits for data consistency
- **Schema Evolution**: Add/modify columns without rewriting data
- **Partition Evolution**: Change partitioning without data migration

### Common Operations

#### Query Current Data
```sql
SELECT * FROM bronze.mcdonalds_sales_bronze LIMIT 10;
```

#### Time Travel Query
```sql
SELECT * FROM bronze.mcdonalds_sales_bronze 
FOR SYSTEM_TIME AS OF TIMESTAMP '2026-02-07 10:00:00';
```

#### View Table History
```sql
SELECT * FROM bronze.mcdonalds_sales_bronze$history;
```

#### View Snapshots
```sql
SELECT * FROM bronze.mcdonalds_sales_bronze$snapshots;
```

#### CDC Pattern - Get Latest Records
```sql
SELECT 
  JSON_EXTRACT_SCALAR(after, '$.id') as id,
  JSON_EXTRACT_SCALAR(after, '$.product') as product,
  JSON_EXTRACT_SCALAR(after, '$.amount') as amount
FROM bronze.mcdonalds_sales_bronze
WHERE op IN ('c', 'r', 'u')  -- create, read, update
```

#### Filter Deleted Records
```sql
SELECT * FROM bronze.mcdonalds_sales_bronze
WHERE op = 'd'  -- delete operations
```

## Maintenance

### Drop and Recreate
```bash
python drop_databases.py
python create_databases.py
cd bronze
python create_all_tables.py
```

### Optimize Tables (Compaction)
```sql
OPTIMIZE bronze.mcdonalds_sales_bronze REWRITE DATA USING BIN_PACK;
```

### Vacuum Old Snapshots
```sql
VACUUM bronze.mcdonalds_sales_bronze;
```

## Data Flow
1. Kafka → S3 (raw JSON)
2. S3 → Bronze Iceberg (CDC format)
3. Bronze → Silver (cleaned, parsed JSON)
4. Silver → Gold (aggregated, business metrics)

## S3 Locations
- Raw: `s3://s33ding-kafka-output/mcdonalds_<topic>/`
- Bronze: `s3://s33ding-kafka-output/db_bronze/mcdonalds_<topic>/`

## Tips
- Bronze tables store CDC metadata - don't delete `op`, `ts_ms` fields
- Use `after` field for current state, `before` for previous state
- `record_hash` helps identify duplicate records
- Iceberg handles small files automatically with compaction
