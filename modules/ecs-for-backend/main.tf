resource "aws_vpc" "barnone-vpc" {
  tags = {
    "Name" = "barnone-vpc"
  }

  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "aws_subnet" "barnone-subnet-public1-a" {
  vpc_id                  = aws_vpc.barnone-vpc.id
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = true

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    "Name" = "barnone-subnet-public1-a"
  }
}

resource "aws_subnet" "barnone-subnet-public2-a" {
  vpc_id                  = aws_vpc.barnone-vpc.id
  cidr_block              = "10.0.16.0/20"
  map_public_ip_on_launch = true

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    "Name" = "barnone-subnet-public2-us-east-1b"
  }
}


resource "aws_security_group" "barnone-backend" {
  vpc_id = aws_vpc.barnone-vpc.id

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
    Name = "barnone-backend"
  }

  depends_on = [aws_vpc.barnone-vpc]
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id              = aws_vpc.barnone-vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"

  security_group_ids = [
    aws_security_group.barnone-backend.id,
  ]

  subnet_ids = [
    aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-a.id
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id              = aws_vpc.barnone-vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"

  security_group_ids = [
    aws_security_group.barnone-backend.id,
  ]

  subnet_ids = [
    aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-a.id
  ]
}


resource "aws_ecr_repository" "barnone-backend" {
  name                 = "barnone-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "barnone-repo-policy" {
  repository = aws_ecr_repository.barnone-backend.name
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
  name = "barnone-backend"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

resource "aws_iam_role" "barnone-backend-task-execution-role" {
  name               = "barnone-backend-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.barnone-backend-task-execution-role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

resource "aws_cloudwatch_log_group" "barnone-backend-group" {
  name = "barnone-backend-ecs"

  tags = {
    Environment = "test"
    Application = "BarNone"
  }
}

resource "aws_ecs_task_definition" "barnone-backend-task-def" {
  family                   = "barnone"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.barnone-backend-task-execution-role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name  = "barnone-backend-ecs"
      #image = "169002939622.dkr.ecr.us-east-1.amazonaws.com/barnone-backend"
      image     = "jpzimmerman/barnone-backend"
      cpu       = 10
      memory    = 512
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "barnone-backend-ecs",
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
    Name = "barnone-backend-task-def"
  }

  depends_on = [aws_cloudwatch_log_group.barnone-backend-group]
}

resource "aws_ecs_service" "barnone-backend-ecs" {
  name             = "barnone-backend-ecs"
  cluster          = aws_ecs_cluster.barnone-backend.id
  launch_type      = "FARGATE"
  platform_version = "1.3.0"
  task_definition  = aws_ecs_task_definition.barnone-backend-task-def.arn
  desired_count    = 1
  network_configuration {
    security_groups  = [aws_security_group.barnone-backend.id]
    subnets          = [aws_subnet.barnone-subnet-public1-a.id, aws_subnet.barnone-subnet-public2-a.id]
    assign_public_ip = true
  }

  depends_on = [aws_security_group.barnone-backend, aws_ecs_task_definition.barnone-backend-task-def, aws_vpc_endpoint.ecr_api_endpoint, aws_vpc_endpoint.ecr_dkr_endpoint]
}

