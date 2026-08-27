resource "aws_security_group" "ecr_dkr_endpoint_sg" {
  name        = "ecr-dkr-endpoint-sg-${var.environment}"
  description = "Security group for ECR DKR VPC endpoint"
  vpc_id      = aws_vpc.environment_vpc.id
}

resource "aws_security_group" "ecr_api_endpoint_sg" {
  name        = "ecr-api-endpoint-sg-${var.environment}"
  description = "Security group for ECR API VPC endpoint"
  vpc_id      = aws_vpc.environment_vpc.id
}

resource "aws_security_group" "logs_endpoint_sg" {
  name        = "logs-endpoint-sg-${var.environment}"
  description = "Security group for CloudWatch Logs VPC endpoint"
  vpc_id      = aws_vpc.environment_vpc.id
}


# ECR DKR

resource "aws_vpc_security_group_ingress_rule" "ecr_dkr_endpoint_https_a" {
  security_group_id = aws_security_group.ecr_dkr_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[0].cidr_block
  description       = "Allow HTTPS from public subnet A"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecr_dkr_endpoint_https_b" {
  security_group_id = aws_security_group.ecr_dkr_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[1].cidr_block
  description       = "Allow HTTPS from public subnet B"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


# ECR API

resource "aws_vpc_security_group_ingress_rule" "ecr_api_endpoint_https_a" {
  security_group_id = aws_security_group.ecr_api_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[0].cidr_block
  description       = "Allow HTTPS from public subnet A"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ecr_api_endpoint_https_b" {
  security_group_id = aws_security_group.ecr_api_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[1].cidr_block
  description       = "Allow HTTPS from public subnet B"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


# CloudWatch Logs

resource "aws_vpc_security_group_ingress_rule" "logs_endpoint_https_a" {
  security_group_id = aws_security_group.logs_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[0].cidr_block
  description       = "Allow HTTPS from public subnet A"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "logs_endpoint_https_b" {
  security_group_id = aws_security_group.logs_endpoint_sg.id
  cidr_ipv4         = aws_subnet.public[1].cidr_block
  description       = "Allow HTTPS from public subnet B"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}


# Interface VPC Endpoints

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.environment_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = aws_subnet.public[*].id

  security_group_ids = [
    aws_security_group.ecr_dkr_endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.environment_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = aws_subnet.public[*].id

  security_group_ids = [
    aws_security_group.ecr_api_endpoint_sg.id
  ]
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.environment_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.logs"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = aws_subnet.public[*].id

  security_group_ids = [
    aws_security_group.logs_endpoint_sg.id
  ]
}


# Gateway VPC Endpoints

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.environment_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id
  ]
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.environment_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.public.id
  ]
}