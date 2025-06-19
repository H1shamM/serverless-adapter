import json
import pytest

from botocore.exceptions import ClientError
from adapter.handler import lambda_handler

@pytest.fixture(autouse=True)
def env(monkeypatch):
    monkeypatch.setenv('AWS_REGION','eu-west-1')
    yield

def test_handler_success(monkeypatch):
    fake_ec2_raw = [{"InstanceId": "i-123"}]
    fake_s3_raw = [{"Name": "bucket1"}]

    fake_ec2_norm = [{"id": "i-123", "type": "ec2"}]
    fake_s3_norm = [{"name": "bucket1", "type": "s3"}]

    monkeypatch.setattr("adapter.handler.list_ec2_instances", lambda region: fake_ec2_raw)
    monkeypatch.setattr("adapter.handler.list_s3_buckets", lambda: fake_s3_raw)
    monkeypatch.setattr("adapter.handler.normalize_ec2", lambda raw: fake_ec2_norm)
    monkeypatch.setattr("adapter.handler.normalize_s3", lambda raw: fake_s3_norm)

    response = lambda_handler({}, None)
    assert response["statusCode"] == 200
    data = json.loads(response["body"])
    assert data == fake_ec2_norm + fake_s3_norm


def test_handler_aws_error(monkeypatch):

    def raise_client_error(region):
        raise ClientError({"Error": {}}, "DescribeInstances")

    monkeypatch.setattr("adapter.handler.list_ec2_instances", raise_client_error)
    monkeypatch.setattr("adapter.handler.list_s3_buckets",    lambda: [])

    response = lambda_handler({}, None)

    assert response["statusCode"] == 500
    err = json.loads(response["body"])
    assert "AWS error" in err["error"]

