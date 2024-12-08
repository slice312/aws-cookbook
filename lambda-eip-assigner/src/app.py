import json
import logging
import boto3
from boto3_type_annotations.sts import Client as STSClient

# logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger()
logger.setLevel(logging.INFO)


sts: STSClient = boto3.client('sts')

def lambda_handler(event, context):
    response = sts.get_caller_identity()
    logger.info(response)

    logger.info(f"check {event}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "hello world",
            # "location": ip.text.replace("\n", "")
        }),
    }





# import logging
# logger = logging.getLogger()
# logger.setLevel(logging.INFO)


# ec2 = boto3.client('ec2')

# def lambda_handler(event, context):
#     logger.info('## ENVIRONMENT VARIABLES')
#     print("kek")
#     print(event)
#     # Получаем ID инстанса из события
#     instance_id = event['detail']['EC2InstanceId']
#     allocation_id = 'eipalloc-xxxxxxxx'  # Замените на ваш Allocation ID

#     try:
#         # Привязываем Elastic IP к инстансу
#         ec2.associate_address(InstanceId=instance_id, AllocationId=allocation_id)
#         print(f"Elastic IP {allocation_id} associated with instance {instance_id}")
#     except Exception as e:
#         print(f"Error associating Elastic IP: {e}")