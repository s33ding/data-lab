import boto3

client = boto3.client('athena', region_name='us-east-1')

response = client.get_query_execution(
    QueryExecutionId='d1d34d00-da5c-4d91-b32e-9aadda80c997'
)

print(f"Status: {response['QueryExecution']['Status']['State']}")
if 'StateChangeReason' in response['QueryExecution']['Status']:
    print(f"Reason: {response['QueryExecution']['Status']['StateChangeReason']}")
