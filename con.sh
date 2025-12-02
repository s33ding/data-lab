#!/bin/bash
cd iac
IP=$(terraform output -raw kafka_instance_public_ip)
ssh -i ../fedora-main-kafka.pem ec2-user@$IP
