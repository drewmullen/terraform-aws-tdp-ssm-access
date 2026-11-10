# Isolated so a later pass can delete this file and supply these providers
# from an HCP Terraform provider set. AWS credentials are not configured
# here. The workspace receives them from the organization variable set.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      DeveloperPortalApplication     = var.developer_portal_application
      DeveloperPortalAddOn           = var.developer_portal_add_on
      DeveloperPortalAddOnDefinition = var.developer_portal_add_on_definition
    }
  }
}

# VERIFY: Phase 2 confirms which token this provider actually uses. No token
# is set here. The provider reads TFE_TOKEN from the environment, which will
# be either the add-on run's own token or a team token injected as a variable.
provider "tfe" {
  hostname = "app.terraform.io"
}
