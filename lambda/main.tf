resource "aws_lambda_function" "lambda_function_executor" {
    depends_on = [
        aws_iam_role_policy_attachment.lambda_function_executor_basic_policy,
        null_resource.builder,
        null_resource.ecr_builder
    ]

    memory_size = var.memory_size

    timeout = var.timeout

    layers = var.layers

    function_name = var.function_name

    description = var.description

    package_type = var.runtime == "docker" || var.image_uri != null ? "Image" : "Zip"

    filename = var.runtime == "docker" || var.image_uri != null ? null : var.no_clone || var.no_build ? "${path.module}/dummy_file.zip" : "${local.function_dir}/main.zip"

    source_code_hash = var.runtime == "docker" || var.image_uri != null ? null : fileexists("${local.function_dir}/main.zip") ? filebase64sha256("${local.function_dir}/main.zip") : null

    image_uri = var.image_uri != null ? var.image_uri : var.runtime == "docker" ? "${aws_ecr_repository.ecr_repository[0].repository_url}:latest" : null

    handler = var.runtime == "docker" || var.image_uri != null ? null : var.handler
    runtime = var.runtime == "docker" || var.image_uri != null ? null : var.runtime

    role = aws_iam_role.lambda_function_executor.arn

    dynamic vpc_config {
        for_each = length(var.subnet_ids) == 0 && length(var.security_group_ids) == 0 ? [] : [true]

        content {
            subnet_ids         = var.subnet_ids
            security_group_ids = var.security_group_ids
        }
    }

    dynamic environment {
        for_each = length(keys(var.venvs)) == 0 ? [] : [true]

        content{
            variables = var.venvs
        }
    }

    dynamic ephemeral_storage {
        for_each = var.ephemeral_storage == null ? [] : [true]

        content {
            size = var.ephemeral_storage
        }
    }

    tags = merge(
        {
            Name        = "lambda_function_executor"
        },
        var.tags
    )
}

resource "aws_lambda_function_event_invoke_config" "lambda_function_executor" {
    function_name = aws_lambda_function.lambda_function_executor.function_name

    maximum_event_age_in_seconds = var.on_failure_maximum_event_age_in_seconds
    maximum_retry_attempts       = var.maximum_retry_attempts

    dynamic destination_config {
        for_each = var.on_failure_notify != null || var.on_success_notify != null ? [true] : []

        content {
            on_failure {
                destination = var.on_failure_notify
            }

            on_success {
                destination = var.on_success_notify
            }
        }
    }
}

resource "aws_lambda_function_url" "lambda_function_executor" {
  count = var.use_lambda_url != null && var.use_lambda_url ? 1 : 0

  function_name      = aws_lambda_function.lambda_function_executor.function_name
  authorization_type = var.lambda_url_authorization_type

  dynamic cors {
    for_each = var.lambda_url_cors != null ? [var.lambda_url_cors] : []

    content {
        allow_credentials = lambda_url_cors.allow_credentials
        allow_origins     = lambda_url_cors.allow_origins
        allow_methods     = lambda_url_cors.allow_methods
        allow_headers     = lambda_url_cors.allow_headers
        expose_headers    = lambda_url_cors.expose_headers
        max_age           = lambda_url_cors.max_age
    }
  }
}