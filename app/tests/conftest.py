import os
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT))

os.environ.setdefault("S3_BUCKET_NAME", "test-image-bucket")
os.environ.setdefault("DYNAMODB_TABLE_NAME", "test-image-table")
os.environ.setdefault("AWS_DEFAULT_REGION", "eu-north-1")
os.environ.setdefault("AWS_ACCESS_KEY_ID", "testing")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "testing")

from app import app  # noqa: E402


@pytest.fixture
def client() -> TestClient:
    return TestClient(app)
