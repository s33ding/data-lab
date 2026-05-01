import boto3
import pandas as pd
import time

client = boto3.client('athena', region_name='us-east-1')

def list_databases():
    response = client.start_query_execution(
        QueryString='SHOW DATABASES',
        ResultConfiguration={'OutputLocation': 's3://s33ding-kafka-output/athena-results/'},
        WorkGroup='primary'
    )
    
    query_id = response['QueryExecutionId']
    
    while True:
        result = client.get_query_execution(QueryExecutionId=query_id)
        status = result['QueryExecution']['Status']['State']
        if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
            if status == 'SUCCEEDED':
                results = client.get_query_results(QueryExecutionId=query_id)
                rows = results['ResultSet']['Rows']
                data = [[col.get('VarCharValue', '') for col in row['Data']] for row in rows[1:]]
                return pd.DataFrame(data, columns=['database'])
            break
        time.sleep(1)

if __name__ == '__main__':
    df = list_databases()
    print(df)
