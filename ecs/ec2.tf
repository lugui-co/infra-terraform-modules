resource "aws_iam_policy" "ecs_ec2_instance_policy" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name        = "${var.cluster_name}_ecs_ec2_instance_policy"
    path        = "/"
    description = "IAM policy para a ec2 orquestrada pelo ecs"

    policy = file("${path.module}/policy/ecs_ec2_instance_policy.json")
}

resource "aws_iam_role" "ecs_ec2_instance_role" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name               = "${var.cluster_name}_ecs_ec2_instance_role"
    assume_role_policy = file("${path.module}/policy/ecs_ec2_instance_role.json")

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_instance_role"
        },
        var.tags
    )
}

resource "aws_iam_role_policy_attachment" "ecs_instance_attachment" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    role       = aws_iam_role.ecs_ec2_instance_role[count.index].name
    policy_arn = aws_iam_policy.ecs_ec2_instance_policy[count.index].arn
}

resource "aws_iam_policy" "ecs_ec2_autoscaling_group_policy" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name        = "${var.cluster_name}_ecs_ec2_autoscaling_group_policy"
    path        = "/"
    description = "IAM policy for autoscaling group to publish on sns"

    policy = templatefile("${path.module}/policy/ecs_ec2_autoscaling_group_policy.json", {
        SNS_TOPIC = aws_sns_topic.scale_down[count.index].arn
    })
}

resource "aws_iam_role" "ecs_ec2_autoscaling_role" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name               = "${var.cluster_name}_ecs_ec2_autoscaling_role"
    assume_role_policy = file("${path.module}/policy/ecs_ec2_autoscaling_role.json")

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_autoscaling_role"
        },
        var.tags
    )
}

resource "aws_iam_role_policy_attachment" "autoscaling_group_attachment" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    role       = aws_iam_role.ecs_ec2_autoscaling_role[count.index].name
    policy_arn = aws_iam_policy.ecs_ec2_autoscaling_group_policy[count.index].arn
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name = "${var.cluster_name}_ecs_ec2_instance_profile"
    role = aws_iam_role.ecs_ec2_instance_role[count.index].name

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_instance_profile"
        },
        var.tags
    )
}

resource "aws_launch_template" "ecs_ec2_launch_template" {
    count = length(local.servicos_na_ec2)

    name_prefix          = "${local.servicos_na_ec2[count.index].name}_ecs_ec2_launch_template"
    image_id             = try(local.servicos_na_ec2[count.index].ec2.ami, "ami-040d909ea4e56f8f3")

    instance_type        = local.servicos_na_ec2[count.index].ec2.instance_type

    iam_instance_profile {
        name = aws_iam_instance_profile.ecs_instance_profile[0].name
    }

    user_data            = try(local.servicos_na_ec2[count.index].ec2.user_data, base64encode(templatefile("${path.module}/ecs_ec2_user_data.sh", {
        CLUSTER_NAME = aws_ecs_cluster.ecs_cluster.name
        PLACEMENT_TAG = local.servicos_na_ec2[count.index].name
    })))

    monitoring {
        enabled = true
    }

    ebs_optimized = try(local.servicos_na_ec2[count.index].ec2.ebs_optimized, true)

    metadata_options {
        http_endpoint = try(local.servicos_na_ec2[count.index].ec2.http_endpoint, "enabled")
        http_tokens = try(local.servicos_na_ec2[count.index].ec2.http_tokens, "required")
    }

    network_interfaces {
        associate_public_ip_address = try(var.services[count.index].public_ip, false)
        security_groups = try(local.servicos_na_ec2[count.index].security_group_ids, aws_security_group.ecs_security_groups[index(local.servicos_com_sg_interno, local.servicos_na_ec2[count.index])].id)
        delete_on_termination = true
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "ecs_ec2_autoscaling_group" {
    count = length(local.servicos_na_ec2)

    name                      = "${local.servicos_na_ec2[count.index].name}_ecs_ec2_autoscaling_group"
    vpc_zone_identifier       = local.servicos_na_ec2[count.index].subnet_ids

    desired_capacity          = try(local.servicos_na_ec2[count.index].ec2.desired_capacity, 1)
    min_size                  = try(local.servicos_na_ec2[count.index].ec2.min_size, 1)
    max_size                  = try(local.servicos_na_ec2[count.index].ec2.max_size, 1)

    health_check_grace_period = 5
    health_check_type         = "EC2"

    launch_template {
        id      = aws_launch_template.ecs_ec2_launch_template[count.index].id
    }

    tag {
        key   = "Name"
        value = "${local.servicos_na_ec2[count.index].name}_ecs_ec2_autoscaling_group"
        propagate_at_launch = true
    }

    lifecycle {
        create_before_destroy = true

        ignore_changes = [
            desired_capacity
        ]
    }
}

resource "aws_autoscaling_lifecycle_hook" "ecs_ec2_autoscaling_group" {
    count = length(local.servicos_na_ec2)

    name                   = "${local.servicos_na_ec2[count.index].name}_ecs_ec2_autoscaling_group"
    autoscaling_group_name = aws_autoscaling_group.ecs_ec2_autoscaling_group[count.index].name
    default_result         = "CONTINUE"
    heartbeat_timeout      = 60
    lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"

    notification_metadata = aws_ecs_cluster.ecs_cluster.name

    notification_target_arn = aws_sns_topic.scale_down[0].arn

    role_arn                = aws_iam_role.ecs_ec2_autoscaling_role[0].arn
}