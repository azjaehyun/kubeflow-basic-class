#!/bin/bash
echo "********************** bastion에 env 파일을 복사합니다. ***********************"
echo "********************** 복사대상은 ssh private key , terraform tfstate file 을 복사합니다. ***********************"
echo "********************** 복사를 위해 현재 경로에 있는 ssh private key file 이름을 입력해주세요. EX) yangjaehyun-keypair ***********************"
read ssh_private_key
echo "********************** 복사를 위해 bastion public ip를 입력해주세요. ***********************"
read bastion_public_ip

echo "********************** bastion에 ssh private key  파일을 복사합니다. ***********************"
scp -i ${ssh_private_key} ${ssh_private_key}  ubuntu@${bastion_public_ip}:~/.ssh
echo "********************** bastion에 10-pre-requisite terraform.tfstate 파일을 복사합니다. ***********************"
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/10-pre-requisite/terraform.tfstate ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/10-pre-requisite/terraform.tfstate
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/10-pre-requisite/.terraform.lock.hcl ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/10-pre-requisite/.terraform.lock.hcl

echo "********************** bastion에 20-vpc-subnet-eks-bastion terraform.tfstate 파일을 복사합니다. ***********************"
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/20-vpc-subnet-eks-bastion/terraform.tfstate ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/20-vpc-subnet-eks-bastion/terraform.tfstate
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/20-vpc-subnet-eks-bastion/.terraform.lock.hcl ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/20-vpc-subnet-eks-bastion/.terraform.lock.hcl

echo "********************** bastion에 40-eks-getting-started terraform.tfstate  파일을 복사합니다. ***********************"
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/40-eks-getting-started/terraform.tfstate ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/40-eks-getting-started/terraform.tfstate
scp -i ${ssh_private_key} ./arch/terraform-middle/dev/40-eks-getting-started/.terraform.lock.hcl ubuntu@${bastion_public_ip}:~/eks-basic-class/3-terraform/arch/terraform-middle/dev/40-eks-getting-started/.terraform.lock.hcl
echo "********************** bastion에 40-eks-getting-started eks-output.txt  파일을 복사합니다. ***********************"
scp -i ${ssh_private_key} ./eks-output.txt ubuntu@${bastion_public_ip}:~/.kube


echo "********************** 아래 명령어로 bastion 서버에 접속합니다. ***********************"
echo "ssh -i  " ${ssh_private_key}  "   ubuntu@"${bastion_public_ip}