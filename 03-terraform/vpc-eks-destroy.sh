#!/bin/bash
echo " cleansing start"

echo "********************** 30 - eks destory ***********************"
echo "eks 삭제를 원하시면 y를 입력해주세요"
read eks_y_value
if [ "$eks_y_value" == "y" ]; then
   terraform -chdir=arch/terraform-middle/dev/40-eks-getting-started init
   terraform -chdir=arch/terraform-middle/dev/40-eks-getting-started destroy --auto-approve
else
    echo ""
fi

echo "********************** 20 - vpc & subnet destory ***********************"
echo "vpc subnet 삭제를 원하시면 y를 입력해주세요"
read vpc_y_value
if [ "$vpc_y_value" == "y" ]; then
   terraform -chdir=arch/terraform-middle/dev/20-vpc-subnet-eks-bastion init
   terraform -chdir=arch/terraform-middle/dev/20-vpc-subnet-eks-bastion destroy --auto-approve
else
    echo ""
fi
echo " cleansing finish"


echo "********************** 10 - pre-requisite ***********************"
echo "10 - pre-requisite keypair 삭제를 원하시면 y를 입력해주세요"
read vpc_y_value
if [ "$vpc_y_value" == "y" ]; then
   terraform -chdir=arch/terraform-middle/dev/10-pre-requisite  init
   terraform -chdir=arch/terraform-middle/dev/10-pre-requisite  destroy --auto-approve
else
    echo ""
fi
echo " cleansing finish"






















