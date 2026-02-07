#!/usr/bin/env python3
import subprocess

def run_test(script):
    result = subprocess.run(f"./{script}", shell=True)
    return result.returncode == 0

if __name__ == "__main__":
    print("🧪 Running PostgreSQL Integration Tests...\n")
    
    tests = [
        "check-connection.py",
        "check-mcdonalds.py",
        "random_insert.py",
        "query-mcdonalds.py"
    ]
    
    for test in tests:
        if not run_test(test):
            print(f"❌ Test {test} failed!")
            exit(1)
        print()
    
    print("✅ All PostgreSQL tests completed!")
