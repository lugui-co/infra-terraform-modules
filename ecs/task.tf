resource "aws_ecs_task_definition" "ecs_task_definition" {
    count = length(var.services)

    family = var.services[count.index].name

    container_definitions = !can(var.services[count.index].task_definition) ? templatefile("${path.module}/container_definition.json", {
        REPOSITORY_URL = try(var.services[count.index].image, "${aws_ecr_repository.ecr_repository[index(local.servicos_com_repositorio, var.services[count.index])].repository_url}:latest"),
        LOG_GROUP = aws_cloudwatch_log_group.ecs_cloudwatch_log_group[count.index].name,
        REGION = data.aws_region.region.name,
        ENVIRONMENT_VARIABLES = jsonencode(try(var.services[count.index].environment_variables, null))
        SECRETS = jsonencode(try(var.services[count.index].secrets, null) != null ? [for secret in var.services[count.index].secrets : {name: secret.name, valueFrom: secret.valueFrom}] : null)
        ENTRYPOINT = jsonencode(try(var.services[count.index].entryPoint, null))
        COMMAND = jsonencode(try(var.services[count.index].command, null))
        CPU = var.services[count.index].cpu,
        MEMORY = var.services[count.index].memory,
        PORTS = jsonencode(try([for port in try(var.services[count.index].ports, null) : {"containerPort": port,"hostPort": port,"protocol": "tcp"}], null)),
        SERVICE_NAME = var.services[count.index].name,
        PRIVILEGED = can(var.services[count.index].ec2) || try(var.services[count.index].no_fargate, false) ? try(var.services[count.index].security_options.privileged, false) : "null",
        READ_ONLY = try(var.services[count.index].security_options.read_only, true),
        SECURTY_OPTIONS = can(var.services[count.index].ec2) || try(var.services[count.index].no_fargate, false) ? jsonencode(try(var.services[count.index].security_options.docker_security_options, ["no-new-privileges"])) : "null",
        LINUX_PARAMETERS = jsonencode(try(var.services[count.index].security_options.linux_parameters,  {"capabilities": {"drop": ["ALL"]}}))
        RESOURCE_REQUIREMENTS = try(var.services[count.index].resource_requirements, "null")
        VOLUME_MOUNT = jsonencode(try([for index, volume in var.services[count.index].volumes : {"sourceVolume": "${var.services[count.index].name}-volume-${index}", "containerPath": volume.container}], null))
        START_TIME = try(var.services[count.index].start_time, 5)
        STOP_TIME = try(var.services[count.index].stop_time, 5)
    }) : var.services[count.index].task_definition

    execution_role_arn = aws_iam_role.ecs_task_iam_role[count.index].arn

    task_role_arn = aws_iam_role.ecs_container_iam_role[count.index].arn

    memory = var.services[count.index].memory
    cpu = var.services[count.index].cpu

    requires_compatibilities = can(var.services[count.index].ec2) || try(var.services[count.index].no_fargate, false) ? ["EC2"] : ["FARGATE"]

    network_mode = try(var.services[count.index].network_mode, "awsvpc")

    dynamic volume {
        for_each = try(var.services[count.index].volumes, [])

        content {
            name      = "${var.services[count.index].name}-volume-${volume.key}"
            host_path = can(volume.value.efs_id) ? null : volume.value.host

            dynamic efs_volume_configuration {
                for_each = can(volume.value.efs_id) ? [true] : []

                content {
                    file_system_id          = volume.value.efs_id
                    root_directory          = volume.value.host
                    transit_encryption      = "ENABLED"

                    dynamic authorization_config {
                        for_each = can(volume.value.access_point_id) ? [true] : []

                        content {
                            access_point_id = volume.value.access_point_id
                            iam             = try(volume.value.iam, "DISABLED")
                        }
                    }
                }
            }
        }
    }

    dynamic ephemeral_storage {
        for_each = can(var.services[count.index].ephemeral_storage) ? [var.services[count.index].ephemeral_storage] : []

        content {
            size_in_gib = ephemeral_storage.value
        }
    }

    tags = merge({
            Name = "task_role - ${var.services[count.index].name}"
        },
        var.tags
    )
}

resource "aws_ecs_service" "ecs_service" {
    count = length(var.services)

    name            = var.services[count.index].name
    cluster         = aws_ecs_cluster.ecs_cluster.id
    task_definition = aws_ecs_task_definition.ecs_task_definition[count.index].arn

    force_new_deployment = true

    desired_count = can(var.services[count.index].ec2) ? null : 1

    scheduling_strategy = can(var.services[count.index].ec2) ? "DAEMON" : "REPLICA"

    deployment_minimum_healthy_percent = can(var.services[count.index].ec2) ? null : 100
    deployment_maximum_percent = can(var.services[count.index].ec2) ? null : 200

    health_check_grace_period_seconds = try(var.services[count.index].grace_period, var.services[count.index].start_time, 0)

    dynamic capacity_provider_strategy {
        for_each = can(var.services[count.index].ec2) ? [] : can(var.services[count.index].no_fargate) ? [] : [true]
        content {
            capacity_provider = try(var.services[count.index].no_spot, false) ? "FARGATE" : "FARGATE_SPOT"
            weight            = 100
        }
    }

    dynamic network_configuration {
        for_each = try(var.services[count.index].network_mode, "awsvpc") == "awsvpc" ? [true] : []
        content{
            subnets = var.services[count.index].subnet_ids
            security_groups = try(var.services[count.index].security_group_ids, [aws_security_group.ecs_security_groups[index(local.servicos_com_sg_interno, var.services[count.index])].id])
            assign_public_ip = can(var.services[count.index].ec2) ? false : try(var.services[count.index].public_ip, false)
        }
    }

    dynamic load_balancer {
        for_each = can(var.services[count.index].load_balancers) && try(var.services[count.index].load_balancers, false) != false && try(var.services[count.index].load_balancers, false) != null ? [true] : []
        content {
            target_group_arn = aws_alb_target_group.alb[index(local.servicos_com_alb, var.services[count.index])].arn
            container_name   = var.services[count.index].name
            container_port   = try(var.services[count.index].load_balancers.target_port, var.services[count.index].load_balancers.port, var.services[count.index].ports[0])
        }
    }

    dynamic service_registries {
        for_each = can(var.services[count.index].discovery_service) && try(var.services[count.index].discovery_service, false) == true ? [true] : []
        content {
            registry_arn = aws_service_discovery_service.discovery_service[index(local.servicos_com_discovery, var.services[count.index])].arn
            container_port = try(var.services[count.index].network_mode, "awsvpc") == "awsvpc" ? null : try(local.servicos_com_alb[index(local.servicos_com_alb, var.services[count.index])].load_balancers.target_port, local.servicos_com_alb[index(local.servicos_com_alb, var.services[count.index])].load_balancers.port, var.services[count.index].ports[0])
            container_name = try(var.services[count.index].network_mode, "awsvpc") == "awsvpc" ? null : var.services[count.index].name
        }
    }

    dynamic placement_constraints {
        for_each = try([var.services[count.index].ec2], [])
        content {
            type       = "memberOf"
            expression = "attribute:custom.placement_tag == ${var.services[count.index].name}"
        }
    }

    lifecycle {
        ignore_changes = [
            desired_count
        ]
    }
}