terraform {
  required_version = ">= 1.8.0"

  cloud {
    organization = "NT113"

    workspaces {
      name = "aws-enterprise-hub-spoke-network"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
