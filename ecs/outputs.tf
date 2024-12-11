output "cluster_arn" {
    value = aws_ecs_cluster.ecs_cluster.arn
    description = "arn do cluster do ecs"
}

output "service_id" {
    value = aws_ecs_service.ecs_service.*.id
    description = "lista com os ids dos servicos do ecs"
}

output "task_definition_arn" {
    value = aws_ecs_task_definition.ecs_task_definition.*.arn
    description = "lista com os arns das task definitions do ecs"
}

output "repository_arn" {
    value = aws_ecr_repository.ecr_repository.*.arn
    description = "lista com os arns dos repositorios do ecs (eles vao ser criados mesmo que nao sejam usados)"
}

output "repository_id" {
    value = aws_ecr_repository.ecr_repository.*.registry_id
    description = "lista com os ids dos repositorios do ecs (eles vao ser criados mesmo que nao sejam usados)"
}

output "repository_url" {
    value = aws_ecr_repository.ecr_repository.*.repository_url
    description = "lista com as urls dos repositorios do ecs. use para dar push e pull. (eles vao ser criados mesmo que nao sejam usados)"
}

output ecs_task_discovrey_domain {
    value = try([for index, service_name in aws_service_discovery_service.discovery_service.*.name : "${service_name}.${aws_service_discovery_private_dns_namespace.discovery_service[index].name}"], null)
    description = "a lista com os hostnames do descobridor de servicos da rota 53 que forem criados SOMENTE SE voce especificar que eles devem ser criados"
}

output "ecs_task_alb_domain" {
    value = try(aws_alb.alb.*.dns_name, null)
    description = "a lista com os dominios dos load balancers que forem criados SOMENTE SE voce especificar que eles devem ser criados"
}

output "ecs_task_alb_arn" {
    value = try(aws_alb.alb.*.arn, null)
    description = "a lista com os arns dos load balancers que forem criados SOMENTE SE voce especificar que eles devem ser criados"
}

output "ecs_task_alb_listener" {
    value = try(aws_alb_listener.alb_http_to_https.*.arn, null) != null || try(aws_alb_listener.alb.*.arn, null) != null ? concat(try(aws_alb_listener.alb_http_to_https.*.arn, []), try(aws_alb_listener.alb.*.arn, [])) : null
    description = "a lista com os arns dos listenerss dos load balancers que forem criados SOMENTE SE voce criar load balancers"
}

output "ecs_ec2_autoscaling_group_id" {
    value = try(aws_autoscaling_group.ecs_ec2_autoscaling_group.*.id, null)
    description = "a lista com os id dos grupos de autoescala das ec2 que rodam o ecs. use para tunar elas."
}

output "ecs_ec2_autoscaling_group_arn" {
    value = try(aws_autoscaling_group.ecs_ec2_autoscaling_group.*.arn, null)
    description = "a lista com os arns dos grupos de autoescala das ec2 que rodam o ecs. use para tunar elas."
}

output "ecs_security_group_ids" {
    value = aws_security_group.ecs_security_groups.*.id
    description = "ids dos security groups que foram criados para as tasks"
}

output "ecs_security_group_arns" {
    value = aws_security_group.ecs_security_groups.*.arn
    description = "arns dos security groups que foram criados para as tasks"
}

output "ecs_task_iam_role" {
    value = aws_iam_role.ecs_task_iam_role.*.arn
    description = "arns das roles de iam das tasks"
}

output "ecs_container_iam_role" {
    value = aws_iam_role.ecs_container_iam_role.*.arn
    description = "arns das roles de iam dos containeres (nao e a instancia. e o container mesmo)"
}

output "ecs_task_iam_name" {
    value = aws_iam_role.ecs_task_iam_role.*.name
    description = "nomes das roles de iam das tasks"
}

output "ecs_container_iam_name" {
    value = aws_iam_role.ecs_container_iam_role.*.name
    description = "nomes das roles de iam dos containeres (nao e a instancia. e o container mesmo)"
}