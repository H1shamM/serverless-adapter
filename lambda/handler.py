
import os
import json

from botocore.exceptions import ClientError

from aws_utils import list_ec2_instances, normalize_instances

def lambda_handler(event, context):
    """
    Self-contained Lambda that lists and normalizes EC2 instances.

    """
    # 1. Load config from env
    access_key = os.environ.get("AWS_ACCESS_KEY_ID")
    secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
    region = os.environ.get("AWS_REGION", "us-east-1")

    if not access_key or not secret_key:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Missing AWS credentials"})
        }

    # 2. Fetch raw EC2 data
    try:
        raw = list_ec2_instances(access_key, secret_key, region)
    except ClientError as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"AWS error: {e}"})
        }
    # 3. Fetch and normalize data
    data = normalize_instances(raw)

    return {
        "statusCode": 200,
        "body": json.dumps(data, default=str)
    }

