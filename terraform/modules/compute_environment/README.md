# Batch Compute Environment - optional ephemeral storage

Terraform module creates a AWS Batch compute Environment using SPOT-EC2 instances with optional ephemeral storage.

If ephemeral storage is selected (default), Compute Environment will choose from R5d and C5d EC2 instance families
and mount one of the available ephemeral storage device (SSD drive) as `/tmp`.
It will use the second available ephemeral storage device as SWAP drive.

## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.12.13, < 0.14 |


## Providers

| Name | Version |
|------|---------|
| aws | >= 2.45, < 4 |
| local | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bid\_percentage | n/a | `number` | `100` | no |
| allocation\_strategy | [The allocation strategy defines behavior when AWS Batch needs additional capacity](https://docs.aws.amazon.com/batch/latest/userguide/allocation-strategies.html) | `string` | `BEST_FIT` | no |
| compute\_environment\_name | n/a | `string` | `"ephemeral_storage"` | no |
| ebs\_volume\_size | n/a | `number` | `8` | no |
| ecs\_role\_policy\_arns | n/a | `list(string)` | n/a | yes |
| instance\_types | n/a | `list(string)` | <pre>[<br>  "r5d.4xlarge",<br>  "r5d.8xlarge",<br>  "r5d.12xlarge",<br>  "r5d.16xlarge",<br>  "r5d.24xlarge",<br>  "c5d.12xlarge",<br>  "c5d.18xlarge",<br>  "c5d.24xlarge"<br>]</pre> | no |
| key\_pair | n/a | `string` | n/a | yes |
| launch\_type | n/a | `string` | `"SPOT"` | no |
| max\_vcpus | n/a | `number` | `256` | no |
| min\_vcpus | n/a | `number` | `0` | no |
| project | n/a | `string` | n/a | yes |
| security\_group\_ids | n/a | `list(string)` | n/a | yes |
| subnets | n/a | `list(string)` | n/a | yes |
| suffix | n/a | `string` | `""` | no |
| tags | n/a | `map(string)` | n/a | yes |
| use\_ephemeral\_storage | n/a | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| arn | n/a |


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
