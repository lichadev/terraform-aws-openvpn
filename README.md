# AWS OpenVPN Terraform module

Terraform module which creates an OpenVPN EC2 instance in AWS.

## Usage

#### Terraform required version >= 0.14.8

## OpenVPN Service

```hcl
module "openvpn" {
    source              = "github.com/nimbux911/terraform-aws-openvpn.git"
    stack_name          = "${var.env}-openvpn"
    vpc_id              = "vpc-abcde12345"
    instance_type       = "t3.small"
    subnet_id           = "subnet-abcde12345"
    peered_networks     = ["172.16.0.0/16", "172.17.0.0/16"]
    tags                = local.common_tags
    ssm_parameters_path = "/terraform/ec2-openvpn/"
    ssh_ingress_cidrs   = ["123.22.12.53/32"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| compose\_cidr | CIDR for default compose network. | `string` | `"192.168.127.1/24"` | no |
| docker\_cidr | CIDR for default docker network. | `string` | `"192.168.125.1/24"` | no |
| instance\_type | OpenVPN EC2 instance type. | `string` | `"t3a.micro"` | no |
| peered\_networks | CIDRs blocks which OpenVPN will be able to route the traffic to/from. | `list(string)` | `[]` | no |
| ssh\_ingress\_cidrs | CIDR blocks to allow ssh access to the OpenVPN instance. | `list(string)` | `[]` | no |
| ssm\_parameters\_path | Path prefix for ssm parameters. | `string` | `""` | no |
| stack\_name | Name for the stack resources. | `string` | `"openvpn"` | no |
| subnet\_id | Public subnet id to host the OpenVPN instance. | `string` | ` ` | yes |
| tags | Tags to add to the stack resources. | `map` | `{}` | no |
| ubuntu\_ami\_id | Custom Ubuntu AMI id for the OpenVPN instance. | `string` | `""` | no |
| volume\_path | Path to mount the data fs. | `string` | `"/openvpn/"` | no |
| vpc\_id | VPC id where the OpenVPN will be hosted. | `string` | ` ` | yes |
| dns\_name | DNS name that points to elastic ip  | `string` | ` ` | no |


## Outputs

| Name | Description |
|------|-------------|
| autoscaling\_group\_id | The ID of the autoscaling group. |
| data\_volume\_id | The ID of the data EBS volume. |
| eip\_public\_ip | The public address of the eip. |
| iam\_role\_arn | The instance role ARN. |
| security\_group\_id | The ID of the security group. |

