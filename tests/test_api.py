import time

import requests

BASE_URL = "http://localhost:8000"


def wait_for_startup(timeout_seconds: int = 30) -> None:
    deadline = time.time() + timeout_seconds
    last_error = ""
    while time.time() < deadline:
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=1)
            if response.status_code == 200:
                return
        except requests.RequestException as exc:
            last_error = str(exc)
        time.sleep(1)
    raise AssertionError(f"API failed to start within {timeout_seconds}s: {last_error}")


def test_health_endpoint() -> None:
    wait_for_startup()
    response = requests.get(f"{BASE_URL}/health", timeout=5)
    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    assert response.json() == {"status": "ok"}


def test_create_and_retrieve_user_with_persistence() -> None:
    wait_for_startup()

    create_response = requests.post(
        f"{BASE_URL}/users", json={"name": "Lisa"}, timeout=5
    )
    assert create_response.status_code in (200, 201)
    created_payload = create_response.json()

    assert isinstance(created_payload.get("id"), int)
    assert created_payload["id"] > 0
    assert created_payload["name"] == "Lisa"

    user_id = created_payload["id"]

    get_response = requests.get(f"{BASE_URL}/users/{user_id}", timeout=5)
    assert get_response.status_code == 200
    fetched_payload = get_response.json()
    assert fetched_payload["id"] == user_id
    assert fetched_payload["name"] == "Lisa"

    get_response_again = requests.get(f"{BASE_URL}/users/{user_id}", timeout=5)
    assert get_response_again.status_code == 200
    assert get_response_again.json() == fetched_payload
