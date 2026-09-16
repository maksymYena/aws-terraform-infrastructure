from io import BytesIO
from unittest.mock import Mock

import pytest
from botocore.exceptions import BotoCoreError, ClientError

import app as app_module


def test_health_endpoint(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_root_endpoint(client):
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "service": "Image Label Service",
        "status": "running",
    }


def test_upload_image_success(client, monkeypatch):
    upload_mock = Mock()
    monkeypatch.setattr(
        app_module.s3_client,
        "upload_fileobj",
        upload_mock,
    )

    response = client.post(
        "/images",
        files={
            "file": (
                "cat.png",
                BytesIO(b"fake-image-content"),
                "image/png",
            )
        },
    )

    assert response.status_code == 201

    response_body = response.json()

    assert response_body["message"] == "Image uploaded successfully"
    assert response_body["bucket"] == app_module.S3_BUCKET_NAME
    assert response_body["imageName"].startswith("images/")
    assert response_body["imageName"].endswith(".png")

    upload_mock.assert_called_once()

    _, bucket_name, object_key = upload_mock.call_args.args

    assert bucket_name == app_module.S3_BUCKET_NAME
    assert object_key == response_body["imageName"]
    assert upload_mock.call_args.kwargs["ExtraArgs"] == {
        "ContentType": "image/png"
    }


def test_upload_rejects_non_image_file(client):
    response = client.post(
        "/images",
        files={
            "file": (
                "document.txt",
                BytesIO(b"not an image"),
                "text/plain",
            )
        },
    )

    assert response.status_code == 400
    assert response.json() == {
        "detail": "Only image files are allowed"
    }


def test_get_images_by_label(client, monkeypatch):
    query_mock = Mock(
        return_value={
            "Items": [
                {
                    "LabelValue": "Cat",
                    "ImageName": "images/cat-1.png",
                },
                {
                    "LabelValue": "Cat",
                    "ImageName": "images/cat-2.png",
                },
            ]
        }
    )

    monkeypatch.setattr(
        app_module.table,
        "query",
        query_mock,
    )

    response = client.get("/images/Cat")

    assert response.status_code == 200
    assert response.json() == {
        "label": "Cat",
        "count": 2,
        "images": [
            {
                "LabelValue": "Cat",
                "ImageName": "images/cat-1.png",
            },
            {
                "LabelValue": "Cat",
                "ImageName": "images/cat-2.png",
            },
        ],
    }

    query_mock.assert_called_once()


def test_get_images_returns_empty_list(client, monkeypatch):
    monkeypatch.setattr(
        app_module.table,
        "query",
        Mock(return_value={"Items": []}),
    )

    response = client.get("/images/Unknown")

    assert response.status_code == 200
    assert response.json() == {
        "label": "Unknown",
        "count": 0,
        "images": [],
    }


@pytest.mark.parametrize(
    "content_type",
    [
        "application/json",
        "application/pdf",
        "text/plain",
    ],
)
def test_upload_rejects_unsupported_content_types(
        client,
        content_type,
):
    response = client.post(
        "/images",
        files={
            "file": (
                "file.dat",
                BytesIO(b"content"),
                content_type,
            )
        },
    )

    assert response.status_code == 400


def test_upload_image_returns_500_on_s3_client_error(
        client,
        monkeypatch,
):
    error = ClientError(
        {
            "Error": {
                "Code": "AccessDenied",
                "Message": "Access denied",
            }
        },
        "PutObject",
    )

    monkeypatch.setattr(
        app_module.s3_client,
        "upload_fileobj",
        Mock(side_effect=error),
    )

    response = client.post(
        "/images",
        files={
            "file": (
                "cat.png",
                BytesIO(b"fake-image-content"),
                "image/png",
            )
        },
    )

    assert response.status_code == 500
    assert "S3 error AccessDenied" in response.json()["detail"]


def test_upload_image_returns_500_on_boto_core_error(
        client,
        monkeypatch,
):
    class TestBotoCoreError(BotoCoreError):
        fmt = "test boto error"

    monkeypatch.setattr(
        app_module.s3_client,
        "upload_fileobj",
        Mock(side_effect=TestBotoCoreError()),
    )

    response = client.post(
        "/images",
        files={
            "file": (
                "cat.png",
                BytesIO(b"fake-image-content"),
                "image/png",
            )
        },
    )

    assert response.status_code == 500
    assert "AWS SDK error" in response.json()["detail"]


def test_get_images_returns_500_on_dynamodb_client_error(
        client,
        monkeypatch,
):
    error = ClientError(
        {
            "Error": {
                "Code": "InternalServerError",
                "Message": "DynamoDB failed",
            }
        },
        "Query",
    )

    monkeypatch.setattr(
        app_module.table,
        "query",
        Mock(side_effect=error),
    )

    response = client.get("/images/Cat")

    assert response.status_code == 500
    assert response.json() == {
        "detail": "Failed to read image data from DynamoDB"
    }


def test_get_images_returns_500_on_boto_core_error(
        client,
        monkeypatch,
):
    class TestBotoCoreError(BotoCoreError):
        fmt = "test boto error"

    monkeypatch.setattr(
        app_module.table,
        "query",
        Mock(side_effect=TestBotoCoreError()),
    )

    response = client.get("/images/Cat")

    assert response.status_code == 500
    assert response.json() == {
        "detail": "Failed to communicate with AWS"
    }
