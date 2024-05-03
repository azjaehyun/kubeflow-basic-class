# 사전 작업 
- 2-cloud9  폴더 packer 이미지 생성 후 3-terraform 을 진행합니다.

### terraform을 활용한 aws 2tier infra 생성 , keypair 생성 , bastion 생성 , eks 생성
- 아래의 쉘로 한방에 구축을 진행합니다.
```
./vpc-eks-apply.sh
```

- 위의 쉘 실행후 셋팅 방법입니다.  [ << 부분이 입력하는 부분  ]
  

```
********************** Make AWS credentials Setting ***********************
AWS Access Key ID [****************ZPMM]:   <<  입력
AWS Secret Access Key [****************ESmI]:  <<  입력
Default region name [us-west-2]:  <<  입력
Default output format [json]:  <<  입력
********************** Show AWS credentials  ***********************
/home/ec2-user/.aws/credentials
********************************************************************
********************** Terraform install ***********************
테라폼 cli 설치가 필요하시면 y를 입력해주세요
y <<  y 입력하면 설치 y 아니면 미설치 
********************** Terraform install finish ***********************
********************** keypair Make Start ***********************
ssh-keygen key를 생성합니다. key file 이름을 입력해주세요. 본인 영문명을 넣어주시면 됩니다. EX) yangjaehyun 
yangjaehyun  <<  본인 영문명 입력
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): << 그냥 엔터
Enter same passphrase again: << 그냥 엔터
Your identification has been saved in yangjaehyun-keypair
Your public key has been saved in yangjaehyun-keypair.pub
The key fingerprint is:
SHA256:fS/DPEoI+e/npjXr26H8sggmYx6r3vlHi9VqV681xEY ec2-user@ip-172-31-43-99.us-west-2.compute.internal
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|                 |
|               E |
|       . .    o  |
|      o S ...  + |
|       o .o+..+  |
|      = =+.oO.oo.|
|     + B.+===O oo|
|   .o.=..+*BO=+. |
+----[SHA256]-----+
 만들어진 공개키는 아래와 같습니다 
ssh-rsa adfafafa/PTcyb1dEnsAfchM1+cTAqnEs4Pr1NN5uS8od6SsgwXGYcEWE71vTIdBxS5uFBfRHG+SBPX+u+ov5TS8Zd/vevg9NRZde4L67XzA8j9Q8Kfr1Sgs7q2YMuCNqM49oiCZ6iF8H4d3+QhaZmTTnFbBafFBlynXLW9VG/iWjfJAqYufpvu1+HZo2Tffc+Nc938MZ7WUpYeiwffi6ml/adfa ec2-user@ip-172-31-43-99.us-west-2.compute.internal
 만들어진 개인키는 아래와 같습니다 
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAtjRAEkYkrE8Y1wJi257JjRNk/XhURmW8sIicVItx+FrlSfVF
mB/fdbQAHxwfCtuh99kweh2jUol8LAu26THiqFTbGnbhOrkC3szUeehOxi7TvHbr
Pz03Mm9XRJ7AH3ITNfnEwKpxLOD69TTebkvKHekrIMFxmHBFhO9b0yHQcUubhQX0
RxvkgT1/rvqL+U0vGXf73r4PTUWXXuC+u18wPI/UPCn69UoLO6tmDLgjajOPaIgm
eohfB+Hd/kIWmZk05xWwWnxQZcp1y1vVRv4lo3yQKmLn6b7tfh2aNk333PjXPd/D
Ge1lKWHosH34uppf4VFHbDqgGsl2xadfafafnMtPnbEyH+kCgYA/QaXmKu0dahmx
NR4B3E1lwxrWSINQ4VridgaaNXRXRRo3uQ2ijyJsGumKf0C39a4llEhLmkBsEcw8
MjqYtBBptSIYETePQpCvmPUJL/FbatJh+rXyB8jmAWoHNRpZ1Q/XPPVl9lgNaYQK
NRYsO5GOz331tKRBNTRbOQKBgH8tLnTfRqfBa5kvNqgw0YACgyqzK9UPFU1S5TNE
crIXgwux6wv1cE+qWqHWiulx6D59Ob2WL3nATczmDafCxpmGeHVYaP23Jun7xiZ5
UDiDwP0o/q64zCHfAzV53y0LRCcoEqiJfTjdW6KtNhjeDeMxJ8SjpDAduCynvMKY
JIfRAoGBAJsrSt8z9nVOpJQDxENfP4jIxSjgYjV/3swxH0QZcLNK6Es725HV9x/a
mLCGi8/VG4KM9SVXJSCUb05LFKiqmuUiwHNLlPyt0FKKAEDXpWE9uKhX2076PrvS
YtUAmtx2MwfFNqb/1h8cQZPEOJXF1o7xCxUX9PQT4IWZIkikcv8b//CNE
-----END RSA PRIVATE KEY-----
 생성된 개인키와 공개키는 테라폼 구성을 위해 ./arch/terraform-middle/dev/10-pre-requisite/template/ 경로로 복사합니다
********************** keypair Make Finish ***********************
********************** terraform tfvars owner 변수를 변경합니다 ****************************
********************** 본인의 이름을 영어로 입력하세요 ex) yang.jaehyun **************************
yangjaehyun
********************** terraform tfvars setting  **********************
********************** 10-pre-requisite Start ***********************
context = {
    aws_credentials_file    = "$HOME/.aws/credentials"
    aws_profile             = "default"
    aws_region              = "us-west-2"
    region_alias            = "uw2"

    project                 = "eks-init"
    environment             = "dev"
    env_alias               = "d"
    owner                   = "yangjaehyun"
    team_name               = "Devops CNE Team"
    team                    = "CNE"
    generator_date          = "20240108"
    domain                  = "terraform.prac.dev"
    pri_domain              = "terraform.prac"
}
키페어를 등록하려면 y를 눌러주세요 
y
10-pre-requisite keypair 등록을 실행합니다.

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 3.31.0"...
- Finding latest version of hashicorp/tls...
- Installing hashicorp/aws v5.33.0...
- Installed hashicorp/aws v5.33.0 (self-signed, key ID 34365D9472D7468F)
- Installing hashicorp/tls v4.0.5...
- Installed hashicorp/tls v4.0.5 (self-signed, key ID 34365D9472D7468F)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
tls_private_key.this: Creating...
tls_private_key.this: Creation complete after 0s [id=34e3e360f834bed4466b6e32b5298d054e6b648f]
aws_key_pair.this: Creating...
aws_key_pair.this: Creation complete after 0s [id=eks-init-uw2d-yangjaehyun-keypair]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
********************** 10-pre-requisite End ***********************
********************** 20 - VPC Make Starting ***********************
context = {
    aws_credentials_file    = "$HOME/.aws/credentials"
    aws_profile             = "default"
    aws_region              = "us-west-2"
    region_alias            = "uw2"

    project                 = "eks-init"
    environment             = "dev"
    env_alias               = "d"
    owner                   = "yangjaehyun"
    team_name               = "Devops CNE Team"
    team                    = "CNE"
    generator_date          = "20240108"
    domain                  = "terraform.prac.dev"
    pri_domain              = "terraform.prac"
}

# vpc prefix ip
vpc_cidr = "40.40"테라폼 벨류 설정 파일이 맞으면 y를 눌러주세요
y
VPC 및 bastion 서버 생성을 실행합니다.
Initializing modules...
- aws_ec2_bastion in ../../../../modules/aws/ec2/ec2_bastion
- aws_private_subnet_eks_a in ../../../../modules/aws/subnet
- aws_private_subnet_eks_c in ../../../../modules/aws/subnet
- aws_public_subnet_a in ../../../../modules/aws/subnet
- aws_public_subnet_c in ../../../../modules/aws/subnet
- aws_sg_default in ../../../../modules/aws/security
- aws_vpc in ../../../../modules/aws/vpc
- aws_vpc_network in ../../../../modules/aws/network/igw_nat_subnet

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.33.0...
- Installed hashicorp/aws v5.33.0 (self-signed, key ID 34365D9472D7468F)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.


... 생략

config_map_aws_auth = <<EOT


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::767404772322:role/eks-basic-uw2d-yangjaehyun-eks-node
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes

EOT
kubeconfig = <<EOT


apiVersion: v1
clusters:
- cluster:
    server: https://91B0E6B4A6C4915B3DBD73B24B31DC35.gr7.us-west-2.eks.amazonaws.com
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJTk9EeHUrSFZ3NnN3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5.... 생략 xWdXRvK0NxVXFyTU5KaTVZMURHejE3aGZWUlMKbnBaUmdZVEtITTRjR3VrMU1VcmhqNDhHUXNVTlVDdjluNk9BZ0RJS25nM1cvemE4RHZBR0dCZVJRSUVlbE11UgpDRWgrKzAzUld0WE8vMlBrUW1ZdUp0cTkvUis5T2ZDWDBCd0VPeUVTbnpoVUJWU24weEE0WEZSU0xGU0hGa2ZtCmNTejQ2eTk0K2I4T1BYZmN0L3ltT0JrS051bUJET1JlU0VWTmNnRFVPMXJkQ2owdzlZcmF3Wnd0R0d4aTdpakwKK1lXRk5NSW9kWnhrCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
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
        - us-west-2
        - eks
        - get-token
        - --cluster-name
        - eks-basic-uw2d-yangjaehyun-k8s
      env:
      - name: AWS_PROFILE
        value: default

EOT
```