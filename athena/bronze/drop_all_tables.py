#!/usr/bin/env python3
import boto3
import time

athena = boto3.client('athena', region_name='us-east-1')
OUTPUT = 's3://s33ding-kafka-output/athena-results/'
DATABASE = 'bronze'

tables = ['mcdonalds_sales', 'mcdonalds_inventory', 'mcdonalds_employees']

for table in tables:
    print(f"\n🗑️  Dropping {table}...")
    response = athena.start_query_execution(
        QueryString=f'DROP TABLE IF EXISTS {table}',
        QueryExecutionContext={'Database': DATABASE},
        ResultConfiguration={'OutputLocation': OUTPUT}
    )
    
    query_id = response['QueryExecutionId']
    while True:
        result = athena.get_query_execution(QueryExecutionId=query_id)
        status = result['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            if status == 'SUCCEEDED':
                print(f"✅ {table} dropped")
            else:
                print(f"❌ Failed: {result['QueryExecution']['Status'].get('StateChangeReason', '')}")
            break
        time.sleep(1)

print("\n🎉 All tables dropped!")
