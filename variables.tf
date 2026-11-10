variable "app_workspace_name" {
  description = "Workspace name of the application this add-on is installed on. Leave unset to use the derived name in locals.tf."
  type        = string
  default     = null

  validation {
    condition     = var.app_workspace_name == null || length(var.app_workspace_name) > 0
    error_message = "app_workspace_name must be null or the application workspace name."
  }
}

variable "aws_region" {
  description = "Region of the application VM and this add-on's function. Platform-fixed: do not show this to developers. Must match the application output aws_region."
  type        = string
  default     = "us-east-1"
}

variable "developer_portal_add_on" {
  description = "Installed add-on name. Terraform Developer Portal sets this. It is unique per installation and is the prefix for this add-on's function and role."
  type        = string

  # VERIFY: TDP does not document add-on name rules. The tutorial uses
  # letters, digits, and hyphens. "${name}-patch" must fit in 64 characters.
  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.developer_portal_add_on)) &&
      length(var.developer_portal_add_on) <= 58
    )
    error_message = "developer_portal_add_on must be 1-58 characters of letters, digits, and hyphens so derived IAM and Lambda names stay within AWS limits."
  }
}

variable "developer_portal_add_on_definition" {
  description = "Add-on definition name. Terraform Developer Portal sets this. Used as a tag so the function can be traced back to the definition."
  type        = string

  validation {
    condition     = length(var.developer_portal_add_on_definition) > 0 && length(var.developer_portal_add_on_definition) <= 256
    error_message = "developer_portal_add_on_definition must be 1-256 characters."
  }
}

variable "developer_portal_application" {
  description = "Application name. Terraform Developer Portal sets this. It selects the application workspace and is the DeveloperPortalApplication tag."
  type        = string

  # VERIFY: same name rules as the VM template. TDP does not document them.
  validation {
    condition = (
      can(regex("^[A-Za-z0-9-]+$", var.developer_portal_application)) &&
      length(var.developer_portal_application) <= 56
    )
    error_message = "developer_portal_application must be 1-56 characters of letters, digits, and hyphens."
  }
}

variable "tfc_organization" {
  description = "HCP Terraform organization that owns the application workspace. Platform-fixed: do not show this to developers."
  type        = string

  validation {
    condition     = length(var.tfc_organization) > 0
    error_message = "tfc_organization must be the HCP Terraform organization name."
  }
}
