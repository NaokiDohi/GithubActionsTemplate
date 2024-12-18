# クラスター定義
resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-${var.env}-ecs-cluster"

  tags = {
    Name        = "${var.service_name}-${var.env}-ecs-cluster"
    Terraform   = "true"
    Environment = var.env
  }
}

# サービス定義
resource "aws_ecs_service" "this" {
  name    = "${var.service_name}-${var.env}-ecs-service"
  cluster = aws_ecs_cluster.this.id
  # ARNではダメ
  # https://github.com/hashicorp/terraform-provider-aws/issues/13931
  # task_definition = aws_ecs_task_definition.this.family
  # task_definition = aws_ecs_task_definition.this.arn
  task_definition = data.aws_ecs_task_definition.this.arn
  # タスク定義が更新された場合、自動で再デプロイを行う設定
  force_new_deployment = false

  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.this.id]
  }

  # ALB との紐付け
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = "80"
  }

  # lifecycle {
  #   ignore_changes = [
  #     desired_count,
  #     # task_definition
  #   ]
  # }

  tags = {
    Name        = "${var.service_name}-${var.env}-ecs-service"
    Terraform   = "true"
    Environment = var.env
  }

  depends_on = [
    aws_ecs_cluster.this,
    aws_ecs_task_definition.this
  ]
}

# タスク定義
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.env}-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name  = var.service_name
      image = "${var.ecr_url}"
      secrets = [
        for k, v in var.ssm_parameters : {
          name      = k
          valueFrom = data.aws_ssm_parameter.list[k].arn
        }
      ]
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-region : "ap-northeast-1",
          awslogs-stream-prefix : var.service_name,
          awslogs-group : "/ecs/${var.service_name}/${var.env}"
        }

      }
      portMappings = [
        {
          containerPort = 80
        }
      ]
    }
  ])
  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn
  track_latest       = false

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  tags = {
    Name        = "${var.service_name}-${var.env}-task-definition"
    Terraform   = "true"
    Environment = var.env
  }

  depends_on = [
    aws_ecs_cluster.this
  ]
}


resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.service_name}/${var.env}"
}
