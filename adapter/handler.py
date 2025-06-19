
import os
import json

from botocore.exceptions import ClientError

from .aws_utils import list_ec2_instances, list_s3_buckets, normalize_s3, normalize_ec2


def lambda_handler(event, context):
    """
    Self-contained Lambda that lists and normalizes EC2 instances.

    """
    # 1. Load config from env
    region = os.environ.get("AWS_REGION", "eu-north-1")

    # 2. Fetch raw EC2 data
    try:
        raw_ec2 = list_ec2_instances(region)
        raw_s3 = list_s3_buckets()
    except ClientError as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"AWS error: {e}"})
        }
    # 3. Fetch and normalize data
    data_ec2 = normalize_ec2(raw_ec2)
    data_s3 = normalize_s3(raw_s3)

    data = data_ec2 + data_s3
    return {
        "statusCode": 200,
        "body": json.dumps(data, default=str)
    }

