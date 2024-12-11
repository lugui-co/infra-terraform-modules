resource "aws_service_discovery_private_dns_namespace" "discovery_service" {
    count = length(local.servicos_com_discovery)

    name        = "${local.servicos_com_discovery[count.index].name}.local"
    description = "internal dns to contact the container"
    vpc         = var.vpc_id

    tags = merge({
            Name = "discovery_service - ${local.servicos_com_discovery[count.index].name}"
        },
        var.tags
    )
}

resource "aws_service_discovery_service" "discovery_service" {
    count = length(local.servicos_com_discovery)

    name = local.servicos_com_discovery[count.index].name

    dns_config {
        namespace_id = aws_service_discovery_private_dns_namespace.discovery_service[count.index].id

        routing_policy = "MULTIVALUE"

        dns_records {
            ttl  = 10
            type = try(var.services[count.index].network_mode, "awsvpc") != "awsvpc" ? "SRV" : "A"
        }
    }
}