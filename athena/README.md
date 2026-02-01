# Athena Data Pipeline

## Structure
- `bronze/` - Raw data ingestion layer
- `silver/` - Cleaned/processed data layer  
- `pipeline/` - ETL scripts and transformations
- `check.py` - Table verification
- `apply.py` - Query execution
- `drop_table.py` - Cleanup utilities

## Usage
1. Create bronze: `cd bronze && python create_bronze_table.py`
2. Create silver: `cd silver && python create_table.py`
3. Run pipeline: `cd pipeline && python cdc_bronze_pipeline.py`
4. Check tables: `python check.py`
5. Query data: `python apply.py`
