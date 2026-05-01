import boto3
import time
import pandas as pd
import io

def query_athena_to_df(query, database, output_location, region_name='us-east-1'):
    client = boto3.client('athena', region_name=region_name)
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': output_location}
    )
    query_execution_id = response['QueryExecutionId']
    
    while True:
        status = client.get_query_execution(QueryExecutionId=query_execution_id)
        state = status['QueryExecution']['Status']['State']
        if state in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            break
        time.sleep(1)
    
    if state != 'SUCCEEDED':
        raise Exception(f"Query failed or was cancelled: {state}")
    
    result_file = f"{output_location}{query_execution_id}.csv"
    parsed = boto3.session.Session().resource('s3')
    bucket_name = result_file.split('/')[2]
    key = '/'.join(result_file.split('/')[3:])
    obj = parsed.Object(bucket_name, key)
    data = obj.get()['Body'].read().decode('utf-8')
    
    return pd.read_csv(io.StringIO(data))

database = "bronze"
output_location = "s3://s33ding-kafka-output/athena-results/"
region_name = "us-east-1"

# Test 1: Query current data
print("=== Current Data ===")
df = query_athena_to_df(
    "SELECT * FROM bronze.mcdonalds_sales LIMIT 5;",
    database, output_location, region_name
)
print(df)

# Test 2: View snapshots
print("\n=== Snapshots ===")
snapshots = query_athena_to_df(
    'SELECT * FROM "bronze"."mcdonalds_sales$snapshots";',
    database, output_location, region_name
)
print(snapshots)

# Test 3: View history
print("\n=== History ===")
history = query_athena_to_df(
    'SELECT * FROM "bronze"."mcdonalds_sales$history";',
    database, output_location, region_name
)
print(history)

# Test 4: View files
print("\n=== Files ===")
files = query_athena_to_df(
    'SELECT file_path, file_size_in_bytes FROM "bronze"."mcdonalds_sales$files" LIMIT 5;',
    database, output_location, region_name
)
print(files)
