# Batch Compute Environment - optional ephemeral storage

Terraform module creates a AWS Batch compute Environment using SPOT-EC2 instances with optional ephemeral storage.

If ephemeral storage is selected (default), Compute Environment will choose from R5d and C5d EC2 instance families 
and mount one of the available ephemeral storage device (SSD drive) as `/tmp`. 
It will use the second available ephemeral storage device as SWAP drive.


## Usage

```terraform
module "compute_environment_ephemeral_storage" {
  source               = "git::git@github.com:wri/gfw-terraform-modules.git//modules/compute_environment_ephemeral_storage?ref=v0.0.1"
  project              = "my-project"
  key_pair             = "my-key"
  subnets              = aws_subnet.public.*.id
  tags                 = { Name = my-project }
  security_group_ids   = [aws_security_group.default.id]
  ecs_role_policy_arns = [data.templatefile.ecs_policy.rendered]
}
```

## Inputs

| Name                     | Description                                                                                                 |  Type        |  Default            | Required |
| ------------------------ | ----------------------------------------------------------------------------------------------------------- | :----------: | :-----------------: | :------: |
| project                  | Project name, used as prefix for resources                                                                  | string       |         n/a         |   yes    |
| key_pair                 | Key pair to logon to EC2 instance                                                                           | string       |         n/a         |   yes    |
| subnets                  | Subnets in which the compute environment can run                                                            | list(string) |         n/a         |   yes    |
| tags                     | Tags used to tag resources                                                                                  | map(string)  |         n/a         |   yes    |
| security_group_ids       | Security groups attached to EC2 instances                                                                   | list(string) |         n/a         |   yes    |
| ecs_role_policy_arns     | Policies attached to ECS instance role                                                                      | list(string) |         n/a         |   yes    |
| suffix                   | Suffix which will be attached to resource names                                                             | string       |         `""`        |    no    |
| use_ephemeral_storage    | Use Ephermeral Storage, if set, don't change ec2 instance types                                             | bool         |       `true`        |    no    |
| ebs_volume_size          | Size of root device. Ignored if use_ephermeral_storage is true                                              | number       |         `8`         |    no    |
| bid_percentage           | Percentage of regular price to bid for Spot instance                                                        | number       |        `100`        |    no    |
| max_vcpus                | Max number of vCPUs for Compute Environment                                                                 | number       |        `256`        |    no    |
| min_vcpus                | Min number of vCPUs for Compute Environment                                                                 | number       |         `0`         |    no    |
| compute_environment_name | Name of the compute environment (must be set if multiple compute environments are used for the same project | string       | `ephemeral_storage` |   yes    |


variable "compute_environment_name" {
  type = string
  default = "ephemeral_storage"
}

## Outputs

| Name | Description                        |
| ---- | ---------------------------------- |
| arn  | ARN of compute environment         |
