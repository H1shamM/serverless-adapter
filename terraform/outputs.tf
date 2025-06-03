output "lambda_function_name" {
  value = aws_lambda_function.adapter.function_name
  description = "Name of the Lambda function"
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value = aws_lambda_function.adapter.arn
}

output "api_invoke_url" {
  description = "Invoke URL for GET /run"
  value = "https://${aws_api_gateway_rest_api.adapter_api.id}.execute-api.${var.aws_region}.amazonaws.com/prod/run"
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.adapter_dashboard.dashboard_name}"
}