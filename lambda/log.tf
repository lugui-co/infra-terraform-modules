resource "aws_cloudwatch_log_group" "lambda_function_executor" {
    name              = "/aws/lambda/${var.function_name}"
    retention_in_days = 180

    tags = merge(
        {
            Name        = "lambda_function_executor_logs"
        },
        var.tags
    )
}