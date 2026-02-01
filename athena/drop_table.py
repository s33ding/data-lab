import boto3
import time

client = boto3.client('athena', region_name='us-east-1')

response = client.start_query_execution(
    QueryString='DROP TABLE IF EXISTS mcdonalds_sales_iceberg;',
    ResultConfiguration={'OutputLocation': 's3://s33ding-kafka-output/athena-results/'},
    WorkGroup='primary'
)

query_id = response['QueryExecutionId']
print(f"Query execution ID: {query_id}")

while True:
    result = client.get_query_execution(QueryExecutionId=query_id)
    status = result['QueryExecution']['Status']['State']
    if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
        print(f"Final status: {status}")
        break
    time.sleep(2)
