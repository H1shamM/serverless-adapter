resource "aws_cloudwatch_dashboard" "adapter_dashboard" {
  dashboard_name = "ServerlessAdapterDashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          view        = "timeSeries"
          stacked     = false
          region      = var.aws_region
          title       = "Lambda Invocations / Errors"
          metrics     = [
            [ "AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.adapter.function_name ],
            [ ".",       "Errors",      ".",            "."                                   ]
          ]
          period      = 300
          stat        = "Sum"
          yAxis = {
            left = { min = 0 }
            right = { min = 0 }
          }
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Duration (Avg)"
          metrics = [
            [ "AWS/Lambda", "Duration", "FunctionName", aws_lambda_function.adapter.function_name, { "stat": "Average" } ]
          ]
          period = 300
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_alarm" {
  alarm_name          = "Serverlessadapter_LambdaErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name = "Errors"
  namespace = "AWS/Lambda"
  period = 300
  statistic = "Sum"
  threshold = 0
  alarm_description = "Alarm if serverless adapter Lambda records any errors."
  actions_enabled = true

  dimensions = {
    FunctionName = aws_lambda_function.adapter.function_name
  }
}