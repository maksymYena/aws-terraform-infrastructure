import os

import requests


API_BASE_URL = os.environ["API_BASE_URL"].rstrip("/")


def test_health_endpoint():
    response = requests.get(f"{API_BASE_URL}/health", timeout=10)

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_root_endpoint():
    response = requests.get(f"{API_BASE_URL}/", timeout=10)

    assert response.status_code == 200