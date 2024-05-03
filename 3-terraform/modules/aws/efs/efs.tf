

# EFS 탑재 대상에 연결할 보안 그룹을 생성
resource "aws_security_group" "efs_sg" {
  name        = var.efs_sg_name
  description = "Allow EFS-File-System inbound traffic"
  vpc_id      = var.vpc_id
  # 인바운드: ingress
  ingress {
    description = "SSH from VPC"

    # 포트 범위: from_port ~ to_port
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["40.40.1.0/24"]
  }
  ingress {
    description = "SSH from VPC"

    # 포트 범위: from_port ~ to_port
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["40.40.2.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = var.tag_name
}


# EFS 파일 시스템 생성
resource "aws_efs_file_system" "efs" {
  # 사용법 https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system
  # 원존 클래스를 이용할 경우
  # availability_zone_name = "ap-northeast-2a"

  # 유휴 시 데이터 암호화
  encrypted = true
  # KMS에서 관리형 키를 이용하려면 kms_key_id 속성을 붙여줍니다.

  # 성능 모드: generalPurpose(범용 모드), maxIO(최대 IO 모드)
  performance_mode = "generalPurpose"
  
  # 버스팅 처리량 모드
  throughput_mode = "bursting"

  # 프로비저닝 처리량 모드
  # throughput_mode = "provisioned"
  # provisioned_throughput_in_mibps = 100

  # 수명 주기 관리
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = var.tag_name
 
}


# 표준 클래스로 EFS를 생성하더라도 탑재 대상은 모든 가용영역에 수동으로 지정해주어야 합니다. 
resource "aws_efs_mount_target" "mount-1" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.private_subnets[0]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "mount-2" {
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.private_subnets[1]
  security_groups = [aws_security_group.efs_sg.id]
}