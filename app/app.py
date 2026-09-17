import os
import uuid
from pathlib import Path

import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import BotoCoreError, ClientError
from dotenv import load_dotenv
from fastapi import FastAPI, File, HTTPException, UploadFile


# Для локального запуска можно использовать .env.
# В ECS значения будут приходить через environment variables.
load_dotenv()


S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]

AWS_REGION = (
    os.getenv("AWS_REGION")
    or os.getenv("AWS_DEFAULT_REGION")
    or "eu-central-1"
)


# Одна AWS session для всех клиентов.
# В ECS boto3 автоматически получит временные credentials
# из ECS Task Role.
aws_session = boto3.Session(region_name=AWS_REGION)

s3_client = aws_session.client("s3")

dynamodb = aws_session.resource("dynamodb")
table = dynamodb.Table(DYNAMODB_TABLE_NAME)


app = FastAPI(title="Image Label Service")


@app.get("/health")
def health():
    return {
        "status": "healthy",
        "version": "demo-1"
    }


@app.get("/")
def root():
    return {
        "service": "Image Label Service",
        "status": "running"
    }


@app.post("/images", status_code=201)
def upload_image(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Only image files are allowed",
        )

    object_key = create_object_key(file.filename)

    try:
        s3_client.upload_fileobj(
            file.file,
            S3_BUCKET_NAME,
            object_key,
            ExtraArgs={
                "ContentType": file.content_type,
            },
        )

    except ClientError as error:
        aws_error = error.response.get("Error", {})
        error_code = aws_error.get("Code", "Unknown")
        error_message = aws_error.get("Message", str(error))

        print(f"S3 error {error_code}: {error_message}")

        raise HTTPException(
            status_code=500,
            detail=f"S3 error {error_code}: {error_message}",
        ) from error

    except BotoCoreError as error:
        print(f"AWS SDK error: {error}")

        raise HTTPException(
            status_code=500,
            detail=f"AWS SDK error: {error}",
        ) from error

    finally:
        file.file.close()

    return {
        "message": "Image uploaded successfully",
        "bucket": S3_BUCKET_NAME,
        "imageName": object_key,
    }


@app.get("/images/{label}")
def get_images_by_label(label: str):
    try:
        response = table.query(
            IndexName="LabelValue-index",
            KeyConditionExpression=Key("LabelValue").eq(label),
        )

        items = response.get("Items", [])

        while "LastEvaluatedKey" in response:
            response = table.query(
                IndexName="LabelValue-index",
                KeyConditionExpression=Key("LabelValue").eq(label),
                ExclusiveStartKey=response["LastEvaluatedKey"],
            )

            items.extend(response.get("Items", []))

    except ClientError as error:
        aws_error = error.response.get("Error", {})
        error_code = aws_error.get("Code", "Unknown")
        error_message = aws_error.get("Message", str(error))

        print(
            f"DynamoDB error {error_code}: "
            f"{error_message}"
        )

        raise HTTPException(
            status_code=500,
            detail="Failed to read image data from DynamoDB",
        ) from error

    except BotoCoreError as error:
        print(f"AWS SDK error: {error}")

        raise HTTPException(
            status_code=500,
            detail="Failed to communicate with AWS",
        ) from error

    return {
        "label": label,
        "count": len(items),
        "images": items,
    }


def create_object_key(filename: str | None) -> str:
    extension = Path(filename or "").suffix.lower()

    return f"images/{uuid.uuid4()}{extension}"
