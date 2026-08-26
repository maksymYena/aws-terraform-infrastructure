import os

import boto3
import pytest


AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
AWS_PROFILE = os.getenv("AWS_PROFILE", "terraform-dev")

BUCKET_NAME = "maksym-yena-image-bucket-dev"
DYNAMODB_TABLE_NAME = "recognition-results"
SQS_QUEUE_NAME = "image-queue-dev"
SNS_TOPIC_NAME = "image-notification-dev"
LAMBDA_FUNCTION_NAME = "image-recognition-lambda"
ECS_CLUSTER_NAME = "image-recognition-cluster"
ECS_SERVICE_NAME = "image-recognition-service"
ALB_NAME = "image-recognition-alb"


@pytest.fixture(scope="session")
def aws_session():
    return boto3.Session(
        profile_name=AWS_PROFILE,
        region_name=AWS_REGION,
    )


def test_s3_bucket_exists(aws_session):
    s3 = aws_session.client("s3")

    response = s3.head_bucket(Bucket=BUCKET_NAME)

    assert response["ResponseMetadata"]["HTTPStatusCode"] == 200


def test_dynamodb_table_is_active(aws_session):
    dynamodb = aws_session.client("dynamodb")

    response = dynamodb.describe_table(
        TableName=DYNAMODB_TABLE_NAME
    )

    table = response["Table"]

    assert table["TableName"] == DYNAMODB_TABLE_NAME
    assert table["TableStatus"] == "ACTIVE"


def test_sqs_queue_exists(aws_session):
    sqs = aws_session.client("sqs")

    response = sqs.get_queue_url(
        QueueName=SQS_QUEUE_NAME
    )

    assert "QueueUrl" in response


def test_sns_topic_exists(aws_session):
    sns = aws_session.client("sns")

    paginator = sns.get_paginator("list_topics")

    topic_arns = []

    for page in paginator.paginate():
        topic_arns.extend(
            topic["TopicArn"]
            for topic in page["Topics"]
        )

    assert any(
        arn.endswith(f":{SNS_TOPIC_NAME}")
        for arn in topic_arns
    )


def test_lambda_function_exists(aws_session):
    lambda_client = aws_session.client("lambda")

    response = lambda_client.get_function(
        FunctionName=LAMBDA_FUNCTION_NAME
    )

    configuration = response["Configuration"]

    assert configuration["FunctionName"] == LAMBDA_FUNCTION_NAME
    assert configuration["State"] == "Active"


def test_ecs_service_is_running(aws_session):
    ecs = aws_session.client("ecs")

    response = ecs.describe_services(
        cluster=ECS_CLUSTER_NAME,
        services=[ECS_SERVICE_NAME],
    )

    assert len(response["services"]) == 1

    service = response["services"][0]

    assert service["status"] == "ACTIVE"
    assert service["desiredCount"] == 2
    assert service["runningCount"] == 2


def test_application_load_balancer_exists(aws_session):
    elbv2 = aws_session.client("elbv2")

    response = elbv2.describe_load_balancers(
        Names=[ALB_NAME]
    )

    assert len(response["LoadBalancers"]) == 1

    load_balancer = response["LoadBalancers"][0]

    assert load_balancer["State"]["Code"] == "active"
    assert load_balancer["Type"] == "application"