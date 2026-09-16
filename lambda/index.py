import json
import os
import urllib.parse

import boto3


DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")


rekognition = boto3.client(
    "rekognition",
    region_name=AWS_REGION,
)

dynamodb = boto3.resource(
    "dynamodb",
    region_name=AWS_REGION,
)

table = dynamodb.Table(DYNAMODB_TABLE_NAME)


def lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    for record in event.get("Records", []):
        process_sqs_record(record)

    return {
        "statusCode": 200,
        "body": "Images processed successfully",
    }


def process_sqs_record(record):
    sqs_body = json.loads(record["body"])

    # SNS отправляет в SQS JSON envelope.
    # Само S3 event находится внутри поля Message.
    if "Message" in sqs_body:
        s3_event = json.loads(sqs_body["Message"])
    else:
        s3_event = sqs_body

    for s3_record in s3_event.get("Records", []):
        bucket_name = s3_record["s3"]["bucket"]["name"]

        object_key = urllib.parse.unquote_plus(
            s3_record["s3"]["object"]["key"]
        )

        process_image(
            bucket_name=bucket_name,
            object_key=object_key,
        )


def process_image(bucket_name, object_key):
    print(
        f"Processing image: "
        f"s3://{bucket_name}/{object_key}"
    )

    response = rekognition.detect_labels(
        Image={
            "S3Object": {
                "Bucket": bucket_name,
                "Name": object_key,
            }
        },
        MaxLabels=10,
        MinConfidence=70,
    )

    labels = response.get("Labels", [])

    print(f"Detected {len(labels)} labels")

    for label in labels:
        label_name = label["Name"]
        confidence = str(label["Confidence"])

        table.put_item(
            Item={
                "ImageName": object_key,
                "LabelValue": label_name,
                "Confidence": confidence,
            }
        )

        print(
            f"Saved label: "
            f"{object_key} -> {label_name}"
        )
