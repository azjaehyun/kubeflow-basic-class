### eks-basic-class
해당 챕터에서는 eks service에 필요한 lib를 설치하고 실습합니다.
---

- eks service를 진행하면서 필요한 lib를 설치하고 셋팅합니다.
  * 설치 목록
  * aws-load-balancer-controller policy 생성
  * aws-load-balancer-controller policy serviceaccount 생성
  * oidc-provider 설치
  * cert manager 설치
- 실습 - k8s Service 종류 실습
  * clb 
  * alb
  * ingress 
  * NodePort
  * CluserIP

## install 가이드

### aws-load-balancer-controller 설치 document 참고하세요.
```
- https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html
```
---


### aws-load-balancer-controller policy 생성

-  policy 다운로드
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
```
  


- 다운로드후 160~165 라인 삭제 후 아래 명령어 실행. 아래부분 삭제
```
160             "Condition": {
161                 "Null": {
162                     "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
163                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
164                 }
165             }
```


- 하지만 bespin-cne 계정에는 이미 만들어져 있기 때문에 아래 명령어 poliy 생성은 생략 가능.
  * 새로 꼭 생성하고 싶으면 AWSLoadBalancerControllerIAMPolicy 이름을 다른 이름으로 생성!! 
```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

### oidc-provider 설치
```
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=eks-basic-uw2d-yangjaehyun-k8s --approve
```
---  
- 실행후 결과
```
2024-01-26 04:34:19 [ℹ]  will create IAM Open ID Connect provider for cluster "eks-basic-uw2d-k8s" in "us-west-2"
2024-01-26 04:34:19 [✔]  created IAM Open ID Connect provider for cluster "eks-basic-uw2d-k8s" in "us-west-2"
```

### aws-load-balancer-controller serviceaccount 생성
```
eksctl create iamserviceaccount \
  --cluster=eks-basic-uw2d-yangjaehyun-k8s \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::767404772322:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --override-existing-serviceaccounts
```
---
```
- 실행후 결과 
2024-01-26 05:00:09 [ℹ]  1 iamserviceaccount (kube-system/aws-load-balancer-controller) was included (based on the include/exclude rules)
2024-01-26 05:00:09 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2024-01-26 05:00:09 [ℹ]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "kube-system/aws-load-balancer-controller",
        create serviceaccount "kube-system/aws-load-balancer-controller",
    } }2024-01-26 05:00:09 [ℹ]  building iamserviceaccount stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2024-01-26 05:00:09 [ℹ]  deploying stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2024-01-26 05:00:10 [ℹ]  waiting for CloudFormation stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2024-01-26 05:00:40 [ℹ]  waiting for CloudFormation stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2024-01-26 05:00:40 [ℹ]  created serviceaccount "kube-system/aws-load-balancer-controller"
```


### aws-load-balancer-controller serviceacount checking 명령어
```
kubectl get serviceaccounts -n kube-system aws-load-balancer-controller -o yaml
```
---
- 실행 후 결과
```
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::767404772322:role/AmazonEKSLoadBalancerControllerRole
  creationTimestamp: "2024-01-26T05:00:40Z"
  labels:
    app.kubernetes.io/managed-by: eksctl
  name: aws-load-balancer-controller
  namespace: kube-system
  resourceVersion: "46593"
  uid: d820993f-2dc7-41d3-8384-5e9747b8dbdc
```

### aws-load-balancer-controller serviceacount delete 명령어
```
eksctl delete iamserviceaccount \
  --cluster=eks-basic-uw2d-yangjaehyun-k8s \
  --namespace=kube-system \
  --name=aws-load-balancer-controller
```

###  [cert manager 설치](https://cert-manager.io/docs/installation/)
```
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.4.1/cert-manager.yaml
```

### eks에 aws-load-balancer-controller를 설치하자!!  [ 설치하기전에 ]
- [ingress controller yaml down](https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml)
- wget https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml 
- 해당 파일은 aws-load-balancer-yaml 폴더 안에 있습니다.
- download 후 863 line에 본인의 클러스터 이름으로 수정!! EX) - --cluster-name=eks-basic-uw2d-yangjaehyun-k8s
- 596 ~ 603 line 인 serviceaccount는 삭제!! 왜냐면 위에서 serviceacount 를 생성했기 때문
- 수정이 완료 되었으면 k8s에 적용하자
  * 꼭 적용하기전에 위에 선행작업으로 cert-manager.yaml 를 설치해야 한다.

```
kubectl apply -f v2_5_4_full.yaml 
```

### aws-load-balancer-controller pod 체크 [ Running 체크 ]
```
kubectl get pod -n kube-system | grep aws-load-balancer-controller
```