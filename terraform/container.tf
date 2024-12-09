
# Security Group for ECS Task
resource "aws_security_group" "metabase_container_sg" {
  name        = "container-sg"
  description = "Allow HTTP/HTTPS access to the container"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Öffentlich zugänglich
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster Definition
resource "aws_ecs_cluster" "metabase_cluster" {
  name = "metabase-cluster"
}

# resource "aws_ecs_service" "metabase_service" {
#   name              = "metabase-service"
#   depends_on        = [aws_ecs_cluster.metabase_cluster]
#   cluster           = aws_ecs_cluster.metabase_cluster.id
#   task_definition   = aws_ecs_task_definition.metabase_task.arn
#   desired_count     = 1
#   launch_type       = "FARGATE"
#   network_configuration {
#     subnets         = [aws_subnet.public_subnet_container.id] # Container läuft im öffentlichen Subnetz
#     security_groups = [aws_security_group.metabase_container_sg.id]
#   }
# }



