# Kubeflow 파이프라인 및 Kubernetes 스케줄링을 통한 모델 배포 요약

Kubeflow와 Kubernetes를 사용하여 특정 시간에 모델 배포 작업을 자동으로 실행하는 방법은 다음과 같습니다.

## 1. Kubeflow Pipeline 주기적 실행 설정

Kubeflow Pipelines의 **주기적 실행(Recurring Run)** 기능을 사용하면 특정 시간 또는 주기적으로 파이프라인을 실행할 수 있습니다. 이를 통해 모델 학습, 테스트, 배포 과정을 자동화하여 특정 시간에 수행할 수 있습니다.

- Kubeflow UI에서 파이프라인 실행 시 "Create Run"을 클릭하고 **Recurring Run**을 설정하여 특정 시간에 자동 실행을 구성할 수 있습니다.
- 예시: 매일 오전 2시에 파이프라인을 실행하도록 설정.

## 2. Kubernetes CronJob 사용

**Kubernetes CronJob**을 사용하여 정해진 시간에 `kubectl apply` 명령을 실행함으로써 모델을 배포할 수 있습니다. CronJob은 Kubernetes에서 주기적으로 작업을 수행하도록 스케줄링할 수 있는 기능입니다.

아래는 CronJob의 예시입니다:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: absa-model-deployment-job
spec:
  schedule: "0 3 * * *"  # 매일 오전 3시에 실행
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: deploy-absa-model
            image: bitnami/kubectl:latest  # kubectl 사용 이미지
            command: ["sh", "-c", "kubectl apply -f /app/deployment.yaml"]
            volumeMounts:
            - name: deployment-yaml
              mountPath: /app
          volumes:
          - name: deployment-yaml
            configMap:
              name: deployment-config  # 배포용 YAML 파일을 ConfigMap으로 사용
          restartPolicy: OnFailure
```

- **schedule**: Cron 형식으로 스케줄을 정의 (`"0 3 * * *"`는 매일 오전 3시 실행).

## 3. Argo Workflow와의 연동

Kubeflow Pipelines는 Argo Workflow를 백엔드로 사용하며, **Argo Workflow** 자체에서도 스케줄링 기능을 사용할 수 있습니다. 이를 통해 스케줄링된 워크플로우를 Kubeflow에서도 관리할 수 있습니다.

## 4. Kubeflow CLI 사용

Kubeflow CLI (`kfp`)를 사용하여 파이프라인을 명령줄에서 등록하고 실행할 수 있습니다. 이 방법은 터미널 또는 Jupyter Notebook에서 실행할 수 있습니다. 예를 들어, 아래와 같은 Python 코드를 통해 Kubeflow 파이프라인을 등록할 수 있습니다:

```python
import kfp
client = kfp.Client()

# 파이프라인 등록
client.upload_pipeline(
    pipeline_package_path='absa_pipeline.yaml',
    pipeline_name='ABSA Model Deployment Pipeline'
)
```

이 코드는 로컬 환경의 터미널 또는 Jupyter Notebook에서 실행할 수 있으며, Kubeflow 클러스터에 접근할 수 있는 환경이어야 합니다.

