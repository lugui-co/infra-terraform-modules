resource "aws_ecs_cluster" "ecs_cluster" {
    name  = var.cluster_name

    setting {
        name = "containerInsights"
        value = var.container_insights ? "enabled" : "disabled"
    }

    tags = merge({
            Name = "ecs_cluster_${var.cluster_name}"
        },
        var.tags
    )
}

resource "aws_cloudwatch_log_group" "ecs_cloudwatch_log_group" {
    count = length(var.services)

    name              = "/aws/ecs/${aws_ecs_cluster.ecs_cluster.name}/${var.services[count.index].name}"
    retention_in_days = 180

    tags = merge({
            Name = "ecs_cloudwatch_log_group_${var.cluster_name}"
        },
        var.tags
    )
}