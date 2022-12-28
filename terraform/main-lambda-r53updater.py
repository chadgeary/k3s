import os

import boto3


def lambda_handler(event, context):

    # get healthy instance ids from asg
    client = boto3.client("autoscaling")
    response = client.describe_auto_scaling_groups(
        Filters=[
            {
                "Name": "tag-value",
                "Values": [
                    "control-plane."
                    + os.environ["PREFIX"]
                    + "-"
                    + os.environ["SUFFIX"]
                    + ".internal"
                ],
            }
        ]
    )
    InstanceIds = []
    for instance in response["AutoScalingGroups"][0]["Instances"]:
        if instance["HealthStatus"] == "Healthy":
            InstanceIds.append(instance["InstanceId"])

    # get private ips of instances
    if InstanceIds:
        print("INFO: InstanceIds " + " ".join(InstanceIds))
        client = boto3.client("ec2")

        ResourceRecords = []
        response = client.describe_instances(InstanceIds=InstanceIds)
        for instance in response["Reservations"][0]["Instances"]:
            # [{Value: IP},]
            ResourceRecords.append({"Value": instance["PrivateIpAddress"]})
    else:
        print("INFO: No InstanceIds")

    # set a record to ips
    if ResourceRecords:
        client = boto3.client("route53")
        response = client.change_resource_record_sets(
            HostedZoneId=os.environ["HOSTED_ZONE_ID"],
            ChangeBatch={
                "Comment": "by r53updater.py",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": "control-plane."
                            + os.environ["PREFIX"]
                            + "-"
                            + os.environ["SUFFIX"]
                            + ".internal",
                            "Type": "A",
                            "TTL": 60,
                            "ResourceRecords": ResourceRecords,
                        },
                    }
                ],
            },
        )
    else:
        print("INFO: No ResourceRecords")
