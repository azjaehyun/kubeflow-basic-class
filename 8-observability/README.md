# eks-basic-class
eks-basic-class - EKS를 처음 접하는 분

## helm을 사용하여 prometheus + grafana을 설치
- repo 추가
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm search repo kube-prometheus-stack
```

- 설치 옵션 설정
```
helm pull prometheus-community/kube-prometheus-stack
tar xf kube-prometheus-stack-54.2.1.tgz
cd kube-prometheus-stack/
```

- helm value.yaml 파일 - 954 line 변경
```
adminPassword: passwd # 초기값 변경
```

- 설치 명령어
```
helm install --create-namespace prom-stack . -n monitoring -f values.yaml
```

- 테스팅 [ 포트 포워딩 ]
```
kubectl port-forward --address 0.0.0.0 -n monitoring svc/prom-stack-grafana 9000:80 &
kubectl port-forward --address 0.0.0.0 -n monitoring svc/prom-stack-kube-prometheus-prometheus 9091:9090 &
```

- 삭제 명령어
```
helm delete prom-stack -n monitoring
```

- 재배포 방법 values.yaml 수정후 실행
```
helm upgrade prom-stack . -n monitoring -f values.yaml
```

- 계정 정보 확인 [ username 확인 방법 ]
```
kubectl get secret --namespace monitoring prom-stack-grafana -o jsonpath="{.data.admin-user}" | base64 --decode ; echo
```
    
- 계정 정보 확인 [ password 확인 방법 ]
```
kubectl get secret --namespace monitoring prom-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

---

- ingress와 맵핑하는 법은 본인 숙제 !!!
  * [팁은 해당 주소 클릭](https://forcloud.tistory.com/206)
