## 8. S3 파일 기반 인공지능 모델 학습 파이프라인

### 설명
- S3에 파일이 업로드되면 해당 파일을 사용하여 인공지능 모델을 학습시키는 파이프라인
- 학습된 모델을 ECR에 업로드하고, 기존 모델과 성능 비교 후 배포 결정

### 코드 예제
```python
import kfp
from kfp import dsl
from kubernetes.client.models import V1Volume, V1VolumeMount

# NFS 볼륨 정의
nfs_volume = V1Volume(
    name='nfs-volume',
    nfs={
        'server': '<NFS_SERVER_IP>',
        'path': '/path/to/nfs/share'  # NFS 서버 경로
    }
)

# NFS 볼륨 마운트
nfs_volume_mount = V1VolumeMount(
    name='nfs-volume',
    mount_path='/data'  # 모든 작업이 /data를 공유
)

# S3에서 파일을 다운로드하는 작업 정의
def download_from_s3_op(bucket_name: str, object_key: str):
    return dsl.ContainerOp(
        name='Download From S3',
        image='amazon/aws-cli',
        command=['aws', 's3', 'cp', f's3://{bucket_name}/{object_key}', '/data/input_file']
    ).add_volume(nfs_volume).add_volume_mount(nfs_volume_mount)

# 모델을 학습시키는 작업 정의
def train_model_op(input_path: str):
    return dsl.ContainerOp(
        name='Train Model',
        image='my-custom-image:latest',
        command=['python', 'train.py'],
        arguments=['--input', input_path, '--output', '/data/model']
    ).add_volume(nfs_volume).add_volume_mount(nfs_volume_mount)

# 학습된 모델을 ECR에 업로드하는 작업 정의
def upload_to_ecr_op(model_path: str, ecr_repo: str):
    return dsl.ContainerOp(
        name='Upload to ECR',
        image='amazon/aws-cli',
        command=['aws', 'ecr', 'put-image', '--repository-name', ecr_repo, '--image', model_path]
    ).add_volume(nfs_volume).add_volume_mount(nfs_volume_mount)

# 새로운 모델과 기존 모델을 평가하는 작업 정의
def evaluate_model_op(new_model_path: str, old_model_path: str):
    return dsl.ContainerOp(
        name='Evaluate Model',
        image='my-evaluation-image:latest',
        command=['python', 'evaluate.py'],
        arguments=[
            '--new_model', new_model_path,
            '--old_model', old_model_path,
            '--output', '/data/evaluation_result'
        ],
        file_outputs={'result': '/data/evaluation_result'}  # 평가 결과를 Kubeflow 출력으로 정의
    ).add_volume(nfs_volume).add_volume_mount(nfs_volume_mount)

# 성능이 좋은 모델을 배포하는 작업 정의
def deploy_model_op(model_path: str):
    return dsl.ContainerOp(
        name='Deploy Model',
        image='my-deployment-image:latest',
        command=['python', 'deploy.py'],
        arguments=['--model', model_path]
    ).add_volume(nfs_volume).add_volume_mount(nfs_volume_mount)

# 전체 파이프라인 정의
@dsl.pipeline(
    name='S3 to Model Training Pipeline',
    description='Pipeline that trains a model from S3 data and conditionally deploys it.'
)
def s3_model_pipeline(bucket_name: str, object_key: str, ecr_repo: str, old_model_path: str):
    # S3에서 파일 다운로드 단계
    download_step = download_from_s3_op(bucket_name, object_key)
    # 모델 학습 단계 (S3에서 다운로드한 파일 사용)
    train_step = train_model_op(download_step.output)
    # 학습된 모델을 ECR에 업로드
    upload_step = upload_to_ecr_op(train_step.output, ecr_repo)
    # 새로운 모델과 기존 모델의 성능 평가 단계
    evaluate_step = evaluate_model_op(train_step.output, old_model_path)

    # 평가 결과가 'better'이면 모델을 배포
    with dsl.Condition(evaluate_step.outputs['result'] == 'better'):
        deploy_model_op(train_step.output)

# 파이프라인을 YAML 파일로 컴파일
kfp.compiler.Compiler().compile(s3_model_pipeline, 's3_model_pipeline.yaml')
```

## 9. 파이프라인 모니터링 및 디버깅

### 설명
- Kubeflow UI에서 파이프라인의 실행 상태를 모니터링하는 방법
- 로그 확인과 디버깅을 통해 문제를 해결하는 방법

### 실습
- Kubeflow Dashboard에서 파이프라인 모니터링 실습
- 각 단계의 로그를 확인하고 오류 해결 방법 탐구

---

이 커리큘럼은 Kubeflow Pipelines를 학습하는 데 필요한 단계들을 포괄적으로 다룹니다. 각 섹션은 점진적으로 난이도가 올라가며, 실습을 통해 개념을 확실히 익히도록 설계되었습니다. 필요에 따라 추가적인 설명이나 실습 자료를 보강할 수 있습니다.
