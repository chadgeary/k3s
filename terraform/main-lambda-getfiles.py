import json
import os
from urllib.request import urlopen

import boto3
import urllib3

"""
"event":
    {
        "prefix": "data/downloads/k3s/helm-x86_64.tar.gz",
        "url": "https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz"
    }
}
"""


def lambda_handler(event, context):

    print(event)
    s3 = boto3.resource("s3")
    http = urllib3.PoolManager()

    s3_object = list(
        s3.Bucket(os.environ["BUCKET"]).objects.filter(Prefix=event["prefix"])
    )
    if len(s3_object) > 0 and s3_object[0].key == event["prefix"]:
        print(event["prefix"] + " exists, skipping.")
    else:
        print(event["prefix"] + " not found, downloading.")
        with urlopen(event["url"]):
            s3.meta.client.upload_fileobj(
                http.request("GET", event["url"], preload_content=False),
                os.environ["BUCKET"],
                event["prefix"],
                ExtraArgs={
                    "ServerSideEncryption": "aws:kms",
                    "SSEKMSKeyId": os.environ["KEY"],
                },
            )
        print(event["prefix"] + " put to s3.")

    return {"statusCode": 200, "body": json.dumps("Complete")}
