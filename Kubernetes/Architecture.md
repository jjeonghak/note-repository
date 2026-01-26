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


























