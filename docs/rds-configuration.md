# RDS PostgreSQL Configuration for Debezium CDC

## Current Status
- **RDS Instance**: `rds-prod`
- **Engine**: PostgreSQL 17.4
- **Status**: Modifying (applying parameter group changes)
- **Parameter Group**: `postgres17-logical-replication`

## Changes Applied

### 1. Parameter Group Creation
```bash
aws rds create-db-parameter-group \
  --db-parameter-group-family postgres17 \
  --description "PostgreSQL 17 with logical replication enabled" \
  --db-parameter-group-name postgres17-logical-replication \
  --region us-east-1
```

### 2. Logical Replication Enabled
```bash
aws rds modify-db-parameter-group \
  --db-parameter-group-name postgres17-logical-replication \
  --parameters "ParameterName=rds.logical_replication,ParameterValue=1,ApplyMethod=pending-reboot" \
  --region us-east-1
```

### 3. Parameter Group Applied to Instance
```bash
aws rds modify-db-instance \
  --db-instance-identifier rds-prod \
  --db-parameter-group-name postgres17-logical-replication \
  --region us-east-1
```

## Parameter Details

### Key Parameters for CDC
- `rds.logical_replication`: `1` (enabled)
- `max_wal_senders`: `35` (default)
- `wal_keep_size`: `2048` MB
- `max_logical_replication_workers`: Auto-configured

### Before vs After
| Parameter | Before | After |
|-----------|--------|-------|
| Parameter Group | `default.postgres17` | `postgres17-logical-replication` |
| Logical Replication | Disabled | Enabled |
| WAL Level | replica | logical (via rds.logical_replication) |

## Monitoring Progress

### Check Instance Status
```bash
aws rds describe-db-instances \
  --db-instance-identifier rds-prod \
  --region us-east-1 \
  --query "DBInstances[0].{Status:DBInstanceStatus,ParameterGroup:DBParameterGroups[0].DBParameterGroupName,ApplyStatus:DBParameterGroups[0].ParameterApplyStatus}"
```

### Expected Status Progression
1. `modifying` - Parameter group being applied
2. `rebooting` - Instance restarting (if required)
3. `available` - Ready for CDC connections

## Post-Reboot Verification

### 1. Connect to Database
```bash
# Get credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value --secret-id rds-master --region us-east-1 --query SecretString --output text)
DB_HOST=$(echo $SECRET | jq -r '.host')
DB_USERNAME=$(echo $SECRET | jq -r '.username')

psql -h $DB_HOST -U $DB_USERNAME -d iesb
```

### 2. Verify Logical Replication
```sql
-- Check if logical replication is enabled
SHOW rds.logical_replication;

-- Should return: on

-- Check replication slots capability
SELECT * FROM pg_replication_slots;

-- Check WAL level (should show 'logical')
SHOW wal_level;
```

### 3. Test Debezium Connection
```bash
cd /home/roberto/Github/kafka-poc-ec2/local
./configure-debezium.sh
```

## Troubleshooting

### If Reboot Required
```bash
# Wait for status to be 'available', then:
aws rds reboot-db-instance \
  --db-instance-identifier rds-prod \
  --region us-east-1
```

### If Connection Issues
- Check security group allows port 5432
- Verify endpoint from RDS console or Secrets Manager
- Confirm credentials in Secrets Manager

### If CDC Still Fails
- Verify `rds.logical_replication = on`
- Check PostgreSQL logs in RDS console
- Ensure user has replication privileges
