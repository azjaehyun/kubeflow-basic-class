### Kubeflow Pipeline 예시 코드
```python
from kfp import dsl
from kfp.dsl import ContainerOp

@dsl.pipeline(
    name="GPU Node Pipeline",
    description="Pipeline that schedules a pod on a specific GPU node"
)
def gpu_node_pipeline():
    # ContainerOp 정의
    gpu_task = dsl.ContainerOp(
        name="gpu_task",
        image="your-docker-image",  # 사용할 도커 이미지를 지정합니다.
        command=["python", "your_script.py"],
    )

    # 특정 노드에서만 실행되도록 Node Selector 설정
    gpu_task.add_node_selector_constraint('gpu_label', 'true')

    # GPU 노드에서 실행되도록 톨러레이션 추가 (GPU 노드에 taint가 설정되어 있는 경우)
    gpu_task.add_toleration({
        'key': 'gpu_label',
        'operator': 'Equal',
        'value': 'true',
        'effect': 'NoSchedule'
    })

if __name__ == "__main__":
    import kfp.compiler as compiler
    compiler.Compiler().compile(gpu_node_pipeline, "gpu_node_pipeline.yaml")
```

위 예시에서 사용된 주요 요소는 다음과 같습니다:

1. **`add_node_selector_constraint('gpu_label', 'true')`**: 노드 셀렉터를 사용하여 특정 노드 라벨(`gpu_label=true`)이 있는 노드에 파드를 스케줄링하도록 지정합니다.

2. **`add_toleration()`**: 만약 해당 GPU 노드가 `taint`로 보호되어 있는 경우, 톨러레이션을 추가하여 해당 노드에서 파드가 실행되도록 합니다. 여기서는 GPU 노드에 설정된 taint가 있을 경우 이를 허용하기 위한 톨러레이션을 정의합니다.

### 생성된 Workflow 예시 (gpu_node_pipeline.yaml)
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: gpu-node-pipeline-
  labels:
    pipelines.kubeflow.org/pipeline-sdk-type: kfp
spec:
  entrypoint: main
  templates:
  - name: main
    dag:
      tasks:
      - name: gpu-task
        template: gpu-task
  - name: gpu-task
    container:
      image: your-docker-image
      command:
        - python
        - your_script.py
      resources:
        limits:
          nvidia.com/gpu: "1"
      nodeSelector:
        gpu_label: "true"
      tolerations:
      - key: "gpu_label"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

위 `gpu_node_pipeline.yaml` 파일은 다음과 같이 구성되어 있습니다:

- **`apiVersion`** 및 **`kind`**: Kubeflow 파이프라인은 Argo Workflows를 기반으로 하므로, Argo의 `Workflow` API 버전과 종류가 설정됩니다.
- **`metadata`**: 파이프라인의 메타데이터를 정의하며, 이름이나 레이블 같은 속성이 포함됩니다.
- **`spec`**: 파이프라인의 정의를 담고 있으며, `entrypoint`, `templates` 등으로 구성됩니다.
  - **`templates`**: 파이프라인을 구성하는 작업(`gpu-task`)이 정의됩니다.
  - **`nodeSelector`** 및 **`tolerations`**: 특정 노드에 GPU 파드를 스케줄링하고 taint를 처리하도록 설정되어 있습니다.

## 8. 외부 노출을 위한 Kubernetes 서비스 연동
생성된 워크플로우를 외부에 노출시키려면 Kubernetes에서 **Service** 리소스를 사용하여 파드를 외부로 노출할 수 있습니다. 아래는 `gpu_node_pipeline.yaml` 파일을 외부에 노출시키기 위한 Kubernetes 서비스 정의 예시입니다.

### Kubernetes Service 예시 코드
```yaml
apiVersion: v1
kind: Service
metadata:
  name: gpu-node-pipeline-service
spec:
  selector:
    app: gpu-node-pipeline  # 파드의 라벨과 일치해야 합니다.
  ports:
    - protocol: TCP
      port: 80  # 외부에서 접근할 포트
      targetPort: 8080  # 파드 내부에서 실행되는 애플리케이션 포트
  type: LoadBalancer  # 외부에 노출하기 위한 서비스 타입
```

위 예시는 다음과 같은 요소로 구성됩니다:

1. **`selector`**: 생성된 파드를 식별하기 위한 라벨 셀렉터입니다. 파드의 메타데이터에 지정된 라벨과 일치해야 합니다.
2. **`ports`**: 외부 포트와 내부 파드 포트를 매핑합니다. 예를 들어, 외부에서 80번 포트로 접근하면 파드의 8080번 포트로 요청이 전달됩니다.
3. **`type: LoadBalancer`**: 이 서비스 타입을 사용하면 클라우드 환경에서 외부 IP를 할당받아 외부에서 접근할 수 있도록 설정됩니다. 클라우드 환경이 아닌 경우 `NodePort` 타입을 사용할 수도 있습니다.

이렇게 설정된 서비스는 GPU를 사용하는 파드를 외부 네트워크에서 접근 가능하게 만들어, GPU를 사용하는 애플리케이션을 외부 사용자나 시스템에서 사용할 수 있도록 합니다.

## 요약
GPU 분할, 효율적인 리소스 제한, 고급 작업 스케줄링, 자동 스케일링, 샤딩, GPU 활용도 모니터링과 같은 기술을 결합하면 쿠버네티스에서 GPU 자원을 효과적으로 관리할 수 있습니다.  
이러한 기술은 GPU 유휴 시간을 줄이고 자원 활용도를 극대화하며, 여러 프로세스가 GPU 자원을 효율적으로 공유할 수 있도록 돕습니다.
적절한 전략을 사용하면 GPU 기반 쿠버네티스 클러스터에서의 성능과 비용 효율성을 크게 향상시킬 수 있으며, 특히 vLLM과 같은 대형 언어 모델을 실행할 때 큰 도움이 됩니다.

