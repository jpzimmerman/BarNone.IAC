resource "aws_security_group" "barnone_backend" {
  vpc_id      = data.aws_vpc.barnone.id
  description = "Security group facilitating connection between VPC and ECS cluster for backend"

  ingress {
    description = "Ingress rule between VPC and ECS backend"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Egress rule between VPC and ECS backend"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "barnone-backend"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = data.aws_vpc.barnone.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"

  security_group_ids = [
    aws_security_group.barnone_backend.id,
  ]

  subnet_ids = [
    data.aws_subnet.barnone_public1_a.id, data.aws_subnet.barnone_public2_b.id
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = data.aws_vpc.barnone.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"

  security_group_ids = [
    aws_security_group.barnone_backend.id,
  ]

  subnet_ids = [
    data.aws_subnet.barnone_public1_a.id, data.aws_subnet.barnone_public2_b.id
  ]
}

resource "aws_ecr_repository" "barnone_backend" {
  name                 = "barnone_backend"
  image_tag_mutability = "IMMUTABLE"
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_key.ecr_key.arn
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "barnone_repo_policy" {
  repository = aws_ecr_repository.barnone_backend.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}

resource "aws_ecs_cluster" "barnone-backend" {
  name = "barnone_backend"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.barnone_backend_group.name
      }
    }
  }
}

resource "aws_iam_role" "barnone_backend_task_execution" {
  name               = "barnone_backend_task_execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.barnone_backend_task_execution.name
  policy_arn = data.aws_iam_policy.ecs_task_execution.arn
}

resource "aws_cloudwatch_log_group" "barnone_backend_group" {
  name              = "barnone-backend-ecs"
  retention_in_days = 400

  tags = {
    Environment = "test"
    Application = "BarNone"
  }
}

resource "aws_ecs_task_definition" "barnone_backend_task_def" {
  family                   = "barnone"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.barnone_backend_task_execution.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name                   = "barnone-backend-ecs"
      image                  = "jpzimmerman/barnone-backend"
      cpu                    = 10
      memory                 = 512
      essential              = true
      readonlyRootFilesystem = true
      environment = [
        { "name" : "DB_CONNECTION", "value" : "[SECRET]" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "barnone_backend_ecs",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  tags = {
    Name = "barnone_backend_task_def"
  }

  depends_on = [aws_cloudwatch_log_group.barnone_backend_group]
}

resource "aws_ecs_service" "barnone_backend" {
  name             = "barnone-backend"
  cluster          = aws_ecs_cluster.barnone-backend.id
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  task_definition  = aws_ecs_task_definition.barnone_backend_task_def.arn
  desired_count    = 1
  network_configuration {
    security_groups  = [aws_security_group.barnone_backend.id]
    subnets          = [data.aws_subnet.barnone_public1_a.id, data.aws_subnet.barnone_public2_b.id]
    assign_public_ip = false
  }

  depends_on = [aws_security_group.barnone_backend, aws_ecs_task_definition.barnone_backend_task_def, aws_vpc_endpoint.ecr_api, aws_vpc_endpoint.ecr_dkr]
}
