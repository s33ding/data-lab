# Security Group Management

## Current Setup
- **Security Group ID**: `sg-0bf9875af00971cc2`
- **Name**: `lab-ingress-restricted`
- **Description**: Dedicated security group for lab.dataiesb.com ingress
- **VPC**: `vpc-016e73ac906d31d5c`
- **Region**: `sa-east-1`
- **Associated with**: Load balancer `k8s-lab-labingre-8e083c31c4` (lab-ingress)

## Quick IP Update Commands

### Get Current IP
```bash
# IPv4
curl -s -4 ifconfig.me

# IPv6  
curl -s ifconfig.me
```

### Update Security Group Rules

**Remove old IP (replace OLD_IP with previous IP):**
```bash
# Remove IPv4 HTTP
aws ec2 revoke-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 80 --cidr OLD_IP/32 --region sa-east-1

# Remove IPv4 HTTPS
aws ec2 revoke-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 443 --cidr OLD_IP/32 --region sa-east-1

# Remove IPv6 HTTP
aws ec2 revoke-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 80 --cidr OLD_IPV6/128 --region sa-east-1

# Remove IPv6 HTTPS
aws ec2 revoke-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 443 --cidr OLD_IPV6/128 --region sa-east-1
```

**Add new IP (replace NEW_IP with current IP):**
```bash
# Add IPv4 HTTP
aws ec2 authorize-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 80 --cidr NEW_IP/32 --region sa-east-1

# Add IPv4 HTTPS  
aws ec2 authorize-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 443 --cidr NEW_IP/32 --region sa-east-1

# Add IPv6 HTTP
aws ec2 authorize-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 80 --cidr NEW_IPV6/128 --region sa-east-1

# Add IPv6 HTTPS
aws ec2 authorize-security-group-ingress --group-id sg-0bf9875af00971cc2 --protocol tcp --port 443 --cidr NEW_IPV6/128 --region sa-east-1
```

## Q CLI Commands

Tell Q: "Update security group sg-0bf9875af00971cc2 to allow access from my current IP only"

## Current Allowed IPs
- IPv4: `177.41.82.208/32`
- IPv6: `2804:1b2:1845:e860:94f0:4a6c:9b20:ccf4/128`
