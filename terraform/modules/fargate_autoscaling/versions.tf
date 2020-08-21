terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.63.0"
    }
    local = {
      source = "hashicorp/local"
    }
    template = {
      source = "hashicorp/template"
    }
  }
}