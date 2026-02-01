# PostgreSQL Test Scripts

Organized testing scripts for PostgreSQL integration.

## Scripts

- `test-connection.sh` - Test database connectivity
- `query-data.sh` - Query all tables and show counts  
- `insert-test-data.sh` - Insert test data with timestamps
- `run-all-tests.sh` - Run complete test suite

## Usage

```bash
cd scripts/postgres-tests/
./run-all-tests.sh
```

Or run individual tests:
```bash
./test-connection.sh
./insert-test-data.sh
```
