# Kubeflow 환경에서의 모델 배포 및 파이프라인 설정

Kubeflow 환경에서 제공하신 모델을 배포하고 사용할 수 있도록 Kubeflow 파이프라인을 설정하는 방법을 설명하겠습니다. Kubeflow는 머신러닝 워크플로우를 쉽게 구축하고 관리할 수 있는 플랫폼이며, Kubeflow 파이프라인을 사용하여 모델을 컨테이너화하고 배포할 수 있습니다.

## 단계별 Kubeflow 파이프라인 구축 과정

### 1. 도커 이미지 생성
먼저 FastAPI 애플리케이션을 Docker 이미지로 패키징해야 합니다. 이 Docker 이미지는 모델을 서빙할 API를 포함하며, Kubernetes 클러스터에서 컨테이너로 실행될 수 있습니다.

#### 1.1 `Dockerfile` 작성
```dockerfile
FROM python:3.8-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY ckpt/result_model/pytorch_model.bin ./ckpt/result_model/
COPY ckpt/result_model/meta.bin ./ckpt/result_model/
COPY modeling/ ./modeling/
COPY data_manager/ ./data_manager/
COPY utils/ ./utils/

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
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

### 4. 모델 서빙 테스트
모델이 정상적으로 배포되었다면, `absa-model-service`를 통해 클러스터 외부에서 접근할 수 있는 LoadBalancer IP 주소를 확인할 수 있습니다.
- 외부 IP 주소로 `/predict` 엔드포인트에 요청을 보내 모델의 예측 결과를 확인할 수 있습니다.
- 예를 들어:
  ```bash
  curl -X POST "http://<external-ip>/predict" -H "Content-Type: application/json" -d '{"text": "이 제품 정말 좋아요!"}'
  ```
  위 명령어를 사용해 클라이언트에서 모델 API를 호출하고 응답을 받을 수 있습니다.

## 추가 고려 사항
- **모니터링**: Kubeflow의 Katib이나 Prometheus와 Grafana 등을 이용하여 모델의 성능 및 시스템 리소스를 모니터링할 수 있습니다.
- **자동 스케일링**: Kubernetes Horizontal Pod Autoscaler(HPA)를 사용하여 트래픽에 따라 모델 서빙 컨테이너의 수를 자동으로 조절할 수 있습니다.
- **파이프라인 확장**: 이 파이프라인은 배포만을 포함하고 있지만, 학습, 평가, 배포, 테스트까지 이어지는 End-to-End 워크플로우로 확장할 수 있습니다.

위 과정을 통해 Kubeflow를 사용하여 모델을 쉽게 배포하고 관리할 수 있습니다. Kubeflow는 특히 여러 단계의 머신러닝 워크플로우를 자동화하고 재사용 가능한 방식으로 관리할 때 매우 유용합니다.
