import boto3
import time

client = boto3.client('athena', region_name='us-east-1')

def run_query(sql_file, description):
    with open(sql_file, 'r') as f:
        query = f.read()
    
    print(f"Running {description}...")
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
            print(f"{description} - Status: {status}")
            if status == 'FAILED':
                print(f"Error: {result['QueryExecution']['Status'].get('StateChangeReason', '')}")
            break
        time.sleep(2)
    
    return status == 'SUCCEEDED'

# Pipeline steps
steps = [
    ('mcdonalds_sales_raw.sql', 'Creating raw table'),
    ('mcdonalds_sales_bronze.sql', 'Creating bronze table'),
    ('raw_to_bronze_transform.sql', 'Transforming raw to bronze')
]

print("Starting CDC to Bronze pipeline...")
for sql_file, description in steps:
    if not run_query(sql_file, description):
        print(f"Pipeline failed at: {description}")
        break
else:
    print("Pipeline completed successfully!")
