resource "aws_ecr_repository" "barnone-backend" {
  name                 = "barnone-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecs_cluster" "barnone-backend" {
  name = "barnone-backend"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }
}

resource "aws_ecs_task_definition" "barnone-backend-task-def" {
  family                   = "barnone"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "barnone-backend-ecs"
      image     = "barnone-backend"
      cpu       = 10
      memory    = 512
      essential = true
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
}

resource "aws_ecs_task_definition" "barnone" {
}

resource "aws_ecs_service" "barnone-backend-ecs" {
  name            = "barnone-backend-ecs"
  cluster         = aws_ecs_cluster.barnone-backend.id
  task_definition = aws_ecs_task_definition.barnone-backend-task-def.arn
  desired_count   = 3
  //iam_role        = aws_iam_role.foo.arn
  //depends_on      = [aws_iam_role_policy.foo]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}

