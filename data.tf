data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "tfe_outputs" "application" {
  organization = var.tfc_organization
  workspace    = local.app_workspace_name
}
