resource "aws_ecr_repository" "ecr_repository" {
    count = length(local.servicos_com_repositorio)

    name                 = local.servicos_com_repositorio[count.index].name
    image_tag_mutability = "MUTABLE"

    image_scanning_configuration {
        scan_on_push = terraform.workspace == "development"
    }

    tags = merge({
            Name = "${local.servicos_com_repositorio[count.index].name} - ecr_repository"
        },
        var.tags
    )
}

resource "aws_ecr_lifecycle_policy" "ecr_repository_lifecycle_policy" {
    count = length(local.servicos_com_repositorio)

    repository = aws_ecr_repository.ecr_repository[count.index].name

    policy = file("${path.module}/policy/lifecycle_policy.json")
}