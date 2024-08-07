resource "aws_security_group" "barnone-frontend" {
  vpc_id = data.aws_vpc.barnone.id

  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "barnone-frontend"
  }
}

# resource "aws_vpc_endpoint" "ecr_api_endpoint" {
#   vpc_id              = aws_vpc.barnone-vpc.id
#   service_name        = "com.amazonaws.us-east-1.ecr.api"
#   private_dns_enabled = true
#   vpc_endpoint_type   = "Interface"

#   security_group_ids = [
#     aws_security_group.barnone-frontend.id,
#   ]

#   subnet_ids = [
#     aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-a.id
#   ]
# }

# resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
#   vpc_id              = aws_vpc.barnone-vpc.id
#   service_name        = "com.amazonaws.us-east-1.ecr.dkr"
#   private_dns_enabled = true
#   vpc_endpoint_type   = "Interface"

#   security_group_ids = [
#     aws_security_group.barnone-frontend.id,
#   ]

#   subnet_ids = [
#     aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-a.id
#   ]
# }


resource "aws_ecr_repository" "barnone-frontend" {
  name                 = "barnone-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "barnone-repo-policy" {
  repository = aws_ecr_repository.barnone-frontend.name
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


resource "aws_ecs_cluster" "barnone-frontend" {
  name = "barnone-frontend"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

resource "aws_iam_role" "barnone-frontend-task-execution-role" {
  name               = "barnone-frontend-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.barnone-frontend-task-execution-role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

resource "aws_cloudwatch_log_group" "barnone-frontend-group" {
  name = "barnone-frontend-ecs"

  tags = {
    Environment = "test"
    Application = "BarNone"
  }
}

resource "aws_ecs_task_definition" "barnone-frontend-task-def" {
  family                   = "barnone"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.barnone-frontend-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "barnone-frontend-ecs"
      image     = "jpzimmerman/barnone-frontend"
      cpu       = 10
      memory    = 512
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "barnone-frontend-ecs",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
        {
          containerPort = 4200
          hostPort      = 4200
        }
      ]
    }
  ])

  tags = {
    Name = "barnone-frontend-task-def"
  }

  depends_on = [aws_cloudwatch_log_group.barnone-frontend-group]
}

resource "aws_ecs_service" "barnone-frontend-ecs" {
  name             = "barnone-frontend-ecs"
  cluster          = aws_ecs_cluster.barnone-frontend.id
  launch_type      = "FARGATE"
  platform_version = "1.3.0"
  task_definition  = aws_ecs_task_definition.barnone-frontend-task-def.arn
  desired_count    = 1
  network_configuration {
    security_groups  = [aws_security_group.barnone-frontend.id]
    subnets          = [data.aws_subnet.barnone-public1-a.id, data.aws_subnet.barnone-public2-b.id]
    assign_public_ip = true
  }

  depends_on = [aws_security_group.barnone-frontend, aws_ecs_task_definition.barnone-frontend-task-def]
}
