terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Use existing VPC (same as RDS) - READ ONLY
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

# Use existing subnet from RDS VPC - READ ONLY  
data "aws_subnet" "existing" {
  id = var.existing_subnet_id
}

# Use existing RDS instance - READ ONLY
data "aws_db_instance" "existing_rds" {
  db_instance_identifier = var.existing_rds_identifier
}

# Security Group for Kafka (new resource, safe to create)
resource "aws_security_group" "kafka_sg" {
  name_prefix = "kafka-sg"
  vpc_id      = data.aws_vpc.existing.id
  description = "Security group for Kafka instance"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kafka broker"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  ingress {
    description = "Zookeeper"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  ingress {
    description = "Kafka Connect"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kafka-security-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for EC2 with SSM and Secrets Manager access
resource "aws_iam_role" "kafka_ec2_role" {
  name = "kafka-ec2-role"
  description = "IAM role for Kafka EC2 instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "kafka-ec2-role"
  }
}

# Policy for Secrets Manager and S3 access
resource "aws_iam_role_policy" "kafka_secrets_s3_policy" {
  name = "kafka-secrets-s3-policy"
  role = aws_iam_role.kafka_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.rds_secret_name}*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::s33ding-kafka-output",
          "arn:aws:s3:::s33ding-kafka-output/*"
        ]
      }
    ]
  })
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "kafka_ssm_policy" {
  role       = aws_iam_role.kafka_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 bucket for Kafka output
resource "aws_s3_bucket" "kafka_output" {
  bucket = "s33ding-kafka-output"

  tags = {
    Name = "kafka-output-bucket"
    Environment = "development"
    Purpose = "kafka-data-output"
  }
}

# Instance profile
resource "aws_iam_instance_profile" "kafka_profile" {
  name = "kafka-instance-profile"
  role = aws_iam_role.kafka_ec2_role.name

  tags = {
    Name = "kafka-instance-profile"
  }
}

# EBS Volume for Kafka data
resource "aws_ebs_volume" "kafka_data" {
  availability_zone = data.aws_subnet.existing.availability_zone
  size              = 50
  type              = "gp3"

  tags = {
    Name = "kafka-data-volume"
  }
}

# EC2 Instance in existing VPC
resource "aws_instance" "kafka_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.kafka_sg.id]
  subnet_id                   = data.aws_subnet.existing.id
  iam_instance_profile        = aws_iam_instance_profile.kafka_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    rds_secret_name = var.rds_secret_name
    aws_region      = var.aws_region
    kafka_device    = "/dev/xvdf"
  })

  tags = {
    Name = "kafka-instance"
    Environment = "development"
    Purpose = "kafka-debezium"
    Project = "kafka-poc"
    Owner = "roberto"
    AutoStop = "true"
    Component = "kafka-cluster"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Attach EBS volume to EC2 instance
resource "aws_volume_attachment" "kafka_data_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.kafka_data.id
  instance_id = aws_instance.kafka_instance.id
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
