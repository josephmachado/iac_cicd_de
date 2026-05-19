import boto3
import time
import json
import os
from datetime import datetime

BUCKET_NAME = os.environ.get("BUCKET_NAME")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")

if not BUCKET_NAME:
    raise ValueError("BUCKET_NAME environment variable is not set")


def write_to_s3():
    s3 = boto3.client("s3")

    data = {
        "timestamp": datetime.utcnow().isoformat(),
        "message": "hello from ec2",
        "value": 42,
    }

    key = f"data/{ENVIRONMENT}/{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"

    s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=json.dumps(data))

    print(f"written: {key}")


while True:
    write_to_s3()
    time.sleep(60)
