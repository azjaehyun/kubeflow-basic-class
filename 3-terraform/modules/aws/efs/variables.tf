

variable "efs_sg_name" {
  type = string
  description = " AWS NFS 생성시 사용할 이름을 입력해주세요." 
}


variable "vpc_id" {
  type = string
  description = " AWS NFS 생성시 사용할 이름을 입력해주세요." 
}

variable "cidr_block" {
  type    = list(string)

}


variable "private_subnets" {
  type    = list(string)
}



variable "tag_name" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}