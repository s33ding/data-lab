-- Create views to flatten Debezium CDC format

-- View for ifood_orders with only the 'after' state (current data)
CREATE OR REPLACE VIEW ifood_db.v_ifood_orders AS
SELECT 
    after.order_id,
    after.restaurant_name,
    after.customer_id,
    from_unixtime(after.order_date / 1000000000) as order_date,
    after.delivery_address,
    after.city,
    after.region,
    CAST(from_base64(after.total_amount) AS DOUBLE) as total_amount,
    CAST(from_base64(after.delivery_fee) AS DOUBLE) as delivery_fee,
    after.payment_method,
    after.order_status,
    from_unixtime(after.created_at / 1000000000) as created_at,
    op as operation_type,
    from_unixtime(ts_ms / 1000) as event_timestamp
FROM ifood_db.ifood_orders
WHERE after IS NOT NULL;

-- View for ifood_order_items with only the 'after' state
CREATE OR REPLACE VIEW ifood_db.v_ifood_order_items AS
SELECT 
    after.item_id,
    after.order_id,
    after.product_name,
    after.category,
    after.quantity,
    CAST(from_base64(after.unit_price) AS DOUBLE) as unit_price,
    CAST(from_base64(after.total_amount) AS DOUBLE) as total_amount,
    from_unixtime(after.created_at / 1000000000) as created_at,
    op as operation_type,
    from_unixtime(ts_ms / 1000) as event_timestamp
FROM ifood_db.ifood_order_items
WHERE after IS NOT NULL;
