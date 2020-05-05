variable "image_name" {
  description = "Name of Docker image"
  type        = string
}

variable "root_dir" {
  description = "Root dir used in Dockerfile"
  type        = string
  default     = "."
}

variable "docker_path" {
  description = "Path to Docker image source, relative to root dir"
  type        = string
  default     = "."
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "hash_script" {
  description = "Path to script to generate hash of source contents"
  type        = string
  default     = ""
}

variable "push_script" {
  description = "Path to script to build and push Docker image"
  type        = string
  default     = ""
}
