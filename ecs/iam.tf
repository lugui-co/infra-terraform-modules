resource "aws_iam_policy" "ecs_task_iam_policy" {
    count = length(var.services)

    name        = "${var.services[count.index].name}-ecs-task-policy"
    path        = "/"
    description = "IAM policy for ecs task"

    policy = templatefile("${path.module}/policy/task_policy.json", {
        LOG_GROUP = aws_cloudwatch_log_group.ecs_cloudwatch_log_group[count.index].arn
        REPOSITORY = can(var.services[count.index].image) ? "" : "${jsonencode({
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "${aws_ecr_repository.ecr_repository[index(local.servicos_com_repositorio, var.services[count.index])].arn}"
        })},"

        KMS = !anytrue([for secret in try(var.services[count.index].secrets, null) != null ? var.services[count.index].secrets : [] : can(secret.kmsKey)]) ? "" : "${jsonencode({
            "Effect": "Allow",
            "Action": "kms:Decrypt",
            "Resource": [for secret in var.services[count.index].secrets : secret.kmsKey if try(secret.kmsKey, null) != null]
        })},"

        PARAMETER_STORE = !anytrue([for secret in try(var.services[count.index].secrets, null) != null ? var.services[count.index].secrets : [] : contains(split(":", secret.valueFrom), "ssm")]) ? "" : "${jsonencode({
            "Effect": "Allow",
            "Action": [
                "ssm:GetParameter",
                "ssm:GetParameters"
            ],
            "Resource": [for secret in var.services[count.index].secrets : secret.valueFrom if contains(split(":", secret.valueFrom), "ssm")]
        })},"

        SCRETS_MANAGER = !anytrue([for secret in try(var.services[count.index].secrets, null) != null ? var.services[count.index].secrets : [] : contains(split(":", secret.valueFrom), "secretsmanager")]) ? "" : "${jsonencode({
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [for secret in var.services[count.index].secrets : secret.valueFrom if contains(split(":", secret.valueFrom), "secretsmanager")]
        })},"

        EFS = !anytrue([for volume in try(var.services[count.index].volumes, []) : try(volume.iam, false) if volume != null]) ? "" : "${jsonencode({
            "Effect": "Allow",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:DescribeMountTargets",
                "elasticfilesystem:DescribeFileSystems"
            ],
            "Resource": [for volume in try(var.services[count.index].volumes, []) : volume.iam if try(volume.iam, null) != null]
        })},"
    })
}

resource "aws_iam_role" "ecs_task_iam_role" {
    count = length(var.services)

    name               = "${var.services[count.index].name}-ecs-task-role"
    assume_role_policy = file("${path.module}/policy/task_role.json")

    tags = merge({
            Name = "${var.services[count.index].name}-ecs-task-role"
        },
        var.tags
    )
}

resource "aws_iam_role_policy_attachment" "ecs_iam_task_policy_attachment" {
    count = length(var.services)

    role       = aws_iam_role.ecs_task_iam_role[count.index].name
    policy_arn = aws_iam_policy.ecs_task_iam_policy[count.index].arn
}

resource "aws_iam_policy" "ecs_container_policy" {
    count = length(var.services)

    name        = "${var.services[count.index].name}-ecs-container-policy"
    path        = "/"
    description = "IAM policy for ecs container"

    policy = can(var.services[count.index].iam_policy) ? var.services[count.index].iam_policy : templatefile("${path.module}/policy/container_policy.json", {
        LOG_GROUP = aws_cloudwatch_log_group.ecs_cloudwatch_log_group[count.index].arn
    })
}

resource "aws_iam_role" "ecs_container_iam_role" {
    count = length(var.services)

    name               = "${var.services[count.index].name}-ecs-container-role"
    assume_role_policy = file("${path.module}/policy/task_role.json")

    tags = merge({
            Name = "${var.services[count.index].name}-ecs-container-role"
        },
        var.tags
    )
}

resource "aws_iam_role_policy_attachment" "ecs_container_attachment" {
    count = length(var.services)

    role       = aws_iam_role.ecs_container_iam_role[count.index].name
    policy_arn = aws_iam_policy.ecs_container_policy[count.index].arn
}