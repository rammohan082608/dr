resource "aws_ecr_repository" "quanum_hub" {
  name                 = var.quanum_hub_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "strand_middleware" {
  name                 = var.strand_middleware_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
