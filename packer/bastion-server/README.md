## packer bastion ami 만들기 

### [packer document](https://developer.hashicorp.com/packer/tutorials/aws-get-started)

To build the bastion AMI:

### cloud9 환경에서(OS type : Amazon Linux) Packer 설치하기
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install packer
``` 
### Packer 설치 확인
```
which packer
packer version
packer -autocomplete-install  #자동완성 설정
```

### pakcer 변수 수정 ( bastion-aws-build.pkr.hcl 파일 수정 )
```
- vi bastion-aws-build.pkr.hcl 입력후 11번 라인 ami_name 이름인 eks-bastion-packer-ubuntu 이름 수정
- 본인 이름앞에 프리픽스로 넣어서 수정하기 EX) yangjaehyun-eks-bastion-packer-ubuntu
- 또한 #으로 주석친 부분 자신의 정보로 변경
```

### default subnet 4개 중에 Avaible zone - A 에 있는 이름을 default-public 으로 이름 변경
- 해당 내용은 bastion-aws-build.pkr.hcl 파일 18라인 때문에 특정 subnet을 지정해야하기 때문.

### packer AMI 생성 실행
```
packer init bastion-aws-build.pkr.hcl
packer build bastion-aws-build.pkr.hcl
```

### 완료후 EC2 -> 왼쪽메뉴에 이미지 -> AMI 들어가서 생성되었는지 확인!!

### 생성완료된 AMI 오른쪽 마우스 클릭 AMI로 인스턴스 시작 클릭후 bastion server 생성하기!