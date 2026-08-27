resource "aws_ecs_cluster" "application_cluster" {
  name = "image-recognition-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "application_task" {
  family                   = "image-recognition-task-${var.environment}"
  network_mode             = "awsvpc"
  memory                   = 3072
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "image-recognition-container"
      image = var.ami_uri

      essential = true

      portMappings = [
        {
          containerPort = var.application_port
          hostPort      = var.application_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.region_name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      environment = [
        {
          name  = "S3_BUCKET_NAME"
          value = var.bucket_name
        },
        {
          name  = "DYNAMODB_TABLE_NAME"
          value = var.dynamodb_name
        },
        {
          name  = "AWS_REGION"
          value = var.region_name
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "image-recognition-ecs-service-sg-${var.environment}"
  description = "Security group for ECS Service"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_service_all_inbound" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "Allow inbound traffic to ECS service"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "ecs_service_all_outbound" {
  security_group_id = aws_security_group.ecs_service_sg.id

  description = "Allow outbound traffic from ECS service"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_ecs_service" "application_service" {
  name            = "image-recognition-service-${var.environment}"
  cluster         = aws_ecs_cluster.application_cluster.id
  task_definition = aws_ecs_task_definition.application_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.subnet_ids

    security_groups = [
      aws_security_group.ecs_service_sg.id
    ]
  }

  desired_count = 2

  load_balancer {
    target_group_arn = aws_lb_target_group.application_target_group.arn
    container_name   = "image-recognition-container"
    container_port   = var.application_port
  }
}