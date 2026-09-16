from pathlib import Path
from uuid import UUID

from app import create_object_key


def test_create_object_key_preserves_extension():
    object_key = create_object_key("photo.PNG")

    assert object_key.startswith("images/")
    assert object_key.endswith(".png")

    generated_name = Path(object_key).stem
    UUID(generated_name)


def test_create_object_key_without_filename():
    object_key = create_object_key(None)

    assert object_key.startswith("images/")
    assert Path(object_key).suffix == ""

    generated_name = object_key.removeprefix("images/")
    UUID(generated_name)


def test_create_object_key_generates_unique_values():
    first_key = create_object_key("image.jpg")
    second_key = create_object_key("image.jpg")

    assert first_key != second_key
