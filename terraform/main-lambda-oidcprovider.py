import json
import os
import time

import boto3


def lambda_handler(event, context):

    s3 = boto3.resource("s3")
    iam = boto3.client("iam")

    # k3s x86_64
    print("caller: " + event["caller"])

    s3objects = {
        "thumbprint": "oidc/thumbprint",
        "openid-configuration": "oidc/.well-known/openid-configuration",
        "jwks": "oidc/openid/v1/jwks",
    }
    fileobjects = {}

    for _ in range(int(os.environ["OBJECT_TIMEOUT"])):
        try:
            for key in s3objects:
                s3.Object(
                    s3.Bucket(os.environ["BUCKET_PUBLIC"]).name, s3objects[key]
                ).copy_from(
                    CopySource={
                        "Bucket": os.environ["BUCKET_PRIVATE"],
                        "Key": s3objects[key],
                    }
                )
                s3.Object(
                    s3.Bucket(os.environ["BUCKET_PUBLIC"]).name, s3objects[key]
                ).Acl().put(ACL="public-read")
                object = s3.meta.client.get_object(
                    Bucket=s3.Bucket(os.environ["BUCKET_PRIVATE"]).name,
                    Key=s3objects[key],
                )
                fileobjects[key] = (
                    object["Body"].read().decode("utf-8").replace("\n", "")
                )
        except s3.meta.client.exceptions.NoSuchKey as e:
            print(e)
            time.sleep(1)
            continue
        else:
            break
    else:
        print("timeout on s3 objects!!!")
        raise

    print(fileobjects)

    try:
        iam.create_open_id_connect_provider(
            Url="https://"
            + s3.Bucket(os.environ["BUCKET_PUBLIC"]).name
            + ".s3."
            + os.environ["REGION"]
            + ".amazonaws.com/oidc",
            ClientIDList=[
                os.environ["PREFIX"] + "-" + os.environ["SUFFIX"],
            ],
            ThumbprintList=[
                fileobjects["thumbprint"],
            ],
            Tags=[
                {
                    "Key": "Name",
                    "Value": os.environ["PREFIX"] + "-" + os.environ["SUFFIX"],
                }
            ],
        )
    except iam.exceptions.EntityAlreadyExistsException:
        print("Exists, skipping creation")

    iam.update_open_id_connect_provider_thumbprint(
        OpenIDConnectProviderArn="arn:aws:iam::"
        + os.environ["ACCOUNT"]
        + ":oidc-provider/"
        + os.environ["BUCKET_PUBLIC"]
        + ".s3."
        + os.environ["REGION"]
        + ".amazonaws.com/oidc",
        ThumbprintList=[
            fileobjects["thumbprint"],
        ],
    )
    print("Provider up to date.")

    return {"statusCode": 200, "body": json.dumps("Complete")}
