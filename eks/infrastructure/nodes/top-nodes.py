#!/usr/bin/env python3

import subprocess
import json

nodes = json.loads(subprocess.check_output(['kubectl', 'get', 'nodes', '-o', 'json']))
top = subprocess.check_output(['kubectl', 'top', 'nodes', '--no-headers']).decode().strip().split('\n')

top_data = {}
for line in top:
    parts = line.split()
    top_data[parts[0]] = {'cpu': parts[1], 'cpu%': parts[2], 'mem': parts[3], 'mem%': parts[4]}

print(f"{'NODE':<45} {'NODEGROUP':<20} {'TYPE':<12} {'CAP':<8} {'STATUS':<10} {'CPU':<10} {'CPU%':<8} {'MEM':<10} {'MEM%':<8}")
print("-" * 140)

for node in sorted(nodes['items'], key=lambda x: x['metadata']['labels'].get('eks.amazonaws.com/nodegroup', '')):
    name = node['metadata']['name']
    labels = node['metadata']['labels']
    ng = labels.get('eks.amazonaws.com/nodegroup', 'N/A')
    itype = labels.get('node.kubernetes.io/instance-type', 'N/A')
    cap = labels.get('eks.amazonaws.com/capacityType', 'N/A')
    
    status = 'Ready'
    if node['spec'].get('unschedulable'):
        status = 'Draining'
    for cond in node['status']['conditions']:
        if cond['type'] == 'Ready' and cond['status'] != 'True':
            status = 'NotReady'
    
    if name in top_data:
        t = top_data[name]
        print(f"{name:<45} {ng:<20} {itype:<12} {cap:<8} {status:<10} {t['cpu']:<10} {t['cpu%']:<8} {t['mem']:<10} {t['mem%']:<8}")
