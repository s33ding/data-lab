CREATE TABLE mcdonalds_employees (
  payload string
)
LOCATION 's3://s33ding-kafka-output/db_bronze/mcdonalds_employees/'
TBLPROPERTIES ('table_type'='ICEBERG');
