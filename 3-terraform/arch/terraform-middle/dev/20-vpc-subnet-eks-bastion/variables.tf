variable "context" {
  type = object({
    aws_credentials_file    = string # describe a path to locate a credentials from access aws cli
    aws_profile             = string # describe a specifc profile to access a aws cli
    aws_region              = string # describe default region to create a resource from aws
    region_alias            = string # region alias or AWS
    project                 = string # project name is usally account's project name or platform name
    environment             = string # Runtime Environment such as develop, stage, production
    env_alias               = string # Runtime Environment such as develop, stage, production
    owner                   = string # project owner
    team                    = string # Team name of Devops Transformation
    generator_date          = string # generator_date
    domain                  = string # public domain name (ex, tools.customer.co.kr)
    pri_domain              = string # private domain name (ex: toolchain)
    #access_key              = string
    #secret_key              = string
  })
}


variable "vpc_cidr" {
  description = "Netmask B Class bandwidth for VPC CIDR"
  type        = string
}

variable "keypair_name" {
  description = "ec2 key pair name (키 페어 메뉴에서 생성된 본인의 키페어 이름을 넣어주세요.)"
  type        = string
  validation {
    condition     = can(regex("keypair$", var.keypair_name))
    error_message = "The variable must end with keypair."
  }
}

variable "bastion_ami_id" {
  description = "bastion_ami_id (AMI 메뉴에서 앞서 packer로 생성한 본인이 AMI id 값을 넣어주세요.)"
  type        = string
  #default = "ami-09370ebbf30fffa1c"
  validation {
    condition     = can(regex("^ami-", var.bastion_ami_id))
    error_message = "AMI ID must start with ami."
  }
}


locals {
  name_prefix               = format("%s-%s%s", var.context.project, var.context.region_alias, var.context.env_alias)
  tags = {
    Project     = var.context.project
    Environment = var.context.environment
    Team        = var.context.team
    Owner       = var.context.owner
  }
}
