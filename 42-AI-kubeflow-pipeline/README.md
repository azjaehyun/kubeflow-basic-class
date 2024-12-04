# Kubeflow 환경에서의 모델 배포 및 파이프라인 설정

Kubeflow 환경에서 제공하신 모델을 배포하고 사용할 수 있도록 Kubeflow 파이프라인을 설정하는 방법을 설명하겠습니다. Kubeflow는 머신러닝 워크플로우를 쉽게 구축하고 관리할 수 있는 플랫폼이며, Kubeflow 파이프라인을 사용하여 모델을 컨테이너화하고 배포할 수 있습니다.

## 단계별 Kubeflow 파이프라인 구축 과정

### 1. 도커 이미지 생성
먼저 FastAPI 애플리케이션을 Docker 이미지로 패키징해야 합니다. 이 Docker 이미지는 모델을 서빙할 API를 포함하며, Kubernetes 클러스터에서 컨테이너로 실행될 수 있습니다.

#### 1.1 `FAST API 기반 Dockerfile` 작성 
```dockerfile
# Base image with Python 3.9
FROM python:3.9-slim

# Set environment variables to prevent Python from writing pyc files and buffering stdout/err
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy requirements file to container
COPY requirements.txt /app/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py /app/
COPY modeling /app/modeling/
COPY data_manager /app/data_manager/
COPY utils /app/utils/

# Copy the model and meta.bin files (모델은 파일이 너무 커서 생략)
COPY ckpt/result_model/pytorch_model.bin /app/ckpt/result_model/
COPY ckpt/result_model/meta.bin /app/ckpt/result_model/  

# Expose the port the app runs on
EXPOSE 8000

# Run the FastAPI application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]

```

#### 1.2 `vLLM 기반 Dockerfile` 작성 
```dockerfile
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

#### 1.2 Docker 이미지 빌드 및 푸시
```bash
docker build -t your-dockerhub-username/absa-model:latest .
docker push your-dockerhub-username/absa-model:latest
```
Docker 이미지를 빌드한 후 Docker Hub 또는 다른 컨테이너 레지스트리에 푸시합니다.

### 2. Kubeflow 파이프라인 구성 요소 작성
Kubeflow 파이프라인에서 사용할 여러 컴포넌트를 정의합니다. 여기에서는 모델을 배포하는 컴포넌트를 작성합니다.

#### 2.1 Kubernetes YAML 파일 작성 (배포용)
모델을 Kubernetes 환경에 배포하기 위해서는 `Deployment`와 `Service`를 정의하는 YAML 파일이 필요합니다.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: absa-model-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: absa-model
  template:
    metadata:
      labels:
        app: absa-model
    spec:
      containers:
      - name: absa-model
        image: your-dockerhub-username/absa-model:latest
        ports:
        - containerPort: 8000
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1"
---
apiVersion: v1
kind: Service
metadata:
  name: absa-model-service
spec:
  selector:
    app: absa-model
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```
이 YAML 파일은 Kubeflow에서 모델을 배포하고 외부 접근을 허용할 수 있도록 합니다.

#### 2.2 Kubeflow Pipeline 파이프라인 정의 (Python 코드로 작성)
Kubeflow 파이프라인을 Python으로 정의하여 모델을 배포하고 테스트하는 워크플로우를 구성합니다.

```python
from kfp import dsl, components

def deploy_model_op():
    return dsl.ContainerOp(
        name='Deploy ABSA Model',
        image='your-dockerhub-username/absa-model:latest',
        command=['sh', '-c'],
        arguments=['kubectl apply -f /app/deployment.yaml']
    )

@dsl.pipeline(
    name='ABSA Model Deployment Pipeline',
    description='A pipeline to deploy ABSA model using Kubeflow'
)
def absa_pipeline():
    deploy_task = deploy_model_op()

if __name__ == '__main__':
    import kfp.compiler as compiler
    compiler.Compiler().compile(absa_pipeline, 'absa_pipeline.yaml')
```
이 코드는 Docker 이미지를 사용해 모델을 배포하는 파이프라인을 정의합니다.



### 3. 파이프라인 실행
Kubeflow UI에 접속한 후, 작성한 파이프라인 정의 파일(`absa_pipeline.yaml`)을 업로드하고 실행할 수 있습니다.
- Kubeflow UI에서 **Experiments**로 이동하여 새로운 실험을 만들고, 작성한 파이프라인을 실행합니다.
- 파이프라인의 단계 중 `Deploy ABSA Model`이 실행되면서 Kubernetes 클러스터에 모델이 배포됩니다.


## 4. absa_pipeline.yaml 예시

Kubeflow 파이프라인을 정의하는 `absa_pipeline.yaml` 파일은 다음과 같은 형식으로 작성됩니다:

```yaml
pipelineInfo:
  name: ABSA Model Deployment Pipeline
  description: A pipeline to deploy ABSA model using Kubeflow
sdkVersion: kfp-1.4.0
schemaVersion: 2.0.0
tasks:
  deploy-absa-model:
    container:
      image: your-dockerhub-username/absa-model:latest
      command:
      - sh
      - -c
      - kubectl apply -f /app/deployment.yaml
      args: []
    name: Deploy ABSA Model
    dependencies: []
deploymentSpec:
  executorGroups:
  - executors:
    - name: deploy-absa-model
      container:
        image: your-dockerhub-username/absa-model:latest
        command:
        - sh
        - -c
        - kubectl apply -f /app/deployment.yaml
      inputs: []
      outputs: []
    name: executor-group-0
  components: []
```

이 파일은 Kubeflow에서 파이프라인을 정의하고 실행하는데 사용되며, 모델 배포 작업을 자동화하는 워크플로우의 일부로 활용됩니다.

## 요약
- **Kubeflow Pipelines Recurring Run**: 특정 시간에 파이프라인을 자동으로 실행하여 배포 포함 전체 워크플로우를 관리.
- **Kubernetes CronJob**: `kubectl` 명령을 정해진 시간에 실행하여 배포 작업을 수행.
- **Argo Workflow 스케줄링**: Argo CLI를 사용하여 워크플로우 스케줄링 가능.
- **Kubeflow CLI 사용**: Kubeflow CLI (`kfp`)를 사용하여 파이프라인을 명령줄에서 등록 및 실행 가능.
- **absa_pipeline.yaml**: Kubeflow 파이프라인 정의 파일로, 배포 작업을 자동화하는 데 사용.

이러한 방법들을 통해 특정 시간에 모델을 배포하거나, 주기적으로 실행하도록 스케줄링하여 배포 프로세스를 자동화할 수 있습니다.


### 5. 모델 서빙 테스트
모델이 정상적으로 배포되었다면, `absa-model-service`를 통해 클러스터 외부에서 접근할 수 있는 LoadBalancer IP 주소를 확인할 수 있습니다.
- 외부 IP 주소로 `/predict` 엔드포인트에 요청을 보내 모델의 예측 결과를 확인할 수 있습니다.
- 예를 들어:
  ```bash
  curl -X POST "http://<external-ip>/predict" -H "Content-Type: application/json" -d '{"text": "이 제품 정말 좋아요!"}'
  ```
  위 명령어를 사용해 클라이언트에서 모델 API를 호출하고 응답을 받을 수 있습니다.

