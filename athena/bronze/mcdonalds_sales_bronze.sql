CREATE TABLE mcdonalds_sales_bronze (
  op string,
  ts_ms bigint,
  before string,
  after string,
  record_hash string
)
LOCATION 's3://s33ding-kafka-output/db_bronze/mcdonalds_sales/'
TBLPROPERTIES (
  'table_type'='ICEBERG'
);
