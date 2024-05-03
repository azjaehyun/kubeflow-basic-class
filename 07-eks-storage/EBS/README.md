# eks-basic-class
eks-basic-class - EKS를 처음 접하는 분

## ebs csi driver install

### [aws ebs csi driver install & delete](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/managing-ebs-csi.html)
```
eksctl create addon --name aws-ebs-csi-driver --cluster eks-basic-uw2d-k8s --service-account-role-arn arn:aws:iam::767404772322:role/AmazonEKS_EBS_CSI_DriverRole --force

install check
eksctl get addon --name aws-ebs-csi-driver --cluster eks-basic-uw2d-k8s
```

```
ubuntu@ip-40-40-11-122:~/.kube$ eksctl create addon --name aws-ebs-csi-driver --cluster eks-init-uw2d-eks --service-account-role-arn arn:aws:iam::767404772322:role/AmazonEKS_EBS_CSI_DriverRole --force
2024-01-22 05:42:23 [ℹ]  Kubernetes version "1.28" in use by cluster "eks-init-uw2d-eks"
2024-01-22 05:42:24 [ℹ]  using provided ServiceAccountRoleARN "arn:aws:iam::767404772322:role/AmazonEKS_EBS_CSI_DriverRole"
2024-01-22 05:42:24 [ℹ]  creating addon
ubuntu@ip-40-40-11-122:~/.kube$ eksctl get addon --name aws-ebs-csi-driver --cluster eks-init-uw2d-eks                       
2024-01-22 05:43:01 [ℹ]  Kubernetes version "1.28" in use by cluster "eks-init-uw2d-eks"
2024-01-22 05:43:01 [ℹ]  to see issues for an addon run `eksctl get addon --name <addon-name> --cluster <cluster-name>`
NAME                    VERSION                 STATUS          ISSUES  IAMROLE                                                         UPDATE AVAILABLE        CONFIGURATION VALUES
aws-ebs-csi-driver      v1.26.1-eksbuild.1      CREATING        0       arn:aws:iam::767404772322:role/AmazonEKS_EBS_CSI_DriverRole
```

# efs 사용하기
EBS와 EFS의 차이점  

EBS	
- 하나의 AZ만 접근 가능
- 처음 설정한 크기
- GB당 0.116$  

EFS
- 여러 AZ에서 접근 가능
- 사용한 만큼 확장
- GB당 0.33$

#  gp3
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "10"
  fsType: ext4
```

# pvc 
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3-storage
  resources:
    requests:
      storage: 20Gi
```

# pvc + pod 
```
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  volumes:
    - name: mypvc
      persistentVolumeClaim:
        claimName: mypvc
  containers:
    - name: mycontainer
      image: nginx  # 사용할 이미지에 따라 조정
      volumeMounts:
        - mountPath: "/mnt/data"
          name: mypvc
```