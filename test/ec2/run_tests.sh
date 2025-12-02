#!/bin/bash
set -e

echo "Running Kafka EC2 Tests..."

# Install requirements
pip install -r requirements.txt

# Update SSH key path in conftest.py
echo "Please update the SSH key path in conftest.py before running tests"

# Run tests with HTML report
pytest -v --html=test_report.html --self-contained-html

echo "Tests completed. Check test_report.html for results."
