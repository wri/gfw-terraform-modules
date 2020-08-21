terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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
  required_version = ">= 0.13"
}
