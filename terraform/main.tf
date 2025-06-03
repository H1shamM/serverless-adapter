# ---------------------------------------------
# 1. IAM Role for Lambda Execution
# ---------------------------------------------

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }

}

resource "aws_iam_role" "lambda_exec_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  name               = "serverless_adapter_lambda_role"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_iam_role_policy" "lambda_ec2_read" {
  name = "serverless_adapter_ec2_read"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:DescribeInstances"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
  role   = aws_iam_role.lambda_exec_role.id
}

resource "aws_iam_role_policy" "lambda_s3_list" {
  name = "serverless_adapter_s3_list"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:ListAllMyBuckets"]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
  })
  role   = aws_iam_role.lambda_exec_role.id
}

# ---------------------------------------------
# 2. Lambda Function
# ---------------------------------------------

resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = var.lambda_s3_bucket
  key    = var.lambda_s3_key

  source = "../adapter.zip"
  etag = filemd5("../adapter.zip")
}
resource "aws_lambda_function" "adapter" {
  function_name = "serverless_adapter_function"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket = var.lambda_s3_bucket
  s3_key = var.lambda_s3_key

  source_code_hash = filebase64sha256("../adapter.zip")

  handler = "handler.lambda_handler"
  runtime = "python3.9"

  timeout = 10
  memory_size = 256

}

# ---------------------------------------------
# 3. API Gateway REST API & Integration
# ---------------------------------------------

resource "aws_api_gateway_rest_api" "adapter_api" {
  name = "serverless_adapter_api"
  description = "HTTP API for invoking the serverless adapter Lambda"
}

resource "aws_api_gateway_resource" "run" {
  parent_id   = aws_api_gateway_rest_api.adapter_api.root_resource_id
  path_part   = "run"
  rest_api_id = aws_api_gateway_rest_api.adapter_api.id
}

resource "aws_api_gateway_method" "get_run" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.run.id
  rest_api_id   = aws_api_gateway_rest_api.adapter_api.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  http_method = aws_api_gateway_method.get_run.http_method
  resource_id = aws_api_gateway_resource.run.id
  rest_api_id = aws_api_gateway_rest_api.adapter_api.id
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.adapter.invoke_arn
}

resource "aws_lambda_permission" "apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.adapter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.adapter_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "adapter_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.adapter_api.id
  stage_name = "prod"
  description = "Deploy API to prod stage"
}

# ---------------------------------------------
# 4. EventBridge (CloudWatch Events) Schedule
# ---------------------------------------------
resource "aws_cloudwatch_event_rule" "every_24_hours" {
  name                  = "run_adapter_every_24_hours"
  description           = "Trigger adapter Lambda every 24 hours"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  arn  = aws_lambda_function.adapter.arn
  rule = aws_cloudwatch_event_rule.every_24_hours.name
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.adapter.function_name
  principal     = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_24_hours.arn
}