import boto3
import json
import os
from urllib.request import urlopen
import urllib3


def lambda_handler(event, context):
    s3 = boto3.resource("s3")
    http = urllib3.PoolManager()
    urls = {
        "k3s/downloads/k3s": os.environ["K3S_BIN_URL"],
        "k3s/downloads/k3s-airgap-images-amd64.tar": os.environ["K3S_TAR_URL"],
    }

    for key in urls:
        s3_object = list(s3.Bucket(os.environ["BUCKET"]).objects.filter(Prefix=key))
        if len(s3_object) > 0 and s3_object[0].key == key:
            print(key + " exists, skipping.")
        else:
            print(key + " not found, downloading.")
            with urlopen(urls[key]):
                s3.meta.client.upload_fileobj(
                    http.request("GET", urls[key], preload_content=False),
                    os.environ["BUCKET"],
                    key,
                    ExtraArgs={
                        "ServerSideEncryption": "aws:kms",
                        "SSEKMSKeyId": os.environ["KEY"],
                    },
                )
            print(key + " put to s3.")

    return {"statusCode": 200, "body": json.dumps("Complete")}
