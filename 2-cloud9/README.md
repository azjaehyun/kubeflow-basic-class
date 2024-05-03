# cloud9 IDE 환경 구성



### 1. Cloud9 구성 설정 및 생성!
- 리전 오레곤 선택 ( us-west-2 선택!! 이유는 가격이 젤쌈 ^^)
- service에서 cloud9 검색 -> 오른쪽 주황색 환경 생성 버튼 클릭
- 세부 정보 이름 , 설명 본인이 작성 
- Instance Type - 추가 인스턴스 유형 - t2.micro
- 플랫폼 - Amazone Linux 2023
- 시간제한 setting - Never(안함)
- 네트워크 설정 - Aws systems Manager(SSM)
- VPC - default 선택
- subnet - us-west-2a로 선택  

---

### 2. cloud9 생성후 접속 후 환경 셋팅하자 !!!
- 오른쪽 상단위 톱니바퀴 클릭 -> AWS settings 클릭 -> Credentials [Aws managed temporary credentails] 비활성화 ( 녹색 -> 빨간색으로 버튼 클릭~)  
- vimrc 설정
```
vi ~/.vimrc
set tabstop=2
set expandtab
set shiftwidth=2
추가 후 저장
```

---
### 3. 왼쪽 깃 sourcec control 클릭 후
-  Clone Repository 클릭 후 https://github.com/azjaehyun/eks-basic-class.git 입력후 엔터!
-  /home/ec2-user/environment 기본 경로로 설정후 녹색버튼 클릭
- 화면 아래 bash 탭에 접속후 ls 치면 eks-basic-class 폴더로 깃이 다운로드 되어 있는것을 확인
- 왼쪽 탭에 폴더 모양을 누르면 Hierarchy 구조로  eks-basic-class 폴더를 볼 수 있음.  


---
### 4. aws configure 설정
- aws configure 명령어 친 후에 본인 억세스키와 시크릿키 리전 입력
- [EX] aws configure
```
AWS Access Key ID [None]: abcdedfeg.... [<<본인 억세스키 입력]
AWS Secret Access Key [None]: abdkljalkfjlke [<<본인 스키릿키 입력]
Default region name [None]: us-west-2
Default output format [None]: json
```
- 확인 명령어 : aws configure list

--- 
### 5. packer 로 bastion AMI 를 생성하자. [이걸 왜하냐? bastio서버 셋팅하기 귀찮다!! 그래서 미리 설정한 이미지를 올리기 위해서 !!]
- packer install 및 버전 확인
```
cd ~
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install packer
packer --version 
```
  

- 이제 bastion ami를 만들어보자 !! 아래 경로로 이동
```
cd /home/ec2-user/environment
cd ./eks-basic-class/packer/bastion-server
```
- packer 변수명 수정해야 해서 아래 절차 진행
- vi bastion-aws-build.pkr.hcl 입력후 11번 라인 ami_name 이름인 eks-bastion-packer-ubuntu 이름 수정
- 본인 이름앞에 프리픽스로 넣어서 수정하기 EX) yangjaehyun-eks-bastion-packer-ubuntu
- 수정 완료후 아래 명령어 실행
  

```
packer init bastion-aws-build.pkr.hcl
packer build bastion-aws-build.pkr.hcl
```
- 실행 하면 아래와 같이 packer를 이용한 빌드 진행과정 출력 확인  

```
packer build bastion-aws-build.pkr.hcl 

learn-packer.amazon-ebs.amzn2: output will be in this color.
==> learn-packer.amazon-ebs.amzn2: Prevalidating any provided VPC information
==> learn-packer.amazon-ebs.amzn2: Prevalidating AMI Name: yangjaehyun-eks-bastion-packer-ubuntu
    learn-packer.amazon-ebs.amzn2: Found Image ID: ami-08e2c1a8d17c2fe17
    learn-packer.amazon-ebs.amzn2: Found Subnet ID: subnet-0029d9863c957a70e
==> learn-packer.amazon-ebs.amzn2: Creating temporary keypair: packer_65b1be50-eae2-4347-e797-f87d32558127
==> learn-packer.amazon-ebs.amzn2: Creating temporary security group for this instance: packer_65b1be51-c64c-e889-be

... 중간 생략

==> learn-packer.amazon-ebs.amzn2: Terminating the source AWS instance...
==> learn-packer.amazon-ebs.amzn2: Cleaning up any extra volumes...
==> learn-packer.amazon-ebs.amzn2: No volumes to clean up, skipping
==> learn-packer.amazon-ebs.amzn2: Deleting temporary security group...
==> learn-packer.amazon-ebs.amzn2: Deleting temporary keypair...
Build 'learn-packer.amazon-ebs.amzn2' finished after 6 minutes 34 seconds.

==> Wait completed after 6 minutes 34 seconds

==> Builds finished. The artifacts of successful builds are:
--> learn-packer.amazon-ebs.amzn2: AMIs were created:
us-west-2: ami-09370ebbf30fffa1c   << AMI 가 정상적으로 생성되면 ami id가 출력됨..
```
  

## packer ami 이미지 확인
- aws ec2 describe-images --image-ids { 위에 생성된 ami id 입력 }
- ex) aws ec2 describe-images --image-ids ami-09370ebbf30fffa1c  

- 결과 확인  

```
{
    "Images": [
        {
            "Architecture": "x86_64",
            "CreationDate": "2024-01-25T01:53:26.000Z",
            "ImageId": "ami-09370ebbf30fffa1c",
            "ImageLocation": "767404772322/yangjaehyun-eks-bastion-packer-ubuntu",
            "ImageType": "machine",
            "Public": false,
            "OwnerId": "767404772322",
            "PlatformDetails": "Linux/UNIX",
            "UsageOperation": "RunInstances", 

... 이하 생략
```

  


