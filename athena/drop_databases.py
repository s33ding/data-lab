import boto3
import time

client = boto3.client('athena', region_name='us-east-1')
sts = boto3.client('sts', region_name='us-east-1')

ALLOWED_ACCOUNT = '248189947068'
ALLOWED_USER = 'AIDATTSKGBS6IXJMFYM6P'

def verify_identity():
    identity = sts.get_caller_identity()
    account_id = identity['Account']
    user_id = identity['UserId']
    
    if account_id != ALLOWED_ACCOUNT or user_id != ALLOWED_USER:
        print(f"❌ Unauthorized: Account {account_id}, User {user_id}")
        exit(1)
    print(f"✅ Authorized: {account_id}")

def drop_db(db_name):
    response = client.start_query_execution(
        QueryString=f'DROP DATABASE IF EXISTS {db_name} CASCADE',
        ResultConfiguration={'OutputLocation': 's3://s33ding-kafka-output/athena-results/'},
        WorkGroup='primary'
    )
    
    query_id = response['QueryExecutionId']
    
    while True:
        result = client.get_query_execution(QueryExecutionId=query_id)
        status = result['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            print(f"Drop database '{db_name}': {status}")
            break
        time.sleep(1)

if __name__ == '__main__':
    verify_identity()
    for db in ['bronze', 'silver', 'gold']:
        drop_db(db)
