# pre-requisite
eks basic class를 위한 사전 환경을 구성 합니다.

## Build
```shell
git clone https://github.com/azjaehyun/eks-basic-class.git
cd ./eks-basic-class/10-terraform/arch/terraform-middle/dev/10-pre-requisite
ssh-keygen -t rsa -b 2048 -m pem -f yangjaehyun-key
cd ..
main.tf ## 부분 수정 후 


terraform init
terraform plan
terraform apply
```

## Checking
AWS CLI 를 통해 구성 내역을 확인 할 수 있습니다.
```shell
aws cli ....
```