
# vLLM Conversion Guide

# vLLM Docker 설정 가이드

이 문서에서는 vLLM 서버를 Docker로 설정하고, 모델을 서빙하기 위해 필요한 과정을 설명합니다. vLLM을 사용해 모델을 서비스하는 Docker 컨테이너를 구축하는 방법을 예시와 함께 안내합니다.

## Dockerfile 작성 예시
아래는 Dockerfile을 사용하여 vLLM 서버와 모델을 설정하고 컨테이너를 빌드하는 방법입니다.
[학습된 파일 경로 pytorch_model.bin , meta.bin ](../40-AI-model/ckpt/result_model/)

```Dockerfile
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
```

### 설명
1. **베이스 이미지 설정**:
   - `python:3.8-slim` 이미지를 사용하여 Python 환경을 설정합니다.

2. **작업 디렉토리 생성**:
   - `/app` 디렉토리를 작업 디렉토리로 설정합니다.

3. **필요한 시스템 종속성 설치**:
   - 필요한 시스템 종속성(`git` 등)을 설치합니다.

4. **Python 패키지 설치**:
   - `requirements.txt` 파일에 필요한 패키지 목록을 작성하고, 이를 Docker 이미지 빌드 시 설치합니다.
   - `vllm` 라이브러리를 비롯한 다른 종속성들이 여기 포함될 수 있습니다.

5. **모델 파일 복사**:
   - 로컬 시스템의 모델 파일이 저장된 디렉토리를 Docker 이미지로 복사합니다 (`/app/ckpt/result_model`).
   - 또한, `meta.bin` 파일을 모델 디렉토리에 포함시킵니다.

6. **vLLM 서버 실행**:
   - `CMD` 명령어를 사용해 컨테이너가 시작될 때 vLLM 서버를 실행하도록 설정합니다.
   - 여기서 `/app/ckpt/result_model`은 모델 파일이 있는 경로이며, vLLM이 해당 경로에서 모델을 로드하게 됩니다.

## 요구사항 파일 (`requirements.txt`) 예시
`requirements.txt`에는 Python 패키지 의존성들을 정의합니다. 예를 들어:

```
vllm
fastapi
uvicorn
requests
```

이렇게 작성하면 Docker 이미지 빌드 시 필요한 모든 Python 패키지가 설치됩니다.

## Docker 빌드 및 실행
이제 Dockerfile을 이용해 이미지를 빌드하고 실행하면 됩니다:

1. **이미지 빌드**:
   ```bash
   docker build -t absa-vllm-server .
   ```

2. **컨테이너 실행**:
   ```bash
   docker run -p 8000:8000 absa-vllm-server
   ```

이 명령으로 컨테이너가 시작되면, vLLM 서버가 포트 `8000`에서 실행됩니다. FastAPI와 같은 다른 서비스를 실행할 때 이 vLLM 서버에 요청을 보내어 모델 예측을 할 수 있습니다.

## 요약
- Dockerfile을 사용하여 컨테이너 내에서 vLLM 서버를 자동으로 실행하도록 설정합니다.
- `CMD ["vllm", "serve", "--model", "/app", "--port", "8000"]`를 통해 Docker 컨테이너가 시작될 때 모델 서버가 자동으로 실행됩니다.
- 빌드한 이미지를 기반으로 컨테이너를 실행하면 vLLM 서버가 실행되고, 다른 서비스(예: FastAPI)에서 이를 호출할 수 있습니다.

이렇게 하면 Docker 컨테이너 내에서 모델 서빙이 자동으로 이루어지므로 편리하게 사용할 수 있습니다.


## REST API 요청 샘플

### 요청 예시 (HTTP POST 요청)
- **URL**: `http://localhost:8000/predict`
- **Headers**: `Content-Type: application/json`
- **Body**:
  ```json
  {
    "text": "이 제품은 정말 좋았습니다! 배송도 빠르고 품질도 훌륭하네요."
  }
  ```

### 응답 예시 (HTTP 응답)
- **응답 예시**:
  ```json
  {
    "sentiment": "positive",
    "aspect": "배송",
    "aspect2": "품질"
  }
  ```