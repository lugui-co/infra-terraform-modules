resource "aws_iam_role" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name = "${var.cluster_name}_scale_down_lambda_role"
    description = "role com para setar o ecs como drain durante scale down"

    assume_role_policy = file("${path.module}/policy/scale_down_lambda_role.json")

    tags = merge({
            Name = "${var.cluster_name}_scale_down_lambda_role"
        },
        var.tags
    )
}

resource "aws_iam_policy" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name        = "${var.cluster_name}_scale_down_lambda_policy"
    path        = "/"
    description = "politica com para setar o ecs como drain durante scale down"

    policy = templatefile("${path.module}/policy/lambda_policy_drain_before_terminate.json", {
        LOG_ARN = aws_cloudwatch_log_group.scale_down[count.index].arn
        ECS_CLUSTER_NAME = aws_ecs_cluster.ecs_cluster.name
        ECS_CLUSTER_ARN = aws_ecs_cluster.ecs_cluster.arn
        AUTOSCALING_GROUP = jsonencode(aws_autoscaling_group.ecs_ec2_autoscaling_group.*.arn)
        ACCOUNT_ID = data.aws_caller_identity.current.account_id
        REGION = data.aws_region.region.name
    })
}

resource "aws_iam_role_policy_attachment" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    role       = aws_iam_role.scale_down[count.index].name
    policy_arn = aws_iam_policy.scale_down[count.index].arn
}

resource "aws_cloudwatch_log_group" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name              = "/aws/lambda/${aws_lambda_function.scale_down[count.index].function_name}"
    retention_in_days = 180

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_scale_down"
        },
        var.tags
    )
}

data "archive_file" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    type             = "zip"
    source_file      = "${path.module}/drain_before_terminate.py"
    output_path      = "${path.module}/tmp/drain_before_terminate.zip"
}

resource "aws_lambda_function" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    timeout = 50

    function_name = "${var.cluster_name}_ecs_ec2_scale_down"

    filename = "${path.module}/drain_before_terminate.zip"

    source_code_hash = data.archive_file.scale_down[count.index].output_base64sha256

    handler = "drain_before_terminate.lambda_handler"
    runtime = "python3.8"

    role = aws_iam_role.scale_down[count.index].arn

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_scale_down"
        },
        var.tags
    )
}

resource "aws_sns_topic" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    name = "${var.cluster_name}_ecs_ec2_scale_down"

    tags = merge({
            Name = "${var.cluster_name}_ecs_ec2_scale_down"
        },
        var.tags
    )
}

resource "aws_sns_topic_subscription" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    topic_arn = aws_sns_topic.scale_down[count.index].arn
    endpoint  = aws_lambda_function.scale_down[count.index].arn
    protocol  = "lambda"
}

resource "aws_lambda_permission" "scale_down" {
    count = length(local.servicos_na_ec2) > 0 ? 1 : 0

    statement_id = "${var.cluster_name}_AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    principal = "sns.amazonaws.com"
    function_name = aws_lambda_function.scale_down[count.index].arn
    source_arn = aws_sns_topic.scale_down[count.index].arn
}