# SSM access add-on

No-code module for a Terraform Developer Portal add-on. Installing it attaches `AmazonSSMManagedInstanceCore` to the VM template's instance role, which makes the instance a Session Manager managed node. Uninstalling it destroys that attachment and revokes access. The add-on also provides a `patch_now` action.

The VM itself comes from `terraform-aws-tdp-vm`. This module does not create an instance, a security group, or a key pair.

Terraform Developer Portal shows the top of this file as developer instructions when an add-on definition is created with **Update from module's README**. The reference below is for the platform engineer.

## Developer instructions

Install this add-on on an application that was deployed from the VM template. When the install finishes, the VM can accept Session Manager connections. Use `start_session_cli` or `start_session_console`. The AWS identity you connect with also needs permission to start a session.

`aws_lambda_invoke.patch_now` starts `AWS-RunPatchBaseline` with `Operation=Install` on this VM and returns a Run Command id in the action log. The command keeps running after the action finishes. Look up that id in Systems Manager Run Command. The document's default `RebootOption` is `RebootIfNeeded`, so installing a patch reboots the VM.

Uninstall the add-on to remove Session Manager access. New sessions fail after the uninstall apply finishes. The VM keeps running.

## Inputs

| Name | Required | Default | Who sets it |
| --- | --- | --- | --- |
| `developer_portal_application` | yes |  | Terraform Developer Portal |
| `developer_portal_add_on` | yes |  | Terraform Developer Portal. Unique per installation |
| `developer_portal_add_on_definition` | yes |  | Terraform Developer Portal |
| `aws_region` | no | `us-east-1` | Platform. Do not show this to developers. Must match the application |
| `tfc_organization` | yes |  | Platform. Do not show this to developers |
| `app_workspace_name` | no | `null` | Platform override. Leave unset unless the derived workspace name is wrong |

`developer_portal_application` must be 1–56 characters of letters, digits, and hyphens. `developer_portal_add_on` must be 1–58 of the same. Those limits are assumptions until real TDP names are confirmed. See the `# VERIFY:` comments in `variables.tf`.

## How this module finds the VM

Terraform Developer Portal passes names, not the application outputs. This module reads the application workspace with `data.tfe_outputs`:

- `nonsensitive_values.instance_id`
- `nonsensitive_values.instance_role_name`

`aws_region` must equal `nonsensitive_values.aws_region`. The application apply has to have finished so those outputs exist.

The workspace name is `local.app_workspace_name` in `locals.tf`. Until Phase 2 confirms TDP's naming, that local is the application name, and `app_workspace_name` overrides it. The `# VERIFY:` comment marks the placeholder.

The `tfe` provider has no token in configuration. It reads `TFE_TOKEN` from the environment. Phase 2 confirms whether the add-on run's own token can read the application outputs or whether a team token has to be injected. See the `# VERIFY:` comment in `providers.tf`.

## Access grant

`aws_iam_role_policy_attachment.ssm_core` attaches `AmazonSSMManagedInstanceCore` to the template role. The template leaves that role empty and does not manage its attachments exclusively, so this attachment survives an application apply. Uninstalling the add-on is what destroys it.

The current managed policy allows Session Manager (`ssmmessages`) and `ssm:GetDeployablePatchSnapshotForInstance`. It does not allow `s3:GetObject`. Whether that is enough for `AWS-RunPatchBaseline` to install packages is marked `# VERIFY:` in `main.tf`. The VM's security group allows outbound TCP 443 and 80, which is the path package downloads use.

The instance ARN used by the patch function is built from this workspace's account and `aws_region`. The application and the add-on are assumed to share an account. See the `# VERIFY:` comment in `locals.tf`.

## Action

`aws_lambda_invoke.patch_now` (`action.aws_lambda_invoke.patch_now`) is not bound to an `action_trigger`. A normal apply does not patch the VM.

The action invokes a Python 3.12 function this module deploys. The function calls `ssm:SendCommand` for `AWS-RunPatchBaseline` with `Operation=Install`. The instance id comes from the `INSTANCE_ID` environment variable. The action payload is `{}`. The function returns the command id and prints `command_id=...` on the action run (`log_type = "Tail"`). It does not wait for the patch to finish.

The function's role allows `ssm:SendCommand` only on the AWS-owned document ARN (`arn:<partition>:ssm:<region>::document/AWS-RunPatchBaseline`) and this instance's ARN, plus log writes to its log group.

No `RebootOption` is set, so the document default `RebootIfNeeded` applies. Installing one or more patches reboots the instance.

Action arguments were checked against the `hashicorp/aws` 6.14.0 provider schema. That is the minimum version, because 6.14.0 added `aws_lambda_invoke`.

## Outputs

| Name | Value |
| --- | --- |
| `instance_id` | Application instance ID |
| `start_session_cli` | `aws ssm start-session --target <id> --region <region>` |
| `start_session_console` | Regional Session Manager URL for the instance. The exact deep link is unverified. See the `# VERIFY:` comment in `locals.tf` |

## Contract with `terraform-aws-tdp-vm`

Required application outputs, all non-sensitive:

| Output | Use |
| --- | --- |
| `instance_id` | Session commands, the patch function's environment, and the instance ARN |
| `instance_role_name` | Target of the `AmazonSSMManagedInstanceCore` attachment |
| `aws_region` | Must match this module's `aws_region` |
| `instance_profile_name` | Not read. Present so other add-ons can use the same contract |
| `private_ip` | Not read |

Destroy this add-on before deleting the application. If the application workspace is deleted first, `tfe_outputs` cannot refresh and this module's destroy fails. The application destroy can also fail first, because the instance role still has this attachment.

## Provider configuration

`providers.tf` holds the AWS and TFE providers. AWS credentials and the TFE token are not set in the file. A later pass can delete that file when provider configuration moves to an HCP Terraform provider set.

Default tags are `DeveloperPortalApplication`, `DeveloperPortalAddOn`, and `DeveloperPortalAddOnDefinition`.
