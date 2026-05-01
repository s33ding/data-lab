CREATE TABLE mcdonalds_sales (
  payload string
)
LOCATION 's3://s33ding-kafka-output/db_bronze/mcdonalds_sales/'
TBLPROPERTIES ('table_type'='ICEBERG');
