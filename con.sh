#!/bin/bash
cd iac
INSTANCE_ID=$(terraform output -raw kafka_instance_id)
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region us-east-1 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
ssh -i ../fedora-main-kafka.pem ec2-user@$PUBLIC_IP
