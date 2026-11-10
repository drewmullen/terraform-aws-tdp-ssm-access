"""Start AWS-RunPatchBaseline with Operation=Install on one instance.

The instance id comes from the INSTANCE_ID environment variable. The invoke
payload is ignored. SendCommand returns as soon as Systems Manager accepts
the command; it does not wait for patching to finish.
"""

import os

import boto3


def handler(event, context):
    del event, context

    instance_id = os.environ["INSTANCE_ID"]
    response = boto3.client("ssm").send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunPatchBaseline",
        Parameters={"Operation": ["Install"]},
        Comment="Terraform Developer Portal patch_now",
    )
    command_id = response["Command"]["CommandId"]
    print(f"command_id={command_id} instance_id={instance_id}")
    return {
        "command_id": command_id,
        "instance_id": instance_id,
        "document_name": "AWS-RunPatchBaseline",
    }
