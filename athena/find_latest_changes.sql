-- Find records with the most recent hash changes
SELECT record_hash, ts_ms, after
FROM mcdonalds_sales_iceberg 
WHERE record_hash IN (
  SELECT record_hash 
  FROM mcdonalds_sales_iceberg 
  GROUP BY record_hash 
  HAVING MAX(ts_ms) = ts_ms
)
ORDER BY ts_ms DESC;
