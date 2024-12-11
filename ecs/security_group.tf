resource "aws_security_group" "ecs_security_groups" {
    count = length(local.servicos_com_sg_interno)

    name        = "${local.servicos_com_sg_interno[count.index].name}-${terraform.workspace}"
    description = "para rodar o ${local.servicos_com_sg_interno[count.index].name} no ecs - criado pelo modulo de tf"
    vpc_id      = var.vpc_id

    dynamic ingress {
        for_each = setsubtract(toset(concat(try(local.servicos_com_sg_interno[count.index].ports, []), [try(local.servicos_com_sg_interno[count.index].load_balancers.health_check.port, null)], [try(local.servicos_com_sg_interno[count.index].load_balancers.target_port, null)], [try(local.servicos_com_sg_interno[count.index].load_balancers.port, null)], [can(local.servicos_com_sg_interno[count.index].load_balancers.certificate) ? 80 : null], [can(local.servicos_com_sg_interno[count.index].load_balancers.certificate) ? 443 : null])), [null])

        content {
            from_port        = ingress.value
            to_port          = ingress.value
            protocol         = "tcp"
            cidr_blocks      = ["0.0.0.0/0"]
        }
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name = "${local.servicos_com_sg_interno[count.index].name}-${terraform.workspace}"
    }
}