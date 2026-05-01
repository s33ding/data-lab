# Athena Data Pipeline

## Structure
```
athena/
├── bronze/
│   ├── sales/          - McDonald's sales tables
│   ├── inventory/      - McDonald's inventory tables
│   └── employees/      - McDonald's employees tables
├── silver/             - Cleaned/processed data layer  
└── pipeline/           - ETL scripts and transformations
```

## Usage

### Create Bronze Tables
```bash
cd bronze
python create_all_tables.py
```

### Check Tables
```bash
python check_tables.py
```

### Query Data
```bash
python apply.py query_bronze.sql
```
