import boto3
import json
import os
import subprocess
import sys
from urllib.request import urlopen
import urllib3


def lambda_handler(event, context):

    s3 = boto3.resource("s3")
    http = urllib3.PoolManager()

    # k3s
    urls = {
        "data/downloads/k3s/k3s": os.environ["K3S_BIN_URL"],
        "data/downloads/k3s/k3s-airgap-images-amd64.tar": os.environ["K3S_TAR_URL"],
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

    # pip packages
    packages = ["ansible", "boto3", "botocore"]
    for package in packages:
        s3_object = list(
            s3.Bucket(os.environ["BUCKET"]).objects.filter(
                Prefix="data/downloads/" + package
            )
        )
        if len(s3_object) > 2:
            print("data/downloads/" + package + " exists, skipping.")
        else:

            # download to /tmp/
            subprocess.check_call(
                [
                    sys.executable,
                    "-m",
                    "pip",
                    "download",
                    "-d",
                    "/tmp/" + package,
                    package,
                ]
            )

            # upload to /data/downloads/
            for root, dirs, files in os.walk("/tmp/" + package):
                for file in files:
                    s3.meta.client.upload_file(
                        os.path.join(root, file),
                        os.environ["BUCKET"],
                        "data/downloads/" + package + "/" + file,
                        ExtraArgs={
                            "ServerSideEncryption": "aws:kms",
                            "SSEKMSKeyId": os.environ["KEY"],
                        },
                    )
                    print(file + " put to s3.")

    return {"statusCode": 200, "body": json.dumps("Complete")}
