terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4, < 5"
    }
    external = {
      source = "hashicorp/external"
    }
    null = {
      source = "hashicorp/null"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">=1.0.11"
}