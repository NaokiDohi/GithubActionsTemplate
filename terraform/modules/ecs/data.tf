data "aws_ecs_task_definition" "this" {
  task_definition = aws_ecs_task_definition.this.family
}
