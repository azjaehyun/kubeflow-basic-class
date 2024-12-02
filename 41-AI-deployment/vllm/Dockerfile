

# 베이스 이미지 설정 - Python 3.8 기반의 경량화된 이미지
FROM python:3.8-slim

# 작업 디렉토리 생성 및 설정
WORKDIR /app

# 필요한 시스템 종속성 설치
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Python 패키지 설치를 위한 파일 복사
COPY requirements.txt .

# Python 패키지 설치
RUN pip install --no-cache-dir -r requirements.txt

# 모델 파일 복사  ( 40-AI-model ) 
COPY ckpt/result_model/pytorch_model.bin /app/pytorch_model.bin
COPY ckpt/result_model/meta.bin /app/meta.bin

# vLLM 실행 명령을 컨테이너 시작 시 실행되도록 설정
CMD ["vllm", "serve", "--model", "/app", "--port", "8000"]