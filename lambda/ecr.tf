resource "aws_ecr_repository" "ecr_repository" {
    count = var.runtime == "docker" && var.image_uri == null ? 1 : 0

    name                 = var.function_name
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = terraform.workspace == "development"
    }

    tags = merge({
            Name = "${var.function_name} - ecr_repository"
        },
        var.tags
    )
}

resource "aws_ecr_lifecycle_policy" "ecr_repository_lifecycle_policy" {
    count = var.runtime == "docker" && var.image_uri == null ? 1 : 0

    repository = aws_ecr_repository.ecr_repository[count.index].name

    policy = file("${path.module}/lifecycle_policy.json")
}

resource "null_resource" "ecr_builder" {
    count = var.runtime == "docker" && var.image_uri == null ? 1 : 0

    provisioner "local-exec" {
        command = templatefile("${path.module}/build_ecr_image.sh", {
            ECR_REGISTRY_ADDRESS = aws_ecr_repository.ecr_repository[0].repository_url
            AWS_REGION = data.aws_region.region.name
        })
    }
}