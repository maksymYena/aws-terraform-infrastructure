import configparser
import getpass
from pathlib import Path

import boto3
from botocore.exceptions import BotoCoreError, ClientError

PROFILE_NAME = "image-service"
REGION = "eu-north-1"
EXPECTED_ACCOUNT_ID = "888840134536"

AWS_DIRECTORY = Path.home() / ".aws"
CREDENTIALS_FILE = AWS_DIRECTORY / "credentials"
CONFIG_FILE = AWS_DIRECTORY / "config"


def read_config(path: Path) -> configparser.RawConfigParser:
    config = configparser.RawConfigParser()

    if path.exists():
        config.read(path, encoding="utf-8")

    return config


def save_config(
    config: configparser.RawConfigParser,
    path: Path,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as file:
        config.write(file)


def validate_credentials(
    access_key: str,
    secret_key: str,
    session_token: str | None,
) -> dict:
    session = boto3.Session(
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        aws_session_token=session_token,
        region_name=REGION,
    )

    sts = session.client("sts")
    return sts.get_caller_identity()


def save_credentials(
    access_key: str,
    secret_key: str,
    session_token: str | None,
) -> None:
    credentials = read_config(CREDENTIALS_FILE)

    if not credentials.has_section(PROFILE_NAME):
        credentials.add_section(PROFILE_NAME)

    credentials.set(PROFILE_NAME, "aws_access_key_id", access_key)
    credentials.set(PROFILE_NAME, "aws_secret_access_key", secret_key)

    if session_token:
        credentials.set(
            PROFILE_NAME,
            "aws_session_token",
            session_token,
        )
    elif credentials.has_option(PROFILE_NAME, "aws_session_token"):
        credentials.remove_option(PROFILE_NAME, "aws_session_token")

    save_config(credentials, CREDENTIALS_FILE)

    aws_config = read_config(CONFIG_FILE)
    profile_section = f"profile {PROFILE_NAME}"

    if not aws_config.has_section(profile_section):
        aws_config.add_section(profile_section)

    aws_config.set(profile_section, "region", REGION)
    aws_config.set(profile_section, "output", "json")

    save_config(aws_config, CONFIG_FILE)


def main() -> None:
    print(f"Configuring AWS profile: {PROFILE_NAME}")
    print("Do not send these credentials to anyone.\n")

    access_key = input("AWS Access Key ID: ").strip()
    secret_key = getpass.getpass("AWS Secret Access Key: ").strip()
    session_token = getpass.getpass(
        "AWS Session Token (leave empty for permanent credentials): "
    ).strip()

    if not access_key or not secret_key:
        raise ValueError(
            "AWS Access Key ID and Secret Access Key are required."
        )

    try:
        identity = validate_credentials(
            access_key=access_key,
            secret_key=secret_key,
            session_token=session_token or None,
        )
    except (ClientError, BotoCoreError) as error:
        print("\nCredentials were not saved.")
        print(f"AWS authentication failed: {error}")
        return

    account_id = identity.get("Account")
    arn = identity.get("Arn")

    print("\nAuthentication successful.")
    print(f"Account: {account_id}")
    print(f"Identity: {arn}")

    if account_id != EXPECTED_ACCOUNT_ID:
        confirmation = input(
            f"\nExpected account {EXPECTED_ACCOUNT_ID}, "
            f"but received {account_id}. Save anyway? [y/N]: "
        ).strip().lower()

        if confirmation != "y":
            print("Credentials were not saved.")
            return

    save_credentials(
        access_key=access_key,
        secret_key=secret_key,
        session_token=session_token or None,
    )

    print(f"\nAWS profile '{PROFILE_NAME}' was saved successfully.")
    print(f"Region: {REGION}")


if __name__ == "__main__":
    main()
