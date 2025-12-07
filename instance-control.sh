#!/bin/bash

cd iac
INSTANCE_ID=$(terraform output -raw kafka_instance_id)
REGION="us-east-1"

case "$1" in
    start)
        aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION
        echo "Starting instance $INSTANCE_ID..."
        ;;
    stop)
        aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
        echo "Stopping instance $INSTANCE_ID..."
        ;;
    status)
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
