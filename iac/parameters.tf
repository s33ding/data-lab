resource "aws_ssm_parameter" "kafka_test_ec2_instance_id" {
  name  = "/kafka-poc/test/ec2-instance-id"
  type  = "String"
  value = aws_instance.kafka_instance.id
  description = "EC2 instance ID for Kafka testing"
}

resource "aws_ssm_parameter" "kafka_test_rds_endpoint" {
  name  = "/kafka-poc/test/rds-endpoint"
  type  = "String"
  value = data.aws_db_instance.existing_rds.endpoint
  description = "RDS endpoint for connectivity testing"
}

resource "aws_ssm_parameter" "kafka_test_secret_name" {
  name  = "/kafka-poc/test/secret-name"
  type  = "String"
  value = "rds-master"
  description = "Secrets Manager secret name for testing"
}

resource "aws_ssm_parameter" "kafka_test_region" {
  name  = "/kafka-poc/test/region"
  type  = "String"
  value = var.aws_region
  description = "AWS region for testing"
}

resource "aws_ssm_parameter" "kafka_test_kafka_port" {
  name  = "/kafka-poc/test/kafka-port"
  type  = "String"
  value = "9092"
  description = "Kafka port for connectivity testing"
}

resource "aws_ssm_parameter" "kafka_test_connect_port" {
  name  = "/kafka-poc/test/connect-port"
  type  = "String"
  value = "8083"
  description = "Kafka Connect port for testing"
}
