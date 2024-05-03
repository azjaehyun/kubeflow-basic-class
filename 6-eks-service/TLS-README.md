### certmanager를 이용한 tls 샘플 


### tls 생성
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
 -out ingress-tls.crt \
 -keyout ingress-tls.key \
 -subj "/CN=ingress-tls" 

kubectl create secret tls ingress-tls \
--namespace default \
--key ingress-tls.key \
--cert ingress-tls.crt
```

### tls ingress 적용방법 
```
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: http-go-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /welcome/test
    nginx.ingress.kubernetes.io/ssl-redirect: "true" # 리다이렉트 설정
spec:
  tls:
  - hosts:
    - gasbugs.com
    secretName: ingress-tls
  rules:
    - host: gasbugs.com
      http:
        paths:
          - pathType: Exact
            path: /welcome/test
            backend:
              service:
                name: http-go
                port:
                  number: 80
EOF

```