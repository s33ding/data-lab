#!/usr/bin/env python3
import boto3
import time

athena = boto3.client('athena', region_name='us-east-1')
OUTPUT = 's3://s33ding-kafka-output/athena-results/'
DATABASE = 'bronze'

response = athena.start_query_execution(
    QueryString='SHOW TABLES',
    QueryExecutionContext={'Database': DATABASE},
    ResultConfiguration={'OutputLocation': OUTPUT}
)

query_id = response['QueryExecutionId']

while True:
    result = athena.get_query_execution(QueryExecutionId=query_id)
    status = result['QueryExecution']['Status']['State']
    if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
        if status == 'SUCCEEDED':
            results = athena.get_query_results(QueryExecutionId=query_id)
            print("Tables in bronze database:")
            for row in results['ResultSet']['Rows'][1:]:
                print(f"  - {row['Data'][0].get('VarCharValue', '')}")
        break
    time.sleep(1)
