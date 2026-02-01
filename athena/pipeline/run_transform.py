import boto3
import time

client = boto3.client('athena', region_name='us-east-1')

with open('raw_to_bronze_transform.sql', 'r') as f:
    query = f.read()

response = client.start_query_execution(
    QueryString=query,
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
        if status == 'FAILED':
            print(f"Error: {result['QueryExecution']['Status'].get('StateChangeReason', '')}")
        break
    time.sleep(2)
