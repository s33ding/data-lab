import boto3
import time

client = boto3.client('athena', region_name='us-east-1')

def create_db(db_name):
    response = client.start_query_execution(
        QueryString=f'CREATE DATABASE IF NOT EXISTS {db_name}',
        ResultConfiguration={'OutputLocation': 's3://s33ding-kafka-output/athena-results/'},
        WorkGroup='primary'
    )
    
    query_id = response['QueryExecutionId']
    
    while True:
        result = client.get_query_execution(QueryExecutionId=query_id)
        status = result['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            print(f"Database '{db_name}': {status}")
            break
        time.sleep(1)

if __name__ == '__main__':
    for db in ['bronze', 'silver', 'gold']:
        create_db(db)
