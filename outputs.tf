output "instance_id" {
  description = "ID of the application VM this add-on granted Session Manager access to."
  value       = local.instance_id
}

output "start_session_cli" {
  description = "AWS CLI command that opens a Session Manager session to the VM. The caller also needs ssm:StartSession."
  value       = "aws ssm start-session --target ${local.instance_id} --region ${var.aws_region}"
}

output "start_session_console" {
  description = "Session Manager console URL for this VM. See the VERIFY comment on local.start_session_console."
  value       = local.start_session_console
}
