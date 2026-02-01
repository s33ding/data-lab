import boto3
import time

client = boto3.client('athena', region_name='us-east-1')

def run_query(sql_file, description):
    with open(sql_file, 'r') as f:
        query = f.read()
    
    print(f"\n=== {description} ===")
    response = client.start_query_execution(
        QueryString=query,
        ResultConfiguration={'OutputLocation': 's3://s33ding-kafka-output/athena-results/'},
        WorkGroup='primary'
    )
    
    query_id = response['QueryExecutionId']
    
    while True:
        result = client.get_query_execution(QueryExecutionId=query_id)
        status = result['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            if status == 'SUCCEEDED':
                # Get results
                results = client.get_query_results(QueryExecutionId=query_id)
                for row in results['ResultSet']['Rows']:
                    print([col.get('VarCharValue', '') for col in row['Data']])
            else:
                print(f"Query failed: {result['QueryExecution']['Status'].get('StateChangeReason', '')}")
            break
        time.sleep(1)

# Check tables
queries = [
    ('query_raw.sql', 'Raw Table Sample'),
    ('query_bronze.sql', 'Bronze Table Sample')
]

for sql_file, description in queries:
    run_query(sql_file, description)
