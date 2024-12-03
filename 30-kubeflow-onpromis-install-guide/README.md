# Kubernetes v1.29.0 Ubuntu On-premise 설치 가이드

## 1. kubectl, kubeadm, kubelet 설치 (Master, Worker 노드 공통)
```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update -y
# 설치 가능한 kubelet, kubeadm, kubectl 버전 확인
apt-cache madison kubelet

# 위 명령어로 설치 가능한 버전을 확인한 후, 원하는 버전을 선택하여 설치합니다.
# 예시: kubelet=1.29.0-00, kubeadm=1.29.0-00, kubectl=1.29.0-00
sudo apt -y install vim git curl wget kubelet=<버전> kubeadm=<버전> kubectl=<버전>
sudo apt-mark hold kubelet kubeadm kubectl
```

---

## 2. br_netfilter 및 iptables 설정 (Master, Worker 노드 공통)
```bash
sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
```

---

## 3. Containerd 설정 (Master, Worker 노드 공통)
```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system
```

**Docker 제거 후 Containerd 설치:**
```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update -y
sudo apt install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
```

**Containerd 설정 변경:**
```bash
vi /etc/containerd/config.toml
# disabled_plugins = [] 주석 처리
# SystemdCgroup = true 설정 후 저장
sudo systemctl restart containerd
sudo systemctl enable containerd
```

---

## 4. Kubernetes 1.29 이미지 Pull (Master, Worker 노드 공통)
```bash
sudo kubeadm config images pull --image-repository=registry.k8s.io --cri-socket unix:///run/containerd/containerd.sock --kubernetes-version v1.29.0
```

---

## 5. Master 노드 초기화 및 설정
```bash
sudo kubeadm init
# 에러 발생 시 아래 명령 실행 후 재시도:
sudo kubeadm reset
sudo kubeadm init
```

**WeaveNet 설치:**
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```

---

## 6. Worker 노드 Join
```bash
kubeadm join <Master_IP>:6443 --token <token_value> --discovery-token-ca-cert-hash <hash_value>
```

에러 발생 시:
```bash
sudo kubeadm reset
sudo kubeadm init
kubeadm join <Master_IP>:6443 --token <token_value> --discovery-token-ca-cert-hash <hash_value>
```

---

## 7. Master 및 클러스터 상태 확인
```bash
kubectl get nodes
kubectl get pods -A
```

---

### 참고 링크:
- [Kubernetes 공식 문서 - Containerd CRI 설정](https://kubernetes.io/ko/docs/setup/production-environment/container-runtimes/#containerd)
