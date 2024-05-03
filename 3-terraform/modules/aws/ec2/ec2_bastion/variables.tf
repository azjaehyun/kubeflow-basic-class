variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "sg_groups" {
  type = list(string)
}

variable "subnet_id" {
  type = string
}

variable "public_access" {
  type    = bool
  default = false
}

variable "ami_id" {
  type    = string
  description = "us-west-2 리전에는 ami-0871d1355365588e9 입력 - 멘토가 미리 만들어놓음 "
  default = ""
}

variable "name" {
  type    = string
  default = "myapp"
}

variable "key_name" {
  type = string
  description = " 키페어 메뉴에 들어가서 본인의 해당 키 페어 이름 복사해서 넣어주세요. " 
}


variable "tag_name" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}