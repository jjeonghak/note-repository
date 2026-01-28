# 쿠버네티스 내부 이해

<br>

## 아키텍처 이해
쿠버네티스 클러스터는 컨트롤 플레인과 워커 노드로 구성  

<br>

컨트롤 플레인은 클러스터 기능을 제어하고 전체 클러스터가 동작하게 만드는 역할  
- etcd 분산 저장 스토리지
- API 서버
- 스케줄러
- 컨트롤러 매니저

<br>

워커노드는 컨테이너를 실행하는 작업을 담당  
- kubelet
- 쿠버네티스 서비스 프록시(kube-proxy)
- 컨테이너 런타임(docker, rkt)

<br>

애드온 구성 요소도 존재  
- 쿠버네티스 DNS 서버
- 대시보드
- 인그레스 컨트롤러
- 힙스터
- 컨테이너 네트워크 인터페이스 플러그인

<br>

### 구성 요소의 분산 특성

<img width="400" height="250" alt="kubernetes_architecture" src="https://github.com/user-attachments/assets/e843cb98-fa3d-4be5-b22d-08ab2bb06b88" />

<br>
<br>

컨트롤 플레인 구성 요소의 상태 확인을 위해서는 `ComponentStatus` 리소스 조회  

```
$ kubectl get componentstatues
NAME                STATUS   MESSAGE            ERROR
scheduler           Healthy  ok
controller-manager  Healthy  ok
etcd-0              Healthy  {"health": "true"}
```

<br>

시스템 구성 요소는 오직 API 서버하고만 통신  
특히 etcd는 API 서버와만 유일하게 통신하는 구성 요소  

<br>

컨트롤 플레인 구성 요소는 시스템에 직접 배포하거나 파드로 실행 가능  
kubelet은 항상 일반 시스템 구성 요소(데몬)으로 실행  

```
$ kubectl get pod -o custom-columns=POD:metadata.name,NODE:spec.nodeName --sort-by spec.nodeName -n kube-system
POD                             NODE
kube-controller-manager-master  master
kube-dns-2334855451-37d9k       master
etcd-master                     master
kube-apiserver-master           master
kube-scheduler-master           master
kube-flannel-ds-tgj9k           node1
kube-proxy-ny3xm                node1
kube-flannel-ds-0eek8           node2
kube-proxy-sp362                node2
kube-flannel-ds-r5yf4           node3
kube-proxy-og9ac                node3
```

<br>

### etcd
모든 오브젝트는 API 서버가 다시 시작되거나 실패하더라도 유지하기 위해 매니페스트가 영구적으로 저장될 필요 존재  
일관된 키-값 저장소로 etcd 사용, 오직 API 서버만 etcd에 직접적으로 통신  
쿠버네티스는 모든 데이터를 `/registry` 아래에 저장  

```
$ etcdctl ls /registry
/registry/configmaps
/registry/daemonsets
/registry/deployments
/registry/events
/registry/namespaces
/registry/pods
...
```

<br>

저장된 데이터는 네임스페이스 단위로 저장
쿠버네티스 버전 1.7 이전에는 시크릿 리소스도 이와 같이 저장되어 etcd에 직접 접근해서 조회 가능  

```
$ etcdctl ls /registry/pods
/registry/pods/default
/registry/pods/kube-system

$ etcdctl ls /registry/pods/default
/registry/pods/default/kubia-159041347-xk0vc
/registry/pods/default/kubia-159041347-wt6ga
/registry/pods/default/kubia-159041347-hp2o5

$ etcdctl ls /registry/pods/default/kubia-159041347-wt6ga
{"kind":"Pod","apiVersion":"v1","metadata":{"name":"kubia-159041347-wt6ga",
"generateName:"kubia-159041347-","namespace":"default","selfLink":...
```

<br>

저장된 오브젝트의 일관성과 유효성 보장을 위해 낙관적 잠금 메커니즘을 준수  
쿠버네티스는 다른 모든 구성 요소가 API 서버를 통하도록 함으로써 이를 개선  
API 서버 한곳에서 낙관적 잠금 메커니즘을 구현해서 클러스터 상태를 업데이트하기 대문에 오류 발생 가능성 낮음  

<br>

<img width="600" height="350" alt="etcd_consensus_algorithm" src="https://github.com/user-attachments/assets/3703b018-ea6a-416b-8b68-0315b25d3cb1" />

고가용성 보장을 위해 두개 이상(홀수)의 etcd 인스턴스를 실행하는 것이 일반적  
분산 시스템은 실제 상태가 무엇인지 합의 과정 필수  
etcd는 RAFT 합의 알고리즘을 사용해서 대다수의 노드가 동의하는 현재 상태이거나 이전에 동의된 상태 중 하나임을 보장  
합의 알고리즘은 과반수 또는 쿼럼이 필요  

<br>

### API 서버

<img width="600" height="250" alt="api_server_and_etcd" src="https://github.com/user-attachments/assets/ea1cd20a-5ec7-466c-8743-7bdd7c025fb0" />

먼저 요청을 보낸 클라이언트를 인증, 하나 이상의 인증 플러그인에 의해 수행  
HTTP 요청을 검사해서 클라이언트 사용자 이름, 사용자 ID 등 정보를 추출하고 인가 단계에서 사용  
인가 플러그인은 인증된 사용자가 요청한 작업이 요청한 리소스를 대상으로 수행 가능한지 판별  
이후 리소스 생성, 수정, 삭제 요청은 어드미션 컨트롤 플러그인으로 전송(조회는 거치지 않음)  
- `AlwaysPullImages`: 파드의 `imagePullPolicy`를 Always로 변경  
- `ServiceAccount`: 명시적으로 지정하지 않은 경우 default 서비스 어카운트를 적용  
- `NamespaceLifecycle`: 삭제되는 과정에 있는 네임스페이스와 존재하지 않는 네임스페이스 안에 파드 생성 방지  
- `ResourceQuota`: 특정 네임스페이스 안에 있는 파드가 해당 네임스페이스에 할당된 CPU와 메모리만 사용하도록 강제  
요청이 모든 어드미션 컨트롤 플러그인을 통과하면 유효성 검증이후 etcd에 저장  

<br>

<img width="600" height="250" alt="api_server_and_clients" src="https://github.com/user-attachments/assets/d794882a-7e3a-4049-b9c4-56a2fd42bd28" />

API 서버는 직접적으로 오브젝트를 생성하지 않고 통보만 담당  
클라이언트는 API 서버에 HTTP 연결을 맺고 변경 사항을 감지(`watch`)  
kubectl 도구는 리소스 변경을 감시할 수 있는 클라이언트 중 하나  

```
$ kubectl get pods --watch
NAME                   READY  STATUS             RESTARTS  AGE
kubia-159041347-i4j3i  0/1    Pending            0         0s
kubia-159041347-i4j3i  0/1    Pending            0         0s
kubia-159041347-i4j3i  0/1    ContainerCreating  0         1s
kubia-159041347-i4j3i  0/1    Running            0         3s
kubia-159041347-i4j3i  1/1    Running            0         5s
kubia-159041347-i4j3i  1/1    Terminating        0         9s
kubia-159041347-i4j3i  0/1    Terminating        0         17s
```

<br>

### 스케줄러
API 서버의 감시 메커니즘을 통해 새로 생성될 파드를 대기하면서 할당된 노드가 없는 새로운 파드를 노드에 할당  
스케줄러는 선택된 노드에 파드를 실행하도록 지시하지 않고 단지 API 서버로 파드 정의를 갱신  
API 서버는 대상 노드의 kubelet에 파드가 스케줄링된 것을 통보, kubelet은 파드 컨테이너를 생성하고 실행  
- 모든 노드 중에 파드를 스케줄링할 수 있는 노드 목록을 필터링
- 수용 가능한 노드의 우선순위를 정하고 점수가 높은 노드를 선택

<img width="600" height="200" alt="sheduler" src="https://github.com/user-attachments/assets/841ee06c-07f2-4ce7-876f-4c4463732881" />

<br>
<br>

파드가 수용할 수 있는 노드를 탐색하기 위해 미리 설정된 조건 함수 목록에 각 노드를 전달  
- 노드가 하드웨어 리소스에 대한 파드 요청 충족 여부
- 노드에 가용 리소스
- 파드를 특정 노드로 요청한 경우 해당 노드 여부
- 노드 셀렉터와 일치하는 레이블 보유 여부
- 특정 호스트 포트 할당 여부
- 특정 볼륨 요청에 대한 마운트 가능 여부
- 노드의 테인트와 톨러레이션 여부
- 어피니티와 안티 어피니티 규칙 지정 여부

<br>

클러스터에서 다중 스케줄러를 실행 가능  
파드 정의 안에 `schedulerName` 속성을 통해 스케줄링할 스케줄러 지정  
해당 속성이 정의되지 않은 경우 기본적으로 `default-scheduler` 사용  

<br>

### 컨트롤러 매니저
API 서버는 리소스를 etcd에 저장하고 변경 사항을 클라이언트에 통보하는 것만 담당  
API 서버로 배포된 리소스에 지정된대로 시스템을 원하는 상태로 수렴되도록 하는 다른 활성 구성 요소 필요  
현재는 다양한 조정 작업을 수행하는 여러 컨트롤러가 하나의 컨트롤러 매니저 프로세스에서 실행  
- 레플리케이션 매니저
- 레플리카셋, 데몬셋, 잡 컨트롤러
- 디플로이먼트 컨트롤러
- 스테이트풀셋 컨트롤러
- 노드 컨트롤러
- 서비스 컨트롤러
- 엔드포인트 컨트롤러
- 네임스페이스 컨트롤러
- 퍼시스턴트볼륨 컨트롤러
- 이외의 컨트롤러

<br>

컨트롤러는 모두 API 서버에서 리소스 변경되는 것을 감지하고 각 변경 작업을 수행  
일반적으로 조정 루프를 실행해서 실제 상태를 원하는 상태로 조정하고 새로운 상태를 리소스 `status` 섹션에 기록  
어떤 컨트롤러도 kubelet과 직접 통신하거나 명령을 내리지 않음  

<br>

### kubelet
컨트롤 플레인의 일부이지만 마스터 노드에서 실행되지 않고 서비스 프록시와 함께 워커 노드에 실행  
kubelet은 실행중인 노드를 노드 리소스로 만들어서 API 서버에 등록  
지속적으로 API 서버를 모니터링해서 해당 노드에 파드가 스케줄링되면 파드의 컨테이너를 시작  
또한 지속적으로 실행중인 컨테이너를 모니터링해서 상태, 이벤트, 리소스 사용량을 API 서버에 보고  
컨테이너 라이브니스 프로브를 실행하는 구성 요소  
API 서버와 통신 없이 특정 로컬 디렉토리 안에 있는 매니페스트 파일을 기반으로 정적 파드 실행 가능  

<img width="550" height="300" alt="kubelet_and_static_pod" src="https://github.com/user-attachments/assets/84cf4800-fe21-4df9-8e43-9b401f6ff460" />

<br>
<br>

### 서비스 프록시
kube-proxy는 서비스의 IP와 포트로 들어온 접속을 서비스를 지원하는 파드 중 하나와 연결  
서비스가 둘 이상의 파드에서 지원되는 경우 프록시는 파드 간에 로드 밸런싱을 수행  

<br>

<img width="500" height="150" alt="kube_proxy_v1" src="https://github.com/user-attachments/assets/f15714c1-5683-4478-99d7-9e0036938b43" />

초기 구현은 사용자 공간에서 동작하는 프록시(`userspace` 프록시 모드)  
실제 서버 프로세스가 연결을 수락하고 이를 파드로 전달  
서비스 IP로 향하는 연결을 가로채기 위해 프록시는 `iptables` 규칙을 설정해 이를 프록시 서버로 전송  

<br>

<img width="500" height="150" alt="kube_proxy_v2" src="https://github.com/user-attachments/assets/62680de3-8f98-4920-8ce5-e46f6e13cc59" />

현재는 `iptables` 규칙만 사용해 프록시 서버를 거치지 않고 패킷을 무작위로 선택한 파드로 전달(`iptables` 프록시 모드)  
이 두 모드의 차이점은 패킷이 kube-proxy를 통과해 사용자 공간에서 처리되는지 아니면 커널에서 처리되는지 여부  
또한 `userspace` 프록시 모드는 라운드 로빈 방식이며, `iptables` 프록시 모드는 무작위 방식  

<br>

<img width="500" height="500" alt="iptables_proxy_mode" src="https://github.com/user-attachments/assets/9410835f-feb5-4d98-918e-88686167d569" />

API 서버에서 서비스를 생성하면 가상 IP 주소가 할당되며 워커 노드의 kube-proxy 에이전트에 통보  
각 kube-proxy는 실행중인 노드에 해당 서비스 주소로 접근 가능하도록 변경  
서비스 IP/포트 쌍으로 향하는 패킷을 가로채서 목적지 주소를 변경해 패킷이 서비스를 지원하는 여러 파드로 리다이렉션  
서비스와 함께 엔드포인트 오브젝트가 변경되는 것을 같이 감시  

<br>

## 컨트롤러 협업

<img width="550" height="300" alt="controller_manager" src="https://github.com/user-attachments/assets/19f0567d-cbef-4d8d-b25f-681d3958237c" />

<br>
<br>

### 이벤트 체인

<img width="650" height="450" alt="event_chain" src="https://github.com/user-attachments/assets/d7c95af6-a8c5-4ec9-b488-d2d6692d0801" />

kubectl에 의해서 매니페스트가 쿠버네티스 API 서버에 전송  
API 서버는 리소스 정의를 검증하고 이를 etcd에 저장한 후 결과 응답  
이때 연계된 이벤트가 발생  

<br>

### 클러스터 이벤트 관찰

```
$ kubectl get events --watch
NAME                KIND        REASON             SOURCE
...kubia            Deployment  ScalingReplicaSet  deployment-controller
                    Scaled up replica set kubia-193 to 3
...kubia-193        ReplicaSet  SuccessfulCreate   replicaset-controller
                    Created pod: kubia-193-w7112
...kubia-193-tpg6j  Pod         Scheduled          default-scheduler
                    Successfully assigned kubia-193-tpg6j to node1
...kubia-193        ReplicaSet  SuccessfulCreate   replicaset-controller
                    Created pod: kubia-193-39590
...kubia-193        ReplicaSet  SuceessfulCreate   replicaset-controller
                    Created pod: kubia-193-tpg6j
...
```

<br>

## 파드

<img width="500" height="200" alt="pause_container" src="https://github.com/user-attachments/assets/980dbec2-c7cb-4741-8b9e-79bbee87a912" />

```
$ kubectl run nginx --image=nginx
deployment "nginx" created

docker@minikubeVM:~$ docker ps
CONTAINER ID  IMAGE                 COMMAND                 CREATED
c917a6f3c3f7  nginx                 "nginx -g 'daemon off"  4 seconds ago
98b8bf797174  gcr.io/.../pause:3.0  "/pause"                7 seconds ago
```

또한 kubelet은 실행한 파드 내에 퍼즈(`pause`) 컨테이너를 함께 실행  
파드의 모든 컨테이너가 동일한 네트워크와 리눅스 네임스페이스를 공유하도록하는 인프라스트럭처 컨테이너  
파드의 라이프사이클과 동일, 만약 중간에 종료되면 kubelet은 파드의 모든 컨테이너를 다시 생성

<br>

### 파드 간 네트워킹
각 파드는 고유한 IP 주소를 보유, NAT 없이 플랫(`flat`) 네트워크로 서로 통신  
네트워크는 쿠버네티스 자체가 아닌 시스템 관리자 또는 컨테이너 네트워크 인터페이스(`CNT`) 플러그인에 의해 제공  

<br>

<img width="500" height="350" alt="pod_networking" src="https://github.com/user-attachments/assets/ed9a5c52-15a5-40ec-b5e6-0217bcee7f2b" />

특정 네트워크 기술 사용을 강요하지 않지만 파드가 동일한 워커 노드에서 서로 통신 가능해야함  
네트워크는 파드가 자신을 보는 IP 주소가 다른 모든 파드에서 해당 파드 주소를 찾을때도 동일한 IP 주소로 보여야함  
외부 통신할때는 패킷의 출발지 IP를 사설 IP가 아닌 호스트 워커 노드의 IP로 변경  

<br>

<img width="400" height="250" alt="bridge" src="https://github.com/user-attachments/assets/021a9153-1638-4076-bf9b-82d22f0fb042" />

파드의 컨테이너는 퍼즈 컨테이너의 네트워크 네임스페이스를 사용  
인프라스트럭처 컨테이너가 시작되기 전에 컨테이너를 위한 가상 이더넷 인터페이스 쌍(`veth`)이 생성  
한쪽 인터페이스는 호스트의 네임스페이스에 남고, 다른쪽은 컨테이너 네트워크 네임스페이스 안으로 옮겨짐  
호스트의 네트워크 네임스페이스에 있는 인터페이스는 컨테이너 런타임이 사용 가능하게 설정된 네트워크 브릿지에 연결  
컨테이너 내부에서 실행되는 애플리케이션은 `eth0` 인터페이스로 전송  
호스트 네임스페이스의 다른 `veth` 인터페이스로 나와 브릿지로 전달  

<br>

<img width="600" height="300" alt="node_and_bridge" src="https://github.com/user-attachments/assets/8873c26c-2956-435d-bb96-67be0b53e3ab" />

서로 다른 노드 사이에 브릿지 연결 가능  
오버레이, 언더레이 네트워크 또는 일반적인 계층 3 라우팅을 통해 가능  
파드 IP는 전체 클러스터 내에서 유일해야하기 때문에 노드 사이의 브릿지는 겹치지 않는 주소 범위를 사용  
패킷은 먼저 `veth` 쌍을 통과한 후 브릿지를 통해 노드 물리 어댑터로 전달  
회선을 통해 다른 노드의 물리 어댑터로 전달되고 브릿지를 지나 목표 컨테이너의 `veth` 쌍을 통과  
해당 방식은 두 노드가 라우터 없이 같은 네트워크 스위치에 연결된 경우에만 동작  
소프트웨어 정의 네트워크(`SDN`) 사용하면 네트워크 토폴로지가 복잡하더라도 같은 네트워크 연결로 간주  

<br>

컨테이너 네트워크 인터페이스(`CNI`) 플러그인을 통해 설정 가능  
kubelet 시작시 `--network-plugin=cni` 옵션을 사용  
- `Calico`
- `Flannel`
- `Romana`
- `Weave Net`

<br>

## 고가용성 클러스터

<img width="600" height="300" alt="control_plain" src="https://github.com/user-attachments/assets/62abfdf6-7ef0-4c0f-a494-1c7a26e451db" />

다양한 컨트롤러는 노드 장애시 애플리케이션이 특정 규모로 원활하게 동작하도록 지원  
수평 확장을 위해서는 디플로이먼트 리소스로 애플리케이션을 실행  
수평 확장이 불가한 경우 리더 선출 메커니즘 사용  
컨트롤 플레인 또한 여러 마스터 노드로 구성해서 가용성 보장  

<br>

<img width="600" height="250" alt="controller_manager_and_scheduler" src="https://github.com/user-attachments/assets/84dac9dc-4167-4dc1-a664-1a5032175223" />

여러 복제본을 동시에 실행할 수 있는 API 서버와 달리 컨트롤러 매니저나 스케줄러는 아님  
감시를 통해 상태 변경을 적용할때 여러 인스턴스가 서로 경쟁해서 원하지 않는 결과 초래 가능  
한번의 하나의 인스턴스만 확성화하고 각 개별 구성 요소는 선출된 리더일 때만 활성화  

<br>

컨트롤 플레인 구성 요소에서 사용하는 리더 선출은 서로 통신할 필요없음(엔드포인트 리소스 사용)  
단지 동일한 이름으로 된 서비스가 존재하지 않는 한 부작용이 없기 때문에 사용  
`control-plane.alpha.kubernetes.io/leader` 어노테이션의 `holerIdentity` 필드가 현재 리더 이름  
이 필드에 이름을 넣는 것에 처음 성공한 인스턴스가 리더  

```yaml
$ kubectl get endpoints kube-scheduler -n kube-system -o yaml
apiVersion: v1
kind: Endpoints
metadata:
  annotations:
    control-plane.alpha.kubernetes.io/leader: '{"holderIdentity":
    "minikube","leaseDurationSeconds":15,"acquireTime":
    "2017-05-27T18:54:53Z", "renewTime":"2017-05-28T13:07:49Z",
    "leaderTransitions":0}'
...
```

<br>
