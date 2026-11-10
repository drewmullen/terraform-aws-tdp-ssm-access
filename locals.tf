locals {
  # VERIFY: HCP Terraform does not document how Terraform Developer Portal
  # names the workspace it creates for an application. This placeholder is
  # the application name unchanged. Phase 2 replaces this expression after a
  # throwaway application shows the real name. Set app_workspace_name to
  # override it without editing this expression.
  app_workspace_name = coalesce(var.app_workspace_name, var.developer_portal_application)

  instance_id        = data.tfe_outputs.application.nonsensitive_values.instance_id
  instance_role_name = data.tfe_outputs.application.nonsensitive_values.instance_role_name

  # VERIFY: the instance ARN is built in this workspace's AWS account and
  # var.aws_region. The application and this add-on are assumed to use the
  # same account. A region mismatch is rejected by the ssm_core precondition.
  instance_arn = "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/${local.instance_id}"

  # AWS-owned documents use an empty account segment, for example
  # arn:aws:ssm:us-east-1::document/AWS-RunPatchBaseline.
  patch_document_arn = "arn:${data.aws_partition.current.partition}:ssm:${var.aws_region}::document/AWS-RunPatchBaseline"

  patch_function_name = "${var.developer_portal_add_on}-patch"

  # VERIFY: AWS documents the Session Manager console home and the
  # start-session CLI, not an instance deep link. This URL is the regional
  # console path used by the Session Manager instance page.
  start_session_console = "https://${var.aws_region}.console.aws.amazon.com/systems-manager/session-manager/${local.instance_id}?region=${var.aws_region}"
}
