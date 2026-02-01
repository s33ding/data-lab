#!/usr/bin/env python3
import boto3
import json
import psycopg2
from psycopg2.extras import RealDictCursor
import random
from datetime import datetime, timedelta, timedelta
import uuid

def get_db_credentials():
    """Get database credentials from AWS Secrets Manager"""
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId='rds-master')
    return json.loads(response['SecretString'])

def create_connection():
    """Create PostgreSQL connection to cluster"""
    # Connect directly to cluster PostgreSQL
    return psycopg2.connect(
        host='localhost',
        database='testdb',
        user='postgres',
        password='postgres',
        port=5433  # Port forward to cluster
    )

def create_kafka_schema_and_table():
    """Create kafka schema and mcdonalds_sales table"""
    conn = create_connection()
    cursor = conn.cursor()
    
    try:
        # Create kafka schema if not exists
        cursor.execute("CREATE SCHEMA IF NOT EXISTS kafka;")
        
        # Create table
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS kafka.mcdonalds_sales (
            id SERIAL PRIMARY KEY,
            store_id INTEGER NOT NULL,
            store_name VARCHAR(100) NOT NULL,
            transaction_id VARCHAR(50) NOT NULL,
            transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            product_code VARCHAR(20) NOT NULL,
            product_name VARCHAR(100) NOT NULL,
            category VARCHAR(50) NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price DECIMAL(10,2) NOT NULL,
            total_amount DECIMAL(10,2) NOT NULL,
            payment_method VARCHAR(20) NOT NULL,
            customer_type VARCHAR(20) DEFAULT 'regular',
            promotion_code VARCHAR(20),
            region VARCHAR(50) NOT NULL,
            city VARCHAR(50) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        cursor.execute(create_table_sql)
        
        # Create indexes
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_mcdonalds_sales_store_id ON kafka.mcdonalds_sales(store_id);")
        cursor.execute("CREATE INDEX IF NOT EXISTS idx_mcdonalds_sales_date ON kafka.mcdonalds_sales(transaction_date);")
        
        # Enable replica identity for Debezium
        cursor.execute("ALTER TABLE kafka.mcdonalds_sales REPLICA IDENTITY FULL;")
        
        conn.commit()
        print("Table kafka.mcdonalds_sales created successfully!")
        
    except Exception as e:
        print(f"Error creating table: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

def insert_sample_data():
    """Insert sample McDonald's data"""
    products = [
        {"code": "BIG001", "name": "Big Mac", "category": "Burgers", "price": 15.90},
        {"code": "QUA001", "name": "Quarterão", "category": "Burgers", "price": 18.90},
        {"code": "CHE001", "name": "Cheeseburger", "category": "Burgers", "price": 9.90},
        {"code": "NUG001", "name": "McNuggets 10un", "category": "Chicken", "price": 16.90},
        {"code": "FRY001", "name": "Batata Frita M", "category": "Sides", "price": 8.50},
        {"code": "COK001", "name": "Coca-Cola 500ml", "category": "Beverages", "price": 6.90}
    ]
    
    payment_methods = ["credit_card", "debit_card", "pix", "cash"]
    regions = ["Southeast", "Northeast", "South"]
    cities = ["São Paulo", "Rio de Janeiro", "Recife", "Curitiba"]
    
    conn = create_connection()
    cursor = conn.cursor()
    
    try:
        for store_id in range(1, 11):  # 10 stores
            for _ in range(5):  # 5 transactions per store
                product = random.choice(products)
                quantity = random.randint(1, 3)
                
                insert_sql = """
                INSERT INTO kafka.mcdonalds_sales 
                (store_id, store_name, transaction_id, product_code, product_name, 
                 category, quantity, unit_price, total_amount, payment_method, 
                 region, city) 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """
                
                cursor.execute(insert_sql, (
                    store_id,
                    f"McDonald's Store {store_id}",
                    f"TXN{store_id:03d}_{uuid.uuid4().hex[:8]}",
                    product["code"],
                    product["name"],
                    product["category"],
                    quantity,
                    product["price"],
                    round(quantity * product["price"], 2),
                    random.choice(payment_methods),
                    random.choice(regions),
                    random.choice(cities)
                ))
        
        conn.commit()
        print("Sample data inserted successfully!")
        
    except Exception as e:
        print(f"Error inserting data: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    print("Creating McDonald's table and inserting sample data...")
    create_kafka_schema_and_table()
    insert_sample_data()
    print("Setup completed!")
