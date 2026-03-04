#!/usr/bin/env python3

import boto3
import sys
from datetime import datetime

def list_clusters(eks):
    clusters = eks.list_clusters()['clusters']
    if not clusters:
        print("No clusters found")
        sys.exit(1)
    print("\n=== Available Clusters ===")
    for i, cluster in enumerate(clusters, 1):
        print(f"{i}. {cluster}")
    choice = int(input("\nSelect cluster: ")) - 1
    return clusters[choice]

def list_nodegroups(eks, cluster):
    nodegroups = eks.list_nodegroups(clusterName=cluster)['nodegroups']
    if not nodegroups:
        print("No nodegroups found")
        sys.exit(1)
    print("\n=== Available Node Groups ===")
    for i, ng in enumerate(nodegroups, 1):
        ng_info = eks.describe_nodegroup(clusterName=cluster, nodegroupName=ng)['nodegroup']
        sc = ng_info['scalingConfig']
        status = ng_info['status']
        instance_types = ', '.join(ng_info.get('instanceTypes', ['N/A']))
        print(f"{i}. {ng}")
        print(f"   Status: {status} | Instances: {instance_types}")
        print(f"   Current: min={sc['minSize']}, max={sc['maxSize']}, desired={sc['desiredSize']}")
    choice = int(input("\nSelect nodegroup: ")) - 1
    return nodegroups[choice]

def get_status(eks, cluster, nodegroup):
    ng = eks.describe_nodegroup(clusterName=cluster, nodegroupName=nodegroup)['nodegroup']
    sc = ng['scalingConfig']
    print(f"\n=== Current Configuration ===")
    print(f"Cluster: {cluster}")
    print(f"NodeGroup: {nodegroup}")
    print(f"Status: {ng['status']}")
    print(f"Min Size: {sc['minSize']}")
    print(f"Max Size: {sc['maxSize']}")
    print(f"Desired Size: {sc['desiredSize']}")
    print(f"Instance Types: {', '.join(ng.get('instanceTypes', ['N/A']))}")
    if 'health' in ng:
        print(f"Health Issues: {len(ng['health'].get('issues', []))}")
    return sc

def scale(eks, cluster, nodegroup, min_size, max_size, desired):
    print(f"\n=== Scaling Operation ===")
    print(f"Target: min={min_size}, max={max_size}, desired={desired}")
    confirm = input("Confirm? (yes/no): ")
    if confirm.lower() != 'yes':
        print("Cancelled")
        return
    
    response = eks.update_nodegroup_config(
        clusterName=cluster,
        nodegroupName=nodegroup,
        scalingConfig={'minSize': min_size, 'maxSize': max_size, 'desiredSize': desired}
    )
    print(f"✓ Update initiated (ID: {response['update']['id']})")
    print(f"  Status: {response['update']['status']}")
    print(f"  Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

region = input("AWS Region [us-east-1]: ") or "us-east-1"
eks = boto3.client('eks', region_name=region)

cluster = list_clusters(eks)
nodegroup = list_nodegroups(eks, cluster)
current = get_status(eks, cluster, nodegroup)

print("\n=== Actions ===")
print("1. Scale up (min=2, max=5, desired=3)")
print("2. Scale down (min=0, max=1, desired=0)")
print("3. Custom scaling")
print("4. Set min size only")
print("5. Set max size only")
print("6. Set desired size only")
print("7. Exit")

action = input("\nChoose action: ")

if action == "1":
    scale(eks, cluster, nodegroup, 2, 5, 3)
elif action == "2":
    scale(eks, cluster, nodegroup, 0, 1, 0)
elif action == "3":
    min_size = int(input(f"Min size [{current['minSize']}]: ") or current['minSize'])
    max_size = int(input(f"Max size [{current['maxSize']}]: ") or current['maxSize'])
    desired = int(input(f"Desired size [{current['desiredSize']}]: ") or current['desiredSize'])
    scale(eks, cluster, nodegroup, min_size, max_size, desired)
elif action == "4":
    min_size = int(input(f"Min size [{current['minSize']}]: ") or current['minSize'])
    scale(eks, cluster, nodegroup, min_size, current['maxSize'], current['desiredSize'])
elif action == "5":
    max_size = int(input(f"Max size [{current['maxSize']}]: ") or current['maxSize'])
    scale(eks, cluster, nodegroup, current['minSize'], max_size, current['desiredSize'])
elif action == "6":
    desired = int(input(f"Desired size [{current['desiredSize']}]: ") or current['desiredSize'])
    scale(eks, cluster, nodegroup, current['minSize'], current['maxSize'], desired)
else:
    print("Exiting")
