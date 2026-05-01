-- Create database
CREATE DATABASE TestDB;
GO

USE TestDB;
GO

-- Create schema
CREATE SCHEMA kafka;
GO

-- Create tables
CREATE TABLE kafka.ifood_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_date DATETIME,
    total_amount DECIMAL(10,2),
    status VARCHAR(50)
);
GO

CREATE TABLE kafka.ifood_order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2)
);
GO

-- Enable CDC on database
EXEC sys.sp_cdc_enable_db;
GO

-- Enable CDC on tables
EXEC sys.sp_cdc_enable_table
    @source_schema = 'kafka',
    @source_name = 'ifood_orders',
    @role_name = NULL;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = 'kafka',
    @source_name = 'ifood_order_items',
    @role_name = NULL;
GO
