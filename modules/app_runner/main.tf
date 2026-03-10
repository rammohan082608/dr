# ECR Access Role (For App Runner to pull the image)
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.name_prefix}-apprunner-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "build.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role = aws_iam_role.apprunner_ecr_access.name
  # This provides the necessary permissions to pull images from ECR
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance Role (For the running container to access AWS services like CloudWatch)
resource "aws_iam_role" "apprunner_instance" {
  name = "${var.name_prefix}-apprunner-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "tasks.apprunner.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_instance_policy" {
  role = aws_iam_role.apprunner_instance.name
  # Allow logging and general execution
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess" # Adjust to least privilege
}

# App Runner Service
resource "aws_apprunner_service" "mock_client_service" {
  service_name = "${var.name_prefix}-mock-client"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
    image_repository {
      image_identifier      = var.server_ecr_image
      image_repository_type = "ECR"
      image_configuration {
        port = "8080"
      }
    }
  }

  instance_configuration {
    cpu               = 256
    memory            = 512
    instance_role_arn = aws_iam_role.apprunner_instance.arn
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/health"
    interval = 20
  }
}
