# Serverless Adapter

**Serverless Adapter** re-implements an adapter microservice as an AWS Lambda function. It supports both on-demand HTTP invocation (via API Gateway) and scheduled execution (via EventBridge). All AWS resources are provisioned using Terraform, and monitoring is done with CloudWatch dashboards and alarms.

---

## Prerequisites

- AWS CLI configured with a user/role that has permissions to create:
  - Lambda functions
  - API Gateway REST APIs
  - IAM roles and policies
  - EventBridge rules
  - CloudWatch dashboards and alarms
- Terraform v0.15.0 or later
- Python 3.9+ (for Lambda runtime, local packaging)
- Zip utility (to package Lambda code)
- Git (to clone this repository)

---

## Project Layout

- **lambda/**: Contains the Python Lambda handler and its dependencies.
- **terraform/**: Terraform configurations for AWS resources (IAM, Lambda, API Gateway, EventBridge, CloudWatch).
- **scripts/**: Utility scripts for packaging and cleanup (e.g., packaging the Lambda ZIP, destroying resources).
- **README.md**: This file.

---

## Deployment

1. **Clone the Repository**

   ```bash
   git clone https://github.com/H1shamM/serverless-adapter.git
   cd serverless-adapter
   ```

2. **Package Lambda Code**

   Navigate to the `lambda/` directory and create a deployment package:

   ```bash
   cd lambda
   pip install --target ./package -r requirements.txt
   cp handler.py package/
   cd package
   zip -r ../lambda_deploy.zip .
   cd ../..
   ```

3. **Terraform Setup**

   Copy the example vars file and edit with your environment values:

   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

   In `terraform/terraform.tfvars`, set values for:
   - `aws_region`
   - `lambda_function_name`
   - `lambda_memory_size`
   - `lambda_timeout`
   - `schedule_cron_expression`
   - `environment_variables` (e.g., `ADAPTER_ENDPOINT`, `API_KEY`)
   - `dashboard_name`

4. **Initialize & Apply Terraform**

   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
   Review the plan and confirm with `yes`. Terraform will create:
   - IAM roles and policies
   - Lambda function (using `lambda_deploy.zip`)
   - API Gateway REST API with a POST route
   - EventBridge rule for scheduled invocation
   - CloudWatch dashboard and alarms

   After a successful apply, Terraform outputs include:
   - `api_gateway_invoke_url`: The HTTP endpoint for on-demand calls
   - `cloudwatch_dashboard_url`: The URL to view Lambda metrics and alarms
   - `lambda_function_arn`: ARN of the deployed Lambda

---

## Testing & Invocation

- **HTTP Invocation**  
  Use the `api_gateway_invoke_url` output:

  ```bash
  curl -X POST "<api_gateway_invoke_url>"        -H "Content-Type: application/json"        -d '{"resource_id":"example123"}'
  ```

  Expect a JSON response indicating success or a validation error (e.g., missing `resource_id`).

- **Scheduled Invocation**  
  The Lambda runs automatically according to the `schedule_cron_expression` in Terraform. Verify execution by checking CloudWatch Logs for timestamped entries and by viewing metrics on the dashboard.

---

## Monitoring

Terraform creates a CloudWatch Dashboard (named in `terraform.tfvars`) with widgets for:
- **Invocations**: Count of Lambda executions
- **Errors**: Number of failed invocations
- **Duration**: Average and percentile latency

An optional alarm triggers if error counts exceed a threshold. Use the `cloudwatch_dashboard_url` output to open the dashboard and customize as needed.

---

## Cleanup

To destroy all AWS resources provisioned by this project:

```bash
cd terraform
terraform destroy
```

Confirm with `yes`. Then remove local artifacts:

```bash
rm ../lambda/lambda_deploy.zip
```

---

## Author

**Hisham Murad**  
GitHub: [@H1shamM](https://github.com/H1shamM)  
