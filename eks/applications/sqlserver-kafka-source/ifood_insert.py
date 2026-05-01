#!/usr/bin/env python3
import subprocess
import random
from datetime import datetime, timedelta

# Mock data
restaurants = ['Burger King', 'Pizza Hut', 'Subway', 'KFC', 'Outback', 'Dominos', 'Starbucks']
cities = ['São Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Curitiba', 'Porto Alegre']
regions = ['Southeast', 'South', 'Northeast']
payment_methods = ['Credit Card', 'Debit Card', 'PIX', 'Cash']
statuses = ['Delivered', 'In Transit', 'Preparing', 'Cancelled']

products = {
    'Burgers': [('Whopper Combo', 35.90), ('Big King', 28.50), ('Cheeseburger', 15.00)],
    'Pizza': [('Pepperoni Pizza', 69.90), ('Margherita', 59.90), ('Four Cheese', 74.90)],
    'Sandwiches': [('Italian BMT', 24.00), ('Turkey Breast', 22.00), ('Veggie', 19.00)],
    'Chicken': [('Bucket 10pc', 52.90), ('Wings 8pc', 38.00), ('Tenders', 29.90)],
    'Sides': [('Fries', 10.00), ('Onion Rings', 12.00), ('Coleslaw', 8.90)],
    'Beverages': [('Coca-Cola', 7.00), ('Pepsi', 6.00), ('Orange Juice', 9.00)]
}

sql = """IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'TestDB')
    CREATE DATABASE TestDB;
GO
USE TestDB;
GO
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'kafka')
    EXEC('CREATE SCHEMA kafka');
GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ifood_orders' AND schema_id = SCHEMA_ID('kafka'))
BEGIN
    CREATE TABLE kafka.ifood_orders (
        order_id VARCHAR(50) PRIMARY KEY,
        restaurant_name VARCHAR(100) NOT NULL,
        customer_id VARCHAR(50) NOT NULL,
        order_date DATETIME2 DEFAULT GETDATE(),
        delivery_address VARCHAR(200),
        city VARCHAR(50),
        region VARCHAR(50),
        total_amount DECIMAL(10,2),
        delivery_fee DECIMAL(10,2),
        payment_method VARCHAR(50),
        order_status VARCHAR(50),
        created_at DATETIME2 DEFAULT GETDATE()
    )
END;
GO
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ifood_order_items' AND schema_id = SCHEMA_ID('kafka'))
BEGIN
    CREATE TABLE kafka.ifood_order_items (
        item_id INT IDENTITY(1,1) PRIMARY KEY,
        order_id VARCHAR(50) NOT NULL,
        product_name VARCHAR(100) NOT NULL,
        category VARCHAR(50),
        quantity INT,
        unit_price DECIMAL(10,2),
        total_amount DECIMAL(10,2),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (order_id) REFERENCES kafka.ifood_orders(order_id)
    )
END;
GO
"""

for i in range(1, 21):
    order_id = f'IFD{int(datetime.now().timestamp())}{i:03d}'
    restaurant = random.choice(restaurants)
    customer_id = f'CUST{random.randint(1, 100):03d}'
    order_date = (datetime.now() - timedelta(hours=random.randint(0, 48))).strftime('%Y-%m-%d %H:%M:%S')
    city = random.choice(cities)
    region = random.choice(regions)
    delivery_fee = round(random.uniform(4.0, 10.0), 2)
    payment_method = random.choice(payment_methods)
    status = random.choice(statuses)
    
    num_items = random.randint(1, 4)
    order_total = 0
    items_sql = []
    
    for _ in range(num_items):
        category = random.choice(list(products.keys()))
        product_name, unit_price = random.choice(products[category])
        quantity = random.randint(1, 3)
        total_amount = round(unit_price * quantity, 2)
        order_total += total_amount
        items_sql.append(f"INSERT INTO kafka.ifood_order_items (order_id, product_name, category, quantity, unit_price, total_amount) VALUES ('{order_id}', '{product_name}', '{category}', {quantity}, {unit_price}, {total_amount});")
    
    sql += f"INSERT INTO kafka.ifood_orders (order_id, restaurant_name, customer_id, order_date, delivery_address, city, region, total_amount, delivery_fee, payment_method, order_status) VALUES ('{order_id}', '{restaurant}', '{customer_id}', '{order_date}', 'Address {i}', '{city}', '{region}', {order_total}, {delivery_fee}, '{payment_method}', '{status}');\n"
    sql += '\n'.join(items_sql) + '\nGO\n'

sql += """
EXEC sys.sp_cdc_enable_db;
GO
EXEC sys.sp_cdc_enable_table @source_schema = 'kafka', @source_name = 'ifood_orders', @role_name = NULL;
GO
EXEC sys.sp_cdc_enable_table @source_schema = 'kafka', @source_name = 'ifood_order_items', @role_name = NULL;
GO
"""

# Get SQL Server pod
pod = subprocess.check_output(['kubectl', 'get', 'pod', '-n', 'funasa', '-l', 'app=sqlserver', '-o', 'jsonpath={.items[0].metadata.name}']).decode().strip()

# Execute SQL (without -d flag since we create the DB in the script)
subprocess.run(['kubectl', 'exec', '-i', '-n', 'funasa', pod, '--', '/opt/mssql-tools18/bin/sqlcmd', '-S', 'localhost', '-U', 'sa', '-P', 'YourStrong@Passw0rd', '-C'], input=sql.encode())

print("iFood data inserted successfully")
