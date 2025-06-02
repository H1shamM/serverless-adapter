output "lambda_function_name" {
  value = aws_lambda_function.adapter.function_name
  description = "Name of the Lambda function"
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value = aws_lambda_function.adapter.arn
}