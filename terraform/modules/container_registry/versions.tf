terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.45, < 4"
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
  required_version = ">=0.12.13, < 0.14"
}
