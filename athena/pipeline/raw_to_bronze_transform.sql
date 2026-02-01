INSERT INTO mcdonalds_sales_bronze
SELECT 
    json_extract_scalar(payload, '$.op') as op,
    CAST(json_extract_scalar(payload, '$.ts_ms') AS bigint) as ts_ms,
    json_extract_scalar(payload, '$.before') as before,
    json_extract_scalar(payload, '$.after') as after,
    to_hex(md5(to_utf8(payload))) as record_hash
FROM mcdonalds_sales_raw
WHERE payload IS NOT NULL;
