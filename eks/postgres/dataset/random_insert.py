#!/usr/bin/env python3
import boto3
import json
import psycopg2
import random
import uuid
from datetime import datetime

def get_db_credentials():
    client = boto3.client('secretsmanager', region_name='us-east-1')
    response = client.get_secret_value(SecretId='rds-master')
    return json.loads(response['SecretString'])

def random_insert(count=100):
    products = [
        {"code": "BIG001", "name": "Big Mac", "category": "Burgers", "price": 15.90},
        {"code": "QUA001", "name": "Quarterão", "category": "Burgers", "price": 18.90},
        {"code": "CHE001", "name": "Cheeseburger", "category": "Burgers", "price": 9.90},
        {"code": "NUG001", "name": "McNuggets 10un", "category": "Chicken", "price": 16.90},
        {"code": "FRY001", "name": "Batata Frita M", "category": "Sides", "price": 8.50},
        {"code": "COK001", "name": "Coca-Cola 500ml", "category": "Beverages", "price": 6.90}
    ]
    
    payment_methods = ["credit_card", "debit_card", "pix", "cash"]
    regions = ["Southeast", "Northeast", "South", "Center-West", "North"]
    cities = ["São Paulo", "Rio de Janeiro", "Recife", "Curitiba", "Salvador"]
    
    creds = get_db_credentials()
    conn = psycopg2.connect(
        host=creds['host'],
        database=creds['db_name'],
        user=creds['username'],
        password=creds['password'],
        port=5432
    )
    
    cursor = conn.cursor()
    
    for i in range(count):
        store_id = random.randint(1, 1800)
        product = random.choice(products)
        quantity = random.randint(1, 5)
        test_id = str(uuid.uuid4())[:8]
        
        cursor.execute('''
            INSERT INTO kafka.mcdonalds_sales 
            (store_id, store_name, transaction_id, product_code, product_name, 
             category, quantity, unit_price, total_amount, payment_method, region, city) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ''', (
            store_id,
            f"McDonald's Store {store_id}",
            f"TXN_{test_id}",
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
        
        if (i + 1) % 10 == 0:
            print(f"Inserted {i + 1}/{count} records")
    
    conn.commit()
    print(f"Completed: {count} records inserted")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    random_insert()
