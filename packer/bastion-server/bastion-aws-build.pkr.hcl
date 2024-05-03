packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "amzn2" {
  ami_name      = "eks-bastion-packer-ubuntu" # AMI 이름을 지정해주세요.
  instance_type = "t2.micro" # 인스턴스 타입
  region        = "us-west-2" # 생성할 리전 명시


  subnet_filter {
    filters = {
        "tag:Name": "*default-public*"  #subnet 필터. default public subnet A zone 에 이름을 default-public으로 변경해주세요.
    }
  }
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20231025"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"

  tags = {
    Name        = "jaehyun.yang@bespinglobal.com" # 본인의 계정 아이디를 넣어주세요.
    Environment = "dev"
  }
}


build {
  name = "learn-packer"
  sources = [
    "source.amazon-ebs.amzn2"  
  ]

  provisioner "shell" {
     script  = "provision-bastion.sh"
  }
}