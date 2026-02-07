#!/usr/bin/env python3
import subprocess
import sys
import json

SG_ID = "sg-0bf9875af00971cc2"
REGION = "sa-east-1"

def run(cmd, capture=True):
    result = subprocess.run(cmd, shell=True, capture_output=capture, text=True)
    return result.stdout.strip() if capture else result.returncode

def get_current_ip():
    ipv4 = run("curl -s -4 ifconfig.me")
    ipv6 = run("curl -s -6 ifconfig.me 2>/dev/null || echo ''")
    return ipv4, ipv6

def get_existing_rules(port):
    ipv4_rules = run(f"aws ec2 describe-security-groups --group-ids {SG_ID} --region {REGION} "
                     f"--query 'SecurityGroups[0].IpPermissions[?FromPort==`{port}`].IpRanges[].CidrIp' --output text")
    ipv6_rules = run(f"aws ec2 describe-security-groups --group-ids {SG_ID} --region {REGION} "
                     f"--query 'SecurityGroups[0].IpPermissions[?FromPort==`{port}`].Ipv6Ranges[].CidrIpv6' --output text")
    return ipv4_rules.split(), ipv6_rules.split()

def revoke_rule(port, cidr, is_ipv6=False):
    run(f"aws ec2 revoke-security-group-ingress --group-id {SG_ID} --protocol tcp "
        f"--port {port} --cidr {cidr} --region {REGION} 2>/dev/null", capture=False)

def authorize_rule(port, cidr):
    run(f"aws ec2 authorize-security-group-ingress --group-id {SG_ID} --protocol tcp "
        f"--port {port} --cidr {cidr} --region {REGION}", capture=False)

print("🔒 Updating Security Group to allow only your current IP...")

ipv4, ipv6 = get_current_ip()
print(f"📍 Current IPv4: {ipv4}")
if ipv6:
    print(f"📍 Current IPv6: {ipv6}")

print("🗑️ Removing old rules...")
for port in [80, 443]:
    ipv4_rules, ipv6_rules = get_existing_rules(port)
    for cidr in ipv4_rules:
        if cidr:
            print(f"  Removing IPv4 rule: {cidr} on port {port}")
            revoke_rule(port, cidr)
    for cidr in ipv6_rules:
        if cidr:
            print(f"  Removing IPv6 rule: {cidr} on port {port}")
            revoke_rule(port, cidr, is_ipv6=True)

print("✅ Adding rules for current IP...")
for port in [80, 443]:
    print(f"  Adding IPv4 rule: {ipv4}/32 on port {port}")
    authorize_rule(port, f"{ipv4}/32")
    if ipv6:
        print(f"  Adding IPv6 rule: {ipv6}/128 on port {port}")
        authorize_rule(port, f"{ipv6}/128")

print("\n✅ Security group updated successfully!")
print(f"🔒 Only your current IP can access the ingress:")
print(f"   IPv4: {ipv4}")
if ipv6:
    print(f"   IPv6: {ipv6}")
