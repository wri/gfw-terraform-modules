# AWS Fargate Service with autoscaling

Terraform module to create an AWS Fargate Service with autoscaling.

- Creates Fargate service using provided container definition 
- Creates new Application Load Balancer or uses user defined ALB


## Usage

```terraform

module "fargate_autoscaling" {
  source                       = "git::https://github.com/wri/gfw-terraform-modules.git//modules/fargate_autoscaling"
  project                      = "my-project"
  name_suffix                  = "my-workspace"
  tags                         = { BuiltBy     = "Terraform" }
  vpc_id                       = vpc_id
  private_subnet_ids           = []
  public_subnet_ids            = data.terraform_remote_state.core.outputs.public_subnet_ids
  container_name               = var.container_name
  container_port               = var.container_port
  listener_port                = var.listener_port
  desired_count                = var.desired_count
  fargate_cpu                  = var.fargate_cpu
  fargate_memory               = var.fargate_memory
  auto_scaling_cooldown        = var.auto_scaling_cooldown
  auto_scaling_max_capacity    = var.auto_scaling_max_capacity
  auto_scaling_max_cpu_util    = var.auto_scaling_max_cpu_util
  auto_scaling_min_capacity    = var.auto_scaling_min_capacity
  security_group_ids           = [data.terraform_remote_state.core.outputs.postgresql_security_group_id]
  task_role_policies           = [data.terraform_remote_state.core.outputs.iam_policy_s3_write_data-lake_arn]
  task_execution_role_policies = [data.terraform_remote_state.core.outputs.secrets_postgresql-reader_policy_arn, data.terraform_remote_state.core.outputs.secrets_postgresql-writer_policy_arn]
  container_definition         = data.template_file.container_definition.rendered

}

```

## Inputs

| Name                         | Description                                        |  Type        |  Default   | Required |
| ---------------------------- | -------------------------------------------------- | :---------:  | :--------: | :------: |
| project                      | Project name, uses as prefix for resource names    | string       |    n/a     |    yes   |
| name_suffix                  | Name suffix for resource names                     | string       |    n/a     |    no    |
| tags                         | Tags for resources                                 | map(string)  |     .      |    yes   |
| vpc_id                       | VPC ID for fargate cluster                         | string       |    n/a     |    yes   |
| private_subnet_ids           | Private subnet ids for fargate cluster             | list(string) |    n/a     |    yes   |
| public_subnet_ids            | Public subnet ids for load balancer                | list(string) |    n/a     |    yes   |
| container_name               | Container Name                                     | string       |    n/a     |    yes   |
| container_port               | Port the container is listing to                   | number       |    n/a     |    yes   |
| listener_port                | Port the load balancer is listing to               | number       |     80     |    no    |
| desired_count                | Desired task count                                 | number       |      1     |    no    |
| fargate_cpu                  | CPU count for task                                 | number       |      1     |    no    |
| fargate_memory               | Memory in MB for task                              | number       |     512    |    no    |
| auto_scaling_cooldown        | Autoscaling cooldown periode in seconds            | number       |     300    |    no    |
| auto_scaling_max_capacity    | Autoscaling max capacity                           | number       |      1     |    no    |
| auto_scaling_max_cpu_util    | CPU utilization threshold to trigger autoscaling   | number       |      75    |    no    |
| auto_scaling_min_capacity    | Autoscaling min capacity                           | number       |      1     |    no    |
| security_group_ids           | List of security group ids for task                | list(string) |     n/a    |    yes   |
| task_role_policies           | Policies for task role                             | list(string) |     `[]`   |    no    |
| task_execution_role_policies | Policies for task execution role                   | list(string) |     `[]`   |    no    |
| container_definition         | Container definition file (JSON)                   | string       |      n/a   |    yes   |

## Outputs

| Name                  | Description                        |
| --------------------- | ---------------------------------- |
| ecs_security_group_id | Security group of ECS cluster      |
| lb_dns_name           | Load Balancer DNS name             |
