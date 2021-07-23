terraform {
  required_version = ">= 0.12.13, < 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.63"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}