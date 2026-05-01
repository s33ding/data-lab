import boto3
import pandas as pd
import time

client = boto3.client('athena', region_name='us-east-1')

def query_metadata(query, description):
    print(f"\n{'='*60}")
    print(f"📊 {description}")
    print('='*60)
    
    response = client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': 'bronze'},
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
                if len(rows) > 1:
                    columns = [col.get('VarCharValue', '') for col in rows[0]['Data']]
                    data = [[col.get('VarCharValue', '') for col in row['Data']] for row in rows[1:]]
                    df = pd.DataFrame(data, columns=columns)
                    print(df.to_string(index=False))
                else:
                    print("No data found")
            else:
                reason = result['QueryExecution']['Status'].get('StateChangeReason', '')
                if 'ICEBERG_MISSING_METADATA' in reason:
                    print(f"⚠️  Table exists but has no Iceberg metadata (empty table or not yet populated)")
                else:
                    print(f"❌ Query failed: {reason}")
            break
        time.sleep(1)

if __name__ == '__main__':
    tables = ['mcdonalds_sales', 'mcdonalds_inventory', 'mcdonalds_employees']
    
    for table in tables:
        # Snapshots
        query_metadata(
            f'SELECT snapshot_id, committed_at, operation FROM bronze."{table}$snapshots" ORDER BY committed_at DESC LIMIT 5',
            f"{table} - Recent Snapshots"
        )
        
        # History
        query_metadata(
            f'SELECT made_current_at, snapshot_id, is_current_ancestor FROM bronze."{table}$history" ORDER BY made_current_at DESC LIMIT 5',
            f"{table} - History"
        )
        
        # Files
        query_metadata(
            f'SELECT file_path, file_format, record_count, file_size_in_bytes FROM bronze."{table}$files" LIMIT 10',
            f"{table} - Data Files"
        )
        
        # Manifests
        query_metadata(
            f'SELECT path, length, added_snapshot_id FROM bronze."{table}$manifests" LIMIT 5',
            f"{table} - Manifests"
        )
