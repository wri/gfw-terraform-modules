# Batch Compute Environment - ephemeral storage

Terraform module creates a AWS Batch compute Environment using SPOT-EC2 instances with ephemeral storage.

Compute Environment will choose from R5d and C5d EC2 instance families and mount one of the available ephemeral storage device (SSD drive) as `/tmp`.

## Usage

```terraform
module "compute_environment_ephemeral_storage" {
  source             = "git::git@github.com:wri/gfw-terraform-modules.git//modules/compute_environment_ephemeral_storage?ref=v0.0.1"
  project            = "my-project"
  key_pair           = "my-key"
  subnets            = aws_subnet.public.*.id
  tags               = { Name = my-project }
  security_group_ids = [aws_security_group.default.id]
  iam_policy_arn     = [data.templatefile.ecs_policy.rendered]
}
```

## Inputs

| Name               | Description                                        |  Type        |  Default   | Required |
| ------------------ | -------------------------------------------------- | :----------: | :--------: | :------: |
| project            | Project name, used as prefix for resources         | string       |    n/a     |   yes    |
| key_pair           | Key pair to logon to EC2 instance                  | string       |    n/a     |   yes    |
| subnets            | Subnets in which the compute environment can run   | list(string) |    n/a     |   yes    |
| tags               | Tags used to tag resources                         | map(string)  |    n/a     |   yes    |
| security_group_ids | Security groups attached to EC2 instances          | list(string) |    n/a     |   yes    |
| iam_policy_arn     | Policies attached to ECS instance role             | list(string) |    n/a     |   yes    |
| suffix             | Suffix which will be attached to resource names    | string       |    `""`    |    no    |

## Outputs

| Name | Description                        |
| ---- | ---------------------------------- |
| arn  | ARN of compute environment         |
