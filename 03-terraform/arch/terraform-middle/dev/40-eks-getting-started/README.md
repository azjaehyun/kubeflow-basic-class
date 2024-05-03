## 1. EKS를 생성합니다.
~~~
> cd terra-middle-class/terraform/arch/terraform-middle/dev/40-eks-getting-started
> terraform init
> terrform apply
> terraform apply
~~~

## 2. 실행 결과
~~~
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

config_map_aws_auth = <<EOT


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::767404772322:role/terra-middle-class-test-an2p-eks-node
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

EOT
kubeconfig = <<EOT


apiVersion: v1
clusters:
- cluster:
    server: https://538B4773A0671664FF48B2317BBCCDAF.gr7.ap-northeast-2.eks.amazonaws.com
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBR   .... 생략 
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - --region
        - ap-northeast-2
        - eks
        - get-token
        - --cluster-name
        - terra-middle-class-test-an2p-eks
      env:
      - name: AWS_PROFILE
        value: jaehyun.yang@bespinglobal.com

EOT
~~~


## 2. [.kube] config 적용
~~~

cd ~
mkdir .kube
vi config // vi에 terraform으로 실행되고 나온 kubeconfig 복사해서 넣기!

Check 1.
> kubectl get nodes // 확인
NAME                                             STATUS   ROLES    AGE    VERSION
ip-40-40-2-154.ap-northeast-2.compute.internal   Ready    <none>   6m9s   v1.22.15-eks-fb459a0

Check 2.
> kubectl describe configmap aws-auth  -n kube-system
Name:         aws-auth
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
mapRoles:
----
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::767404772322:role/terra-middle-class-test-an2p-eks-node
  username: system:node:{{EC2PrivateDNSName}}

Events:  <none>
~~~