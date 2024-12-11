resource "aws_alb" "alb" {
    count = length(local.servicos_com_alb)

    name               = replace(local.servicos_com_alb[count.index].name, "_", "-")
    internal           = try(local.servicos_com_alb[count.index].load_balancers.internal, try(!local.servicos_com_alb[count.index].public_ip, true))
    load_balancer_type = try(local.servicos_com_alb[count.index].load_balancers.type, "application")
    subnets            = try(local.servicos_com_alb[count.index].load_balancers.subnet_ids, local.servicos_com_alb[count.index].subnet_ids)
    security_groups    = try(local.servicos_com_alb[count.index].load_balancers.type, "application") == "application" ? try(local.servicos_com_alb[count.index].load_balancers.security_group_ids, local.servicos_com_alb[count.index].security_group_ids, [aws_security_group.ecs_security_groups[index(local.servicos_com_sg_interno, local.servicos_com_alb[count.index])].id]) : null
    idle_timeout       = try(local.servicos_com_alb[count.index].load_balancers.idle_timeout, 60)
}

resource "aws_alb_target_group" "alb" {
    count = length(local.servicos_com_alb)

    name                 = replace(local.servicos_com_alb[count.index].name, "_", "-")
    vpc_id               = var.vpc_id
    protocol             = try(local.servicos_com_alb[count.index].load_balancers.type, "application") == "application" ? "HTTP" : "TCP"
    port                 = try(local.servicos_com_alb[count.index].load_balancers.target_port, local.servicos_com_alb[count.index].load_balancers.port, local.servicos_com_alb[count.index].ports[0])
    deregistration_delay = 30
    target_type          = "ip"

    dynamic health_check {
        for_each = try(local.servicos_com_alb[count.index].load_balancers.type, "application") == "application" ? [true] : []
        content {
            enabled = try(local.servicos_com_alb[count.index].load_balancers.health_check.enabled , true)
            healthy_threshold = try(local.servicos_com_alb[count.index].load_balancers.health_check.healthy_threshold , null)
            interval = try(local.servicos_com_alb[count.index].load_balancers.health_check.interval, null)
            matcher = try(local.servicos_com_alb[count.index].load_balancers.health_check.matcher, "200-399")
            path = try(local.servicos_com_alb[count.index].load_balancers.health_check.path, "/")
            port = try(local.servicos_com_alb[count.index].load_balancers.health_check.port, local.servicos_com_alb[count.index].load_balancers.target_port, local.servicos_com_alb[count.index].load_balancers.port, local.servicos_com_alb[count.index].ports[0])
            protocol = "HTTP"
            timeout = try(local.servicos_com_alb[count.index].load_balancers.health_check.timeout, null)
            unhealthy_threshold = try(local.servicos_com_alb[count.index].load_balancers.health_check.unhealthy_threshold, null)
        }
    }

    tags = merge(
        var.tags,
        {
            Name = "target group ${local.servicos_com_alb[count.index].name}"
        },
    )
}

resource "aws_alb_listener" "alb" {
    count = length(local.servicos_com_alb)

    load_balancer_arn = aws_alb.alb[count.index].arn
    port              = can(local.servicos_com_alb[count.index].load_balancers.certificate) ? 443 : try(local.servicos_com_alb[count.index].load_balancers.port, local.servicos_com_alb[count.index].ports[0])

    protocol = try(local.servicos_com_alb[count.index].load_balancers.type, "application") == "application" ? can(local.servicos_com_alb[count.index].load_balancers.certificate) ? "HTTPS" : "HTTP" : "TCP"

    certificate_arn = try(local.servicos_com_alb[count.index].load_balancers.certificate, null)

    ssl_policy = can(local.servicos_com_alb[count.index].load_balancers.certificate) ? try(local.servicos_com_alb[count.index].load_balancers.certificate_policy, "ELBSecurityPolicy-2016-08") : null

    default_action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.alb[count.index].arn
    }
}

resource "aws_alb_listener" "alb_http_to_https" {
    count = length(local.servicos_com_https_no_alb)

    load_balancer_arn = aws_alb.alb[index(local.servicos_com_alb, local.servicos_com_https_no_alb[count.index])].arn
    port              = 80

    protocol = "HTTP"

    default_action {
        type = "redirect"

        redirect {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
        }
    }
}