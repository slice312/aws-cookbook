import os
import json
import logging
import boto3
from botocore.exceptions import ClientError
from boto3_type_annotations.ec2 import Client as EC2Client

from models import EventBridgeEvent

# logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event: EventBridgeEvent, context):
    allocation_id = os.environ["ELASTIC_IP_ALLOCATION_ID"]
    if not allocation_id:
        logger.error("ELASTIC_IP_ALLOCATION_ID environment variable not set")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "ELASTIC_IP_ALLOCATION_ID not set"})
        }

    ec2: EC2Client = boto3.client("ec2")

    instanceId = event["detail"]["EC2InstanceId"]

    try:
        resp = ec2.associate_address(AllocationId=allocation_id, InstanceId=instanceId)
        logger.info(f"Elastic IP successfully associated: {json.dumps(resp)}")
        return resp
    except ClientError as e:
        # Логируем ошибку и возвращаем ответ с ошибкой
        logger.error(f"Error associating Elastic IP: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error associating Elastic IP: {str(e)}"})
        }
