import json
import os
from urllib.request import urlopen

import boto3
import urllib3


def lambda_handler(event, context):

    s3 = boto3.resource("s3")
    http = urllib3.PoolManager()

    # k3s x86_64
    if event["files"] == "k3s-x86_64":

        urls = {
            "data/downloads/k3s/k3s-airgap-images-x86_64.tar": os.environ[
                "K3S_TAR_X86_64"
            ],
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

    # k3s arm64
    if event["files"] == "k3s-arm64":

        urls = {
            "data/downloads/k3s/k3s-airgap-images-aarch64.tar": os.environ[
                "K3S_TAR_ARM64"
            ],
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

    # k3s binary and install.sh
    if event["files"] == "k3s-bin":

        urls = {
            "data/downloads/charts/aws-vpc-cni.tgz": os.environ["AWS_VPC_CNI"],
            "data/downloads/k3s/k3s-x86_64": os.environ["K3S_BIN_X86_64"],
            "data/downloads/k3s/k3s-aarch64": os.environ["K3S_BIN_ARM64"],
            "data/downloads/k3s/helm-x86_64.tar.gz": os.environ["HELM_X86_64"],
            "data/downloads/k3s/helm-aarch64.tar.gz": os.environ["HELM_ARM64"],
            "scripts/install.sh": os.environ["K3S_INSTALL"],
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
