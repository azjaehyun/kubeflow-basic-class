

## [EFS(NAS storage) install](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/efs-csi.html)


- policy.json 다운로드
```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json
```
  

- policy 생성 
```
aws iam create-policy \
--policy-name AmazonEKS_EFS_CSI_Driver_Policy \
--policy-document file://iam-policy-example.json
```

- oidc-provider 실행
```
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=eks-basic-uw2d-k8s --approve
```


- 아래 명령어 실행 
```
eksctl create iamserviceaccount \
  --name efs-csi-controller-sa \
  --namespace kube-system \
  --cluster eks-basic-uw2d-k8s \
  --attach-policy-arn arn:aws:iam::767404772322:policy/AmazonEKS_EFS_CSI_Driver_Policy \
  --approve \
  --override-existing-serviceaccounts
```  
---

- 실행 결과 확인
```
ubuntu@ip-40-40-11-188:~/nas$ eksctl create iamserviceaccount \
>   --name efs-csi-controller-sa \
>   --namespace kube-system \
>   --cluster eks-basic-uw2d-k8s \
>   --attach-policy-arn arn:aws:iam::767404772322:policy/AmazonEKS_EFS_CSI_Driver_Policy \
>   --approve
2024-01-26 06:32:30 [ℹ]  1 existing iamserviceaccount(s) (kube-system/aws-load-balancer-controller) will be excluded
2024-01-26 06:32:30 [ℹ]  1 iamserviceaccount (kube-system/efs-csi-controller-sa) was included (based on the include/exclude rules)
2024-01-26 06:32:30 [!]  serviceaccounts that exist in Kubernetes will be excluded, use --override-existing-serviceaccounts to override
2024-01-26 06:32:30 [ℹ]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "kube-system/efs-csi-controller-sa",
        create serviceaccount "kube-system/efs-csi-controller-sa",
    } }2024-01-26 06:32:30 [ℹ]  building iamserviceaccount stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2024-01-26 06:32:31 [ℹ]  deploying stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2024-01-26 06:32:31 [ℹ]  waiting for CloudFormation stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2024-01-26 06:33:01 [ℹ]  waiting for CloudFormation stack "eksctl-eks-basic-uw2d-k8s-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2024-01-26 06:33:01 [ℹ]  created serviceaccount "kube-system/efs-csi-controller-sa"
```

- 서비스 어카운트 생성시 에러나면 serviceaccount delete 명령어 후 다시 실행해볼것. [ cloudformation 에서도 확인해볼것 !]
```
eksctl delete iamserviceaccount --cluster=eks-basic-uw2d-k8s --namespace=kube-system --name=AmazonEKS_EFS_CSI_Driver_Policy
```

-  EFS 드라이버 설치 
```
helm repo update
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa
```

- aws ui 화면에서 efs 생성 후 아래 명령어로 efs id 확인
``` 
aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text
```

- efs 에서 사용할 Security Group을 만들자
  * SecurtyGroup에서 eks-nas-security 이름으로 생성 (생성 파라미터는 아래와 같이)
    - NFS - TCP - 40.40.1.0/24 - private-subnet-a-nas-security 
    - NFS - TCP - 40.40.2.0/24 - private-subnet-c-nas-security 

- NAS 네트워크 관리 메뉴에서
  * 보안 그룹 default로 설정되어 있는것을 위에 만든 eks-nas-security로 변경!!

- 이제 StorageClass를 생성해보자 !
```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-0183370b0bf38a3df  ## 위에 efs id 에 출력된 값 넣기.
  directoryPerms: "700"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "2000" # optional
  basePath: "/dynamic_provisioning" ## 본인이 원하는 basePath 설정
```

- test pod 생성 
```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo $(date -u) >> /data/out; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: efs-claim
```

- test pod 생성후 PersistentVolumeClaim이 잘 만들어 졌는지 확인 - 1 [ 컨테이너 이름 확인 ] 
```
kubectl get pod -n kube-system  | grep efs-csi-controller* 
efs-csi-controller-5485b8f7c-48xx9   3/3     Running   0          4h32m
efs-csi-controller-5485b8f7c-z7mhg   3/3     Running   0          4h32m
```
- test pod 생성후 PersistentVolumeClaim이 잘 만들어 졌는지 확인 - 2 [ 해당 로그 확인 ]
```
kubectl logs efs-csi-controller-5485b8f7c-48xx9 \ 
    -n kube-system \
    -c csi-provisioner \
    --tail 10
kubectl logs efs-csi-controller-5485b8f7c-z7mhg \ 
    -n kube-system \
    -c csi-provisioner \
    --tail 10
```

- 정상적으로 생성되었는지 확인
```
I0129 04:46:14.063832       1 controller.go:1509] delete "pvc-630343eb-450f-4960-9ada-d3e83fc06531": started
I0129 04:46:14.063881       1 controller.go:1279] volume pvc-630343eb-450f-4960-9ada-d3e83fc06531 does not need any deletion secrets
I0129 04:46:14.134873       1 controller.go:1524] delete "pvc-630343eb-450f-4960-9ada-d3e83fc06531": volume deleted
I0129 04:46:14.143475       1 controller.go:1569] delete "pvc-630343eb-450f-4960-9ada-d3e83fc06531": persistentvolume deleted succeeded
I0129 04:46:20.436942       1 controller.go:1366] provision "default/efs-claim" class "efs-sc": started
I0129 04:46:20.437533       1 event.go:298] Event(v1.ObjectReference{Kind:"PersistentVolumeClaim", Namespace:"default", Name:"efs-claim", UID:"94c835dc-16d1-4983-bb90-f0767f96e4ad", APIVersion:"v1", ResourceVersion:"40634", FieldPath:""}): type: 'Normal' reason: 'Provisioning' External provisioner is provisioning volume for claim "default/efs-claim"
I0129 04:46:20.547863       1 controller.go:923] successfully created PV pvc-94c835dc-16d1-4983-bb90-f0767f96e4ad for PVC efs-claim and csi volume name fs-05e31ef3411a5e3ac::fsap-0b776e3600ec8c4e7
I0129 04:46:20.547909       1 controller.go:1449] provision "default/efs-claim" class "efs-sc": volume "pvc-94c835dc-16d1-4983-bb90-f0767f96e4ad" provisioned
I0129 04:46:20.548111       1 controller.go:1462] provision "default/efs-claim" class "efs-sc": succeeded
I0129 04:46:20.555062       1 event.go:298] Event(v1.ObjectReference{Kind:"PersistentVolumeClaim", Namespace:"default", Name:"efs-claim", UID:"94c835dc-16d1-4983-bb90-f0767f96e4ad", APIVersion:"v1", ResourceVersion:"40634", FieldPath:""}): type: 'Normal' reason: 'ProvisioningSucceeded' Successfully provisioned volume pvc-94c835dc-16d1-4983-bb90-f0767f96e4ad
```

- test pod log도 확인
```
kubectl exec -i -t -n default efs-app -c app -- sh -c "cat /data/out"

결과>>
Mon Jan 29 05:37:56 UTC 2024
Mon Jan 29 05:38:01 UTC 2024
Mon Jan 29 05:38:06 UTC 2024
Mon Jan 29 05:38:11 UTC 2024
Mon Jan 29 05:38:16 UTC 2024
Mon Jan 29 05:38:21 UTC 2024
Mon Jan 29 05:38:26 UTC 2024
Mon Jan 29 05:38:31 UTC 2024
Mon Jan 29 05:38:36 UTC 2024
Mon Jan 29 05:38:41 UTC 2024
Mon Jan 29 05:38:46 UTC 2024
Mon Jan 29 05:38:51 UTC 2024
Mon Jan 29 05:38:56 UTC 2024
```

- bastion server에서도 efs mount 하고 확인하고 싶다면~
```
sudo su
mkdir /mount
sudo mount -t nfs [원격 서버의 주소 및 경로] [로컬 마운트 포인트]
EX) sudo mount -t nfs  fs-05e31ef3411a5e3ac.efs.us-west-2.amazonaws.com /mount
```

- mount 폴더에 들어가면 아래와 같이 storageclass에 basePath 설정된 폴더 안에 해당 pvc id 별로 폴더가 생기고 있는 것을 확인
```
ubuntu@ip-40-40-11-42:/mount/dynamic_provisioning/pvc-94c835dc-16d1-4983-bb90-f0767f96e4ad$ ls
out  out1.txt  out2.txt
```



### 참고 문헌
```
https://kschoi728.tistory.com/94
```




