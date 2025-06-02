
import os
import json

from botocore.exceptions import ClientError

from aws_utils import list_ec2_instances, normalize_instances

def lambda_handler(event, context):
    """
    Self-contained Lambda that lists and normalizes EC2 instances.

    """
    # 1. Load config from env
    region = os.environ.get("AWS_REGION", "eu-north-1")

    # 2. Fetch raw EC2 data
    try:
        raw = list_ec2_instances(region)
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

