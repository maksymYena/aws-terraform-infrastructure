import importlib.util
import json
import os
from pathlib import Path
from unittest.mock import Mock

os.environ.setdefault("AWS_ACCESS_KEY_ID", "testing")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "testing")
os.environ.setdefault("AWS_SESSION_TOKEN", "testing")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-central-1")
os.environ.setdefault("AWS_REGION", "eu-central-1")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")
os.environ.setdefault("DYNAMODB_TABLE_NAME", "test-table")

INDEX_PATH = Path(__file__).resolve().parents[1] / "index.py"

spec = importlib.util.spec_from_file_location("lambda_index", INDEX_PATH)
index = importlib.util.module_from_spec(spec)
spec.loader.exec_module(index)


def test_lambda_handler_without_records():
    response = index.lambda_handler({}, None)

    assert response == {
        "statusCode": 200,
        "body": "Images processed successfully",
    }


def test_process_sqs_record_direct_s3_event(monkeypatch):
    process_image_mock = Mock()
    monkeypatch.setattr(index, "process_image", process_image_mock)

    s3_event = {
        "Records": [
            {
                "s3": {
                    "bucket": {
                        "name": "test-bucket",
                    },
                    "object": {
                        "key": "images%2Fcat.png",
                    },
                }
            }
        ]
    }

    record = {
        "body": json.dumps(s3_event),
    }

    index.process_sqs_record(record)

    process_image_mock.assert_called_once_with(
        bucket_name="test-bucket",
        object_key="images/cat.png",
    )


def test_process_sqs_record_sns_envelope(monkeypatch):
    process_image_mock = Mock()
    monkeypatch.setattr(index, "process_image", process_image_mock)

    s3_event = {
        "Records": [
            {
                "s3": {
                    "bucket": {
                        "name": "test-bucket",
                    },
                    "object": {
                        "key": "images%2Fdog.jpg",
                    },
                }
            }
        ]
    }

    sns_message = {
        "Message": json.dumps(s3_event),
    }

    record = {
        "body": json.dumps(sns_message),
    }

    index.process_sqs_record(record)

    process_image_mock.assert_called_once_with(
        bucket_name="test-bucket",
        object_key="images/dog.jpg",
    )


def test_process_image_saves_detected_labels(monkeypatch):
    detect_labels_mock = Mock(
        return_value={
            "Labels": [
                {
                    "Name": "Cat",
                    "Confidence": 99.5,
                }
            ]
        }
    )

    put_item_mock = Mock()

    monkeypatch.setattr(
        index.rekognition,
        "detect_labels",
        detect_labels_mock,
    )
    monkeypatch.setattr(
        index.table,
        "put_item",
        put_item_mock,
    )

    index.process_image(
        bucket_name="test-bucket",
        object_key="images/cat.png",
    )

    detect_labels_mock.assert_called_once_with(
        Image={
            "S3Object": {
                "Bucket": "test-bucket",
                "Name": "images/cat.png",
            }
        },
        MaxLabels=10,
        MinConfidence=70,
    )

    put_item_mock.assert_called_once_with(
        Item={
            "ImageName": "images/cat.png",
            "LabelValue": "Cat",
            "Confidence": "99.5",
        }
    )
