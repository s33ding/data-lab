CREATE TABLE mcdonalds_inventory (
  payload string
)
LOCATION 's3://s33ding-kafka-output/db_bronze/mcdonalds_inventory/'
TBLPROPERTIES ('table_type'='ICEBERG');
