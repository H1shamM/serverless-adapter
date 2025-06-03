import boto3
from botocore.exceptions import ClientError
from datetime import datetime
from typing import List, Dict, Any


def list_ec2_instances(region: str = "eu-north-1") -> List[Dict]:
    """
    Returns raw EC2 instance data.
    """
    session = boto3.Session(region_name=region)
    ec2 = session.resource("ec2")
    return [inst.meta.data for inst in ec2.instances.all()]

def list_s3_buckets() -> List[Dict[str,Any]]:
    """
       Returns a list of all S3 buckets (names + creation dates).
    """

    s3 = boto3.client("s3")
    resp = s3.list_buckets()
    buckets = resp.get("Buckets", [])
    return [
        {
            "Name": b["Name"],
            "CreationDate": b["CreationDate"]
        }
        for b in buckets
    ]


def normalize_ec2(raw: List[Dict]) -> List[Dict]:
    """
    Transforms AWS EC2 data into your desired shape.
    """
    normalized = []
    for inst in raw:
        # Pull Name tag if present
        name = next(
            (tag["Value"] for tag in inst.get("Tags", []) if tag["Key"] == "Name"),
            "Unnamed Instance"
        )
        normalized.append({
            "asset_id": f"aws_ec2_{inst['InstanceId']}",
            "name": name,
            "type": "ec2",
            "status": inst["State"]["Name"].upper(),
            "created_at": inst["LaunchTime"].isoformat()
                            if isinstance(inst["LaunchTime"], datetime)
                            else inst["LaunchTime"],
            "metadata": {
                "instance_type": inst["InstanceType"],
                "public_ip": inst.get("PublicIpAddress"),
                "vpc_id": inst.get("VpcId")
            }
        })
    return normalized

def normalize_s3(raw_buckets: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
        Transforms S3 bucket data into a consistent JSON shape.
    """

    normalized = []
    for b in raw_buckets:
        created = b.get("CreationDate")
        if isinstance(created, datetime):
            created = created.isoformat()
        normalized.append({
            "resource_type": "s3",
            "resource_id": b["Name"],
            "name": b["Name"],
            "created_at": created,
            "metadata": {}
        })
    return normalized
