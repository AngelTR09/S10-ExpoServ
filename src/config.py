import os
import boto3

# Misma región que var.region de Terraform.
REGION = os.environ.get("AWS_REGION", "us-east-2")
sqs = boto3.client("sqs", region_name=REGION)
sns = boto3.client("sns", region_name=REGION)

# Vienen de `terraform output`; los scripts no crean recursos.
QUEUE_URL = os.environ["QUEUE_URL"]
AUDIT_URL = os.environ["AUDIT_URL"]
TOPIC_ARN = os.environ["TOPIC_ARN"]
