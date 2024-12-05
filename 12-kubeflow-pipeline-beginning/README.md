
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

## 10. 데이터 의존성(Data Dependency)

### 설명

- **개념**: 한 작업의 출력이 다음 작업의 입력으로 사용될 때, 자동으로 작업 순서가 결정됩니다.
- **장점**: 데이터 흐름에 따라 작업 순서가 자연스럽게 결정되므로, 별도의 의존성 설정이 필요 없습니다.

### 예제 코드

```python
from kfp import dsl

# 컴포넌트 A 정의
@dsl.component
def a_op() -> str:
    print("작업 A 실행")
    return "A의 출력"

# 컴포넌트 B 정의
@dsl.component
def b_op(input_from_a: str) -> str:
    print(f"작업 B 실행, 입력: {input_from_a}")
    return "B의 출력"

# 파이프라인 정의
@dsl.pipeline(
    name='데이터 의존성 예제',
    description='데이터 의존성을 활용한 작업 순서 제어 예제'
)
def data_dependency_pipeline():
    # 작업 A 실행
    a_task = a_op()
    # 작업 A의 출력을 입력으로 받아 작업 B 실행
    b_task = b_op(input_from_a=a_task.output)

if __name__ == '__main__':
    from kfp import compiler
    compiler.Compiler().compile(data_dependency_pipeline, 'data_dependency_pipeline.yaml')
```

### 결과

- `a_op`가 먼저 실행되고, 그 출력이 `b_op`의 입력으로 사용됩니다.
- 따라서 `a_op`가 완료된 후 `b_op`가 실행됩니다.

---
---  
    




##  의존성 설정 메서드(Dependency Methods) 
### 11. `after` 메서드

### 설명

- **개념**: 특정 작업이 다른 작업이 완료된 후에 실행되도록 지정합니다.
- **사용법**: `task2.after(task1)` 형태로 사용하며, `task1`이 완료된 후 `task2`가 실행됩니다.
- **주의사항**: 데이터 의존성이 없는 경우에 주로 사용됩니다.

### 예제 코드

```python
from kfp import dsl

# 컴포넌트 A 정의
@dsl.component
def a_op():
    print("작업 A 실행")

# 컴포넌트 B 정의
@dsl.component
def b_op():
    print("작업 B 실행")

# 컴포넌트 C 정의
@dsl.component
def c_op():
    print("작업 C 실행")

# 파이프라인 정의
@dsl.pipeline(
    name='after 메서드 예제',
    description='after 메서드를 활용한 작업 순서 제어 예제'
)
def after_method_pipeline():
    # 작업 A 실행
    a_task = a_op()
    # 작업 B 실행
    b_task = b_op()
    # 작업 C는 작업 A와 B가 완료된 후 실행
    c_task = c_op()
    c_task.after(a_task, b_task)

if __name__ == '__main__':
    from kfp import compiler
    compiler.Compiler().compile(after_method_pipeline, 'after_method_pipeline.yaml')
```

### 결과

- `a_op`와 `b_op`는 동시에 실행됩니다.
- `c_op`는 `a_op`와 `b_op`가 모두 완료된 후에 실행됩니다.

### 12. `depends_on` 메서드

### 설명

- **개념**: 여러 작업에 대한 의존성을 리스트로 지정할 수 있습니다.
- **사용법**: `task.depends_on = [task1, task2]` 형태로 사용합니다.
- **주의사항**: Kubeflow Pipelines SDK의 버전에 따라 `depends_on` 메서드의 지원 여부가 다를 수 있습니다.

### 예제 코드

```python
from kfp import dsl

# 컴포넌트 A 정의
@dsl.component
def a_op():
    print("작업 A 실행")

# 컴포넌트 B 정의
@dsl.component
def b_op():
    print("작업 B 실행")

# 컴포넌트 D 정의
@dsl.component
def d_op():
    print("작업 D 실행")

# 파이프라인 정의
@dsl.pipeline(
    name='depends_on 메서드 예제',
    description='depends_on 메서드를 활용한 작업 순서 제어 예제'
)
def depends_on_pipeline():
    # 작업 A 실행
    a_task = a_op()
    # 작업 B 실행
    b_task = b_op()
    # 작업 D는 작업 A와 B가 완료된 후 실행
    d_task = d_op()
    d_task.depends_on = [a_task, b_task]

if __name__ == '__main__':
    from kfp import compiler
    compiler.Compiler().compile(depends_on_pipeline, 'depends_on_pipeline.yaml')
```

### 결과

- `a_op`와 `b_op`는 동시에 실행됩니다.
- `d_op`는 `a_op`와 `b_op`가 모두 완료된 후에 실행됩니다.

---

## 13. 조건부 실행(Conditional Execution)

특정 조건에 따라 작업을 실행하거나 건너뛸 수 있습니다.

### 3.1 `dsl.Condition` 사용

### 설명

- **개념**: 조건에 따라 특정 블록 내의 작업을 실행합니다.
- **사용법**: `with dsl.Condition(condition_expression):` 형태로 사용합니다.

### 예제 코드

```python
from kfp import dsl

# 컴포넌트 A 정의
@dsl.component
def a_op() -> int:
    print("작업 A 실행")
    return 5  # 예를 들어 숫자 5를 반환

# 컴포넌트 B 정의
@dsl.component
def b_op():
    print("작업 B 실행")

# 파이프라인 정의
@dsl.pipeline(
    name='조건부 실행 예제',
    description='조건에 따라 작업을 실행하는 예제'
)
def conditional_pipeline():
    # 작업 A 실행
    a_task = a_op()
    # 조건부로 작업 B 실행
    with dsl.Condition(a_task.output > 3):
        b_task = b_op()

if __name__ == '__main__':
    from kfp import compiler
    compiler.Compiler().compile(conditional_pipeline, 'conditional_pipeline.yaml')
```

### 결과

- `a_op`의 출력이 3보다 크면 `b_op`가 실행됩니다.
- 그렇지 않으면 `b_op`는 실행되지 않습니다.

---

## 14. Compiling the Pipeline
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

## 17. Submitting the Pipeline
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


## 요약
1. 파이프라인은 `@dsl.pipeline`으로 정의.
2. 각 작업은 `dsl.ContainerOp`으로 정의.
3. 조건, 반복, 출력 공유 등 다양한 제어 기능을 제공.
4. YAML로 컴파일 후 Kubeflow UI나 SDK로 실행.

