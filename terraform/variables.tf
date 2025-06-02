variable "aws_region" {
  description = "AWS region to deploy resources"
  type = string
  default = "eu-north-1"
}

variable "lambda_s3_bucket" {
  description = "S3 bucket where Lambda code ZIP is stored"
  type        = string
  default = "my-serverless-adapter-bucket"
}

variable "lambda_s3_key" {
  description = "S3 key (path) for the Lambda ZIP artifact"
  type = string
  default = "adapter.zip"
}