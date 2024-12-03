
# Kubeflow Pipelines DSL 문법 정리

## 1. Pipeline 정의
### 설명
파이프라인은 작업(`ContainerOp`)을 연결하여 전체 워크플로를 정의합니다.

### 문법
```python
@dsl.pipeline(
    name='Pipeline Name',
    description='Pipeline Description'
)
def my_pipeline(param1: str, param2: int):
    # 작업 정의 및 연결
    pass
```

### 샘플 코드
```python
@dsl.pipeline(
    name='Sample Pipeline',
    description='A sample pipeline that demonstrates basic structure'
)
def sample_pipeline(input_path: str, output_path: str):
    step1 = dsl.ContainerOp(
        name='Step 1',
        image='python:3.8-slim',
        command=['echo', 'Hello, world!']
    )
```

---

## 2. ContainerOp
### 설명
`ContainerOp`는 컨테이너 기반 작업을 정의합니다.

### 문법
```python
dsl.ContainerOp(
    name='Task Name',
    image='Docker Image',
    command=['Command to run in container'],
    arguments=['--arg1', 'value1']
)
```

### 샘플 코드
```python
step1 = dsl.ContainerOp(
    name='Print Message',
    image='alpine',
    command=['echo'],
    arguments=['Hello, Kubeflow!']
)
```

---

## 3. Pipeline Parameters
### 설명
파이프라인에 입력값을 전달하기 위한 매개변수입니다.

### 문법
```python
@dsl.pipeline(
    name='Pipeline with Parameters',
    description='Pipeline that uses parameters'
)
def pipeline_with_params(param1: str, param2: int):
    pass
```

### 샘플 코드
```python
@dsl.pipeline(
    name='Parameterized Pipeline',
    description='A pipeline that demonstrates parameter usage'
)
def param_pipeline(message: str = 'Default Message'):
    dsl.ContainerOp(
        name='Print Message',
        image='alpine',
        command=['echo'],
        arguments=[message]
    )
```

---

## 4. Artifacts and Outputs
### 설명
작업 간 데이터를 전달하기 위한 파일 출력과 입력.

### 문법
```python
step1 = dsl.ContainerOp(
    name='Step 1',
    image='alpine',
    command=['sh', '-c'],
    arguments=['echo "output" > /data/output'],
    file_outputs={'output': '/data/output'}
)

step2 = dsl.ContainerOp(
    name='Step 2',
    image='alpine',
    command=['cat'],
    arguments=[step1.outputs['output']]
)
```

---

## 5. Volume (데이터 공유)
### 설명
작업 간 데이터를 공유하기 위해 볼륨을 사용.

### 문법
```python
from kubernetes.client.models import V1Volume, V1VolumeMount

volume = V1Volume(
    name='shared-volume',
    empty_dir={}
)

volume_mount = V1VolumeMount(
    name='shared-volume',
    mount_path='/data'
)

step1.add_volume(volume).add_volume_mount(volume_mount)
```

---

## 6. Conditions
### 설명
조건부로 작업을 실행.

### 문법
```python
with dsl.Condition(task.outputs['result'] == 'desired_value'):
    task_to_run_if_condition_met
```

### 샘플 코드
```python
with dsl.Condition(step1.outputs['output'] == 'yes'):
    dsl.ContainerOp(
        name='Conditional Step',
        image='alpine',
        command=['echo', 'Condition met!']
    )
```

---

## 7. Loops
### 설명
동일한 작업을 여러 값으로 반복 실행.

### 문법
```python
with dsl.ParallelFor(['a', 'b', 'c']) as item:
    dsl.ContainerOp(
        name='Loop Step',
        image='alpine',
        command=['echo', item]
    )
```

---

## 8. Execution Options
### 설명
작업 실행 옵션 설정.

### 문법
```python
step = dsl.ContainerOp(
    name='Step',
    image='alpine',
    command=['echo', 'Hello']
)

step.set_cpu_limit('1').set_memory_limit('512Mi').set_gpu_limit(1)
```

---

## 9. ResourceOps
### 설명
Kubernetes 리소스를 직접 생성하거나 관리.

### 문법
```python
k8s_op = dsl.ResourceOp(
    name='Create PVC',
    k8s_resource={
        'apiVersion': 'v1',
        'kind': 'PersistentVolumeClaim',
        'metadata': {'name': 'my-pvc'},
        'spec': {
            'accessModes': ['ReadWriteOnce'],
            'resources': {'requests': {'storage': '1Gi'}}
        }
    }
)
```

---

## 10. Compiling the Pipeline
### 설명
파이프라인을 YAML로 컴파일.

### 문법
```python
kfp.compiler.Compiler().compile(my_pipeline, 'pipeline.yaml')
```

### 샘플 코드
```python
kfp.compiler.Compiler().compile(sample_pipeline, 'sample_pipeline.yaml')
```

---

## 11. Submitting the Pipeline
### 설명
Kubeflow UI 또는 SDK를 통해 파이프라인 제출.

### 샘플 코드
```python
import kfp
client = kfp.Client()
client.create_run_from_pipeline_func(
    my_pipeline,
    arguments={'param1': 'value1', 'param2': 10}
)
```

---

## 종합 예제
```python
@dsl.pipeline(
    name='Comprehensive Example',
    description='Demonstrating Kubeflow Pipelines DSL features'
)
def comprehensive_pipeline(message: str = 'Hello'):
    step1 = dsl.ContainerOp(
        name='Step 1',
        image='alpine',
        command=['echo', message]
    )

    with dsl.Condition(step1.outputs['output'] == 'Hello'):
        dsl.ContainerOp(
            name='Conditional Step',
            image='alpine',
            command=['echo', 'Condition met!']
        )

    with dsl.ParallelFor(['a', 'b', 'c']) as item:
        dsl.ContainerOp(
            name='Loop Step',
            image='alpine',
            command=['echo', item]
        )
```

---

## 요약
1. 파이프라인은 `@dsl.pipeline`으로 정의.
2. 각 작업은 `dsl.ContainerOp`으로 정의.
3. 조건, 반복, 출력 공유 등 다양한 제어 기능을 제공.
4. YAML로 컴파일 후 Kubeflow UI나 SDK로 실행.

