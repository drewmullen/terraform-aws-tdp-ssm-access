terraform {
  required_version = ">= 1.14.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.14.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = ">= 0.58.0"
    }
  }
}
