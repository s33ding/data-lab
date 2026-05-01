# Iceberg ACID Operations Guide

## Checking ACID Operations

Iceberg automatically provides metadata tables for each table using the `$` suffix notation.

### Available Metadata Tables

For any Iceberg table, you can query:

```sql
-- Snapshots (transactions/ACID operations)
SELECT * FROM bronze."mcdonalds_sales$snapshots";

-- History
SELECT * FROM bronze."mcdonalds_sales$history";

-- Files
SELECT * FROM bronze."mcdonalds_sales$files";

-- Manifests
SELECT * FROM bronze."mcdonalds_sales$manifests";

-- Partitions
SELECT * FROM bronze."mcdonalds_sales$partitions";
```

### Using the Metadata Script

Run the existing script to analyze all tables:

```bash
python analyze_metadata.py
```

This will show:
- **Snapshots** - Each transaction creates a snapshot (Atomicity)
- **History** - Timeline of changes (Durability)
- **Files** - Data file details
- **Manifests** - Metadata tracking

### Creating Unified Views (Optional)

Create views to see metadata across all tables:

```sql
-- All snapshots across tables
CREATE OR REPLACE VIEW bronze.all_snapshots AS
SELECT 'mcdonalds_sales' as table_name, * FROM bronze."mcdonalds_sales$snapshots"
UNION ALL
SELECT 'mcdonalds_inventory' as table_name, * FROM bronze."mcdonalds_inventory$snapshots"
UNION ALL
SELECT 'mcdonalds_employees' as table_name, * FROM bronze."mcdonalds_employees$snapshots";

-- All history across tables
CREATE OR REPLACE VIEW bronze.all_history AS
SELECT 'mcdonalds_sales' as table_name, * FROM bronze."mcdonalds_sales$history"
UNION ALL
SELECT 'mcdonalds_inventory' as table_name, * FROM bronze."mcdonalds_inventory$history"
UNION ALL
SELECT 'mcdonalds_employees' as table_name, * FROM bronze."mcdonalds_employees$history";
```

### Understanding ACID in Iceberg

- **Atomicity**: Each snapshot represents an atomic transaction
- **Consistency**: Schema evolution is tracked in metadata
- **Isolation**: Snapshot isolation prevents dirty reads
- **Durability**: All changes are persisted in S3 metadata files

### Key Metadata Columns

**$snapshots**:
- `snapshot_id`: Unique transaction ID
- `committed_at`: Transaction timestamp
- `operation`: Type (append, overwrite, delete)

**$history**:
- `made_current_at`: When snapshot became current
- `snapshot_id`: Reference to snapshot
- `is_current_ancestor`: Part of current lineage

**$files**:
- `file_path`: S3 location
- `record_count`: Number of records
- `file_size_in_bytes`: File size
