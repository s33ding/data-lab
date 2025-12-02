output "kafka_instance_id" {
  description = "ID of the Kafka EC2 instance"
  value       = aws_instance.kafka_instance.id
}

output "kafka_instance_private_ip" {
  description = "Private IP of Kafka EC2 instance"
  value       = aws_instance.kafka_instance.private_ip
}

output "kafka_instance_private_dns" {
  description = "Private DNS of Kafka EC2 instance"
  value       = aws_instance.kafka_instance.private_dns
}

output "rds_endpoint" {
  description = "RDS instance endpoint (existing)"
  value       = data.aws_db_instance.existing_rds.endpoint
}

output "vpc_id" {
  description = "VPC ID where both Kafka and RDS are located"
  value       = data.aws_vpc.existing.id
}

output "ssm_connect_command" {
  description = "AWS SSM command to connect to Kafka instance"
  value       = "aws ssm start-session --target ${aws_instance.kafka_instance.id} --region ${var.aws_region}"
}
