terraform {
  required_version = ">=0.12.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.45, < 4"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}