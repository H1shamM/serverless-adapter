import boto3
from botocore.exceptions import ClientError
from datetime import datetime
from typing import List, Dict


def list_ec2_instances(region: str = "eu-north-1") -> List[Dict]:
    """
    Returns raw EC2 instance data.
    """
    session = boto3.Session(region_name=region)
    ec2 = session.resource("ec2")
    return [inst.meta.data for inst in ec2.instances.all()]


def normalize_instances(raw: List[Dict]) -> List[Dict]:
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
