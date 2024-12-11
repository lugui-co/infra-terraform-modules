resource "aws_iam_role" "lambda_function_executor" {
    name = "${coalesce(var.iam_prefix, "lambda_function_executor_")}${var.function_name}"
    description = "role do lambda"

    assume_role_policy = coalesce(var.role_file, file("${path.module}/lambda_role.json"))

    tags = merge(
        {
            Name        = "lambda_function_executor_iam_role"
        },
        var.tags
    )
}

resource "aws_iam_policy" "lambda_function_executor" {
    count = fileexists(local.policy_file.file_path) ? 1 : 0

    name        = "${coalesce(var.iam_prefix, "lambda_function_executor_")}external_policy_${var.function_name}"
    path        = "/"
    description = "politica de acesso aos recursos externos do lambda"

    policy = templatefile(local.policy_file.file_path, local.policy_file.arguments)
}

resource "aws_iam_policy" "lambda_function_executor_basic_policy" {
    name        = "${coalesce(var.iam_prefix, "lambda_function_executor_")}log_polcy_${var.function_name}"
    path        = "/"
    description = "politica de acesso aos logs do lambda"

    policy = templatefile("${path.module}/lambda_policy.json", {
        REGION = data.aws_region.region.name
        ACCOUNT_ID = data.aws_caller_identity.account_id.account_id
        FUNC_NAME = var.function_name
    })
}

resource "aws_iam_policy" "lambda_function_executor_vpc_policy" {
    count = length(var.subnet_ids) != 0 && length(var.security_group_ids) != 0 ? 1 : 0

    name        = "${coalesce(var.iam_prefix, "lambda_function_executor_")}vpc_policy_${var.function_name}"
    path        = "/"
    description = "politica de acesso aos logs do lambda"

    policy = file("${path.module}/lambda_vpc_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_function_executor" {
    count = local.policy_file != null && fileexists(local.policy_file.file_path) ? 1 : 0

    role       = aws_iam_role.lambda_function_executor.name
    policy_arn = aws_iam_policy.lambda_function_executor[count.index].arn
}

resource "aws_iam_role_policy_attachment" "lambda_function_executor_basic_policy" {
    depends_on = [
        null_resource.cloner
    ]

    role       = aws_iam_role.lambda_function_executor.name
    policy_arn = aws_iam_policy.lambda_function_executor_basic_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_function_executor_vpc_policy" {
    count = length(var.subnet_ids) != 0 && length(var.security_group_ids) != 0 ? 1 : 0

    role       = aws_iam_role.lambda_function_executor.name
    policy_arn = aws_iam_policy.lambda_function_executor_vpc_policy[count.index].arn
}