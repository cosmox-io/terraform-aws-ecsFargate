# ecs.tf

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name
}

data "template_file" "fasal_web_app_production" {
  template = file(var.template_path)
  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
    root_url       = aws_alb.main.dns_name
    mongo_url      = var.mongo_url
    mail_url       = var.mail_url
    expose_port    = var.expose_port
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "fasal-web-app-production-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.fasal_web_app_production.rendered
}

resource "aws_ecs_service" "main" {
  name            = "fasal-web-app-production-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "fasal_web_app_production"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]
}