# eks-basic-class
eks-basic-class - EKS를 처음 접하는 분

---

### 1. k8s architecture
[architecture-docs](https://www.redhat.com/ko/topics/containers/kubernetes-architecture)

![img](https://www.redhat.com/rhdc/managed-files/kubernetes_diagram-v3-770x717_0.svg)

---



#### control plane
- kube-apiserver : 
쿠버네티스 클러스터와 상호 작용해야 하나요? API에 요청하세요. 쿠버네티스 API는 쿠버네티스 컨트롤 플레인의 프론트엔드로, 내부 및 외부 요청을 처리합니다. API 서버는 요청이 유효한지 판별하고 유효한 요청을 처리합니다. <U>REST 호출이나 kubectl 커맨드라인 인터페이스 또는 kubeadm과 같은 기타 CLI(command-line interface)를 통해 API에 액세스할 수 있습니다.</U>

- kube-scheduler : 
클러스터가 양호한 상태인가? 새 컨테이너가 필요하다면 어디에 적합한가? 쿠버네티스 스케줄러는 이러한 것들을 주로 다룹니다.
<U>스케줄러는 CPU 또는 메모리와 같은 포드의 리소스 요구 사항과 함께 클러스터의 상태를 고려합니다.</U> 그런 다음 포드를 적절한 컴퓨팅 노드에 예약합니다.

- kube-controller-manager : 
컨트롤러는 실제로 클러스터를 실행하고 쿠버네티스 controller-manager에는 여러 컨트롤러 기능이 하나로 통합되어 있습니다. <U>하나의 컨트롤러는 스케줄러를 참고하여 정확한 수의 포드가 실행되게 합니다.</U> 포드에 문제가 생기면 또 다른 컨트롤러가 이를 감지하고 대응합니다. 컨트롤러는 서비스를 포드에 연결하므로 요청이 적절한 엔드포인트로 이동합니다. 또한 계정 및 API 액세스 토큰 생성을 위한 컨트롤러가 있습니다.

- etcd : 
<U>설정 데이터와 클러스터의 상태에 관한 정보는 키-값 저장소 데이터베이스인 etcd에 상주합니다. </U>내결함성을 갖춘 분산형 etcd는 클러스터에 관한 궁극적 정보 소스(Source Of Truth, SOT)가 되도록 설계되었습니다.

---


#### 쿠버네티스 노드 개념과 특징
- 노드 :
쿠버네티스 클러스터에는 최소 1개 이상의 컴퓨팅 노드가 필요하지만 일반적으로 여러 개가 있습니다. 포드는 노드에서 실행하도록 예약되고 오케스트레이션됩니다. 클러스터의 용량을 확장해야 한다면 노드를 더 추가하면 됩니다.

- 포드 :
포드는 쿠버네티스 오브젝트 모델에서 가장 작고 단순한 유닛으로, 애플리케이션의 단일 인스턴스를 나타냅니다. 각 포드는 컨테이너 실행 방식을 제어하는 옵션과 함께 컨테이너 하나 또는 긴밀히 결합된 일련의 컨테이너로 구성되어 있습니다. 포드를 퍼시스턴트 스토리지에 연결하여 스테이트풀(stateful) 애플리케이션을 실행할 수 있습니다.

- 컨테이너 런타임 엔진 :
컨테이너 실행을 위해 각 컴퓨팅 노드에는 컨테이너 런타임 엔진이 있습니다. 그중 한 가지 예가 Docker입니다. 하지만 쿠버네티스는 rkt, CRI-O와 같은 다른 Open Container Initiative 호환 런타임도 지원합니다.

- kubelet : 
각 컴퓨팅 노드에는 컨트롤 플레인과 통신하는 매우 작은 애플리케이션인 kubelet이 있습니다. kublet은 컨테이너가 포드에서 실행되게 합니다. 컨트롤 플레인에서 노드에 작업을 요청하는 경우 kubelet이 이 작업을 실행합니다.

- kube-proxy :
각 컴퓨팅 노드에는 쿠버네티스 네트워킹 서비스를 용이하게 하기 위한 네트워크 프록시인 kube-proxy도 있습니다. kube-proxy는 운영 체제의 패킷 필터링 계층에 의존하거나 트래픽 자체를 전달하여 클러스터 내부 또는 외부의 네트워크 통신을 처리합니다.

---

#### 쿠버네티스에서 컨테이너 동작 Flow

<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2Fy8SDd%2Fbtrw2NujVjE%2FY7wFvnKBiqUyCuShKE0Uc0%2Fimg.png" width="200" height="300"/></p>

1. kubectl issues REST call : kubectl 명령이 Master Node(혹은 Control-plane)으로 전달됩니다.  
Master에는 REST API Server가 있어서 kubectl의 명령어를 받아들입니다.  


<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FbWBiad%2FbtrwUkUw7qx%2FdGp1AogykknAQiBMWwJVnK%2Fimg.png" width="500" height="300"/></p>  

2. Pod created and scheduled to a worker node : 작업 중인 Node 중 어느 노드에 파드가 생성되면 좋을지 Scheduler에게 요청합니다.  
Scheduler는 노드들의 상태들을 보고 어느 노드가 가장 놓을지 선택 후 응답을합니다.


<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2Fctw5G0%2FbtrwRxUECZz%2FJH2RjAndNPidPzaRRleaW0%2Fimg.png" width="500" height="300"/></p>  

3. Kubelet is notified : Scheduler가 Pod를 생성하기 적당한 노드를 찾아 해당 노드의 kubelet에 파드 생성 요청을 합니다.


<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FbDc6p2%2FbtrwRxAhu9S%2FoLEidKMVFCP8ulJdQon5IK%2Fimg.png" width="350" height="200"/></p>  

4. kubelet instructs Docker to run the image : Pod 생성 요청을 받은 kublet이 Docker 데몬에게 실제 컨테이너의 생성을 요청합니다.


<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2Fb6d9sk%2FbtrwVcnRaLT%2FJu4xTVO3mbwnbfXzkJ9Eak%2Fimg.png" width="350" height="300"/></p> 

5. Docker pulls and runs nginx : 컨테이너 생성 요청을 받은 Docker 데몬이 Docker Hub에서 이미지를 찾아서 이미지를 생성합니다.
이렇게 생성된 컨테이너를 쿠버네티스에서는 'Pod'라는 단위로 관리합니다.


---

#### K8s 동작 flow Image
<p align="center"><img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2Fcy3GnE%2Fbtrh3qU6hMK%2Fkul5MSr7mnqF6kmE7i0m9K%2Fimg.png" width="700" height="500"/></p> 


---

### eks endpoint architecture 종류

- [공식 AWS endpoint architecture 종류 가이드 문서](https://aws.amazon.com/ko/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/)

  * 각 엔드포인트 별로 차이점을 명확하게 알아야 합니다.  

- [Public endpoint only] ( EKS 테스트용 및 빠른 구축시 사용 )
 <p align="center"><img src="https://d2908q01vomqb2.cloudfront.net/fe2ef495a1152561572949784c16bf23abb28057/2020/04/10/endpoint_public.png" width="700" height="400"/></p>  

--- 

- [Public and Private endpoints] (일반적인 웹서비스 구축시 사용)
<p align="center"><img src="https://d2908q01vomqb2.cloudfront.net/fe2ef495a1152561572949784c16bf23abb28057/2020/04/10/endpoint_pubprivate.png" width="700" height="400"/></p>  

<p align="center">아래는 public and private 구성 infra arch 구조</p>
<p align="center"><img src="https://devblog.kakaostyle.com/img/content/2022-03-31-2/2022-03-31-2-01.png" width="500" height="400"/></p>  


--- 

- [Private endpoint only]  (보안이 중요한 서비스 - 금융)
<p align="center"><img src="https://d2908q01vomqb2.cloudfront.net/fe2ef495a1152561572949784c16bf23abb28057/2020/04/10/endpoint_private.png" width="700" height="400"/></p>  


---