#!/bin/bash

echo "Setting up RDS Storage Monitor..."

# Install dependencies
pip3 install -r requirements.txt

echo "Starting RDS Storage Monitor for rds-prod instance..."
echo "The graph will update every 30 seconds"
echo "Press Ctrl+C to stop monitoring"

# Run the monitor
python3 rds_storage_monitor.py
