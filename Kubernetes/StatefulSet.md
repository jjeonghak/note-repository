# 스테이트풀셋
애플리케이션의 스테이트풀을 관리하는데 사용하는 워크로드 API 오브젝트  

<br>

## 스테이트풀 파드 복제
레플리카셋은 하나의 파드 템플릿에서 여러 개의 파드 레플리카를 생성  
하지만 파드 템플릿에는 클레임에 대한 참조가 있어서 레플리카 별로 퍼시스턴트볼륨클레임을 다르게 사용 불가  

- 파드 인스턴스별로 하나의 레플리카셋 사용

<img width="500" height="200" alt="multi_replicaset" src="https://github.com/user-attachments/assets/b19c3238-faa9-4ade-8c2b-b732dd937df1" />

<br>
<br>

- 동일 볼륨을 여러개의 디렉토리로 사용

<img width="500" height="250" alt="volume_and_multi_dir" src="https://github.com/user-attachments/assets/8e06ca0b-2b40-4604-823d-1a2b7a5932e8" />

<br>
<br>

- 각 파드 인스턴스별 전용 서비스 사용

<img width="500" height="400" alt="multi_service" src="https://github.com/user-attachments/assets/02179b69-818b-4e0a-9c6e-3487370c4da6" />

<br>
<br>

## 스테이트풀셋 이해
위의 상황에서 레플리카셋이 아닌 스테이트풀셋 리소스를 생성해서 해결  
애플리케이션의 인스턴스가 각각 안정적인 이름과 상태를 가지며 개별적으로 취급되야하는 경우 사용  
레플리카셋은 `가축(cattle)`을 관리한다면, 스테이트풀셋은 `애완동물(pet)`을 관리  

<br>

### 안정적인 네트워크 아이덴티티 제공
스테이트풀셋으로 생성된 파드는 서수 인덱스가 할당  
파드의 이름과 호스트, 안정적인 스토리지를 붙이는데 사용  

<img width="500" height="200" alt="statefulset_and_replicaset" src="https://github.com/user-attachments/assets/04773f3a-ad2f-458c-9c16-e032c566c7a0" />

<br>
<br>

### 거버닝 서비스
종종 스테이트풀 파드는 호스트를 통해 관리할 필요 존재  
거버닝 헤드리스 서비스를 생성해서 각 파드에게 실제 네트워크 아이덴티티 제공  
이 서비스를 통해 각 파드는 자체 DNS 엔트리 보유(`FQDN`을 통해 접근 가능)  

<br>

### 파드 교체
레플리카셋과 비슷하지만 교체된 파드는 사라진 파드와 동일한 이름과 호스트 보유  

<img width="600" height="550" alt="statefulset_replication" src="https://github.com/user-attachments/assets/2c9efaab-47c1-4dcf-a6f7-748c9d750388" />

<br>
<br>

### 스케일링
스케일링시 사용하지 않는 다음 서수 인덱스를 갖는 새로운 파드 인스턴스 생성  
스케일 다운을 하는 경우 어떤 인스턴스가 삭제될지 예상 가능  
스케일 업하는 경우 두개 이상의 API 오브젝트 생성(파드와 퍼시스턴트볼륨클레임)  
스케일 다운하는 경우 바인딩된 퍼시스턴트볼륨클레임은 그대로 보존  

<img width="600" height="200" alt="scale_down" src="https://github.com/user-attachments/assets/c93c8f7b-f406-4993-ac7b-d014ab8d3f3d" />

<br>
<br>

### 각 스테이트풀 인스턴스에 전용 스토리지 제공
스테이트풀셋의 각 파드는 별도의 퍼시스턴트볼륨을 갖는 다른 퍼시스턴트볼륨클레임을 참조  

<img width="550" height="250" alt="statefulset_and_pvc" src="https://github.com/user-attachments/assets/78a5a603-68c7-4ca9-8c52-599622a99ba0" />

<br>
<br>

### 동일 파드의 새 인스턴스에 퍼시스턴트볼륨클레임 재활용
스케일 다운을 하더라도 스케일 업으로 다시 되돌리기 가능(퍼시스턴트볼륨클레임 재활용)  

<img width="550" height="400" alt="pvc_recycling" src="https://github.com/user-attachments/assets/7615205b-cb7c-4f14-86fe-26b875731507" />

<br>
<br>

## 스테이트풀셋 생성
스테이트풀셋 매니페스트는 레플리카셋과 디플로이먼트 매니페스트와 크게 다르지 않음  
다만 `volumeClaimTemplates`에 각 파드를 위한 퍼시스턴트볼륨클레임을 생성하는데 사용되는 `data` 정의  


```yaml
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: kubia
spec:
  serviceName: kubia
  replicas: 2
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia-pet
        ports:
        - name: http
          containerPort: 8080
        volumeMounts:
        - name: data
          mountPath: /var/data
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    resources:
      requests:
      storage: 1Mi
    accessModes:
    - ReadWriteOnce
```

<br>


스테이트풀셋은 하나의 파드부터 생성하고 준비가 완료된 후 다음 파드 생성  
레이스 컨디션 방지를 위한 동작  

```
$ kubectl create -f kubia-statefulset.yaml
statefulset "kubia" created

$ kubectl get pods
NAME     READY  STATUS             RESTARTS  AGE
kubia-0  0/1    ContainerCreating  0         1s

$ kubectl get pods
NAME     READY  STATUS             RESTARTS  AGE
kubia-0  1/1    Running            0         8s
kubia-1  0/1    ContainerCreating  0         2s

$ kubectl get pvc
NAME          STATUS  VOLUME  CAPACITY  ACCESSMODES  AGE
data-kubia-0  Bound   pv-c    0                      37s
data-kubia-1  Bound   pv-c    0                      37s
```

<br>

파드가 종료되고 새로운 파드로 교체되었을때 어느 노드에나 스케줄링 가능  
하지만 동일한 아이덴티티(이름, 호스트 이름, 스토리지)를 보유  

<img width="600" height="300" alt="statefulset_and_node" src="https://github.com/user-attachments/assets/61df2ba3-bbcc-46b7-a3b0-ffc0e7fd9156" />

<br>

## 피어 디스커버리
스테이트풀셋의 각 멤버는 모든 다른 멤버를 쉽게 찾을 수 있어야함  
API 서버와 통신해서 찾을 수 있지만 그것은 바람직하지 않음  
DNS의 A, CNAME, MX 레코드가 아닌 SRV 레코드를 사용해서 탐색  

<br>

### SRV 레코드
특정 서비스를 제공하는 서버의 호스트 이름과 포트를 가리키는데 사용  

<br>

```
$ kubectl run -it srvlookup --image=tutum/dnsutils --rm --restart=Never -- dig SRV kubia.default.svc.cluster.local
```

일회용 파드(`--restart=Never`)를 실행하고 콘솔에 연결되며(`-it`) 종료되자마자 바로 삭제(`--rm`)  
파드는 tutum/dnsutils 이미지의 단일 컨테이너를 실행하고 명령(`dig SRV ...`) 수행  

<br>

```
...
;; ANSWER SECTION:
kubia.default.svc.cluster.local  30 IN SRV    10 33 0 kubia-0.kubia.default....
kubia.default.svc.cluster.local  30 IN SRV    10 33 0 kubia-1.kubia.default....
;; ADDITIONAL SECTION:
kubia-0.kubia.default.svc.cluster.local.  30 IN A 172.17.0.4
kubia-1.kubia.default.svc.cluster.local.  30 IN A 172.17.0.6
...
```

`ANSWER SECTION`에는 헤드리스 서비스를 뒷바침하는 두개의 파드를 가리키는 두개의 SRV 레코드  
`ADDITIONAL SECTION`에는 자체 A 레코드  
파드가 스테이트풀셋의 다른 모든 파드의 목록을 가져오려면 SRV DNS 룩업을 수행  

<br>

## 스테이트풀셋 노드 실패 처리
노드 실패시 단지 노드의 상태를 쿠버네티스에 보고하는 것을 중지한 kubelet이 있다는 것만 확인 가능  
스테이트풀셋은 노드가 실패한 경우 동일한 아이덴티티와 스토리지를 가진 두개의 파드가 절대 실행되지 않음을 보장  

<br>

### 노드 네트워크 연결 해제 시뮬레이션
노드 네트워크 어댑터를 셧다운하고 확인

```
$ kubectl get node
NAME                                  STATUS    AGE  VERSION
gke-kubia-default-pool-32a2cac8-596v  Ready     16m  v1.6.2
gke-kubia-default-pool-32a2cac8-m0g1  NotReady  16m  v1.6.2
gke-kubia-default-pool-32a2cac8-sgl7  Ready     16m  v1.6.2

$ kubectl get pod
NAME     READY  STATUS    RESTARTS  AGE
kubia-0  1/1    Unknown   0         15m
kubia-1  1/1    Running   0         14m
kubia-2  1/1    Running   0         13m
```

<br>

노드가 다시 온라인 상태로 돌아와 파드 상태를 보고하면 파드는 정상으로 동작  
하지만 일정 시간 Unknown 상태인 파드는 자동으로 노드에서 제거, 마스터가 이 동작을 수행  

```
$ kubectl describe pod kubia-0
Name:      kubia-0
Namespace: default
Node:      gke-kubia-default-pool-32a2cac8-m0g1/10.132.0.2
...
Status:    Terminating (expires Tue, 23 May 2017 15:06:09 +0200)
Reason:    NodeLost
Message:   Node gke-kubia-default-pool-32a2cac8-m0g1 which was
running pod kubia-0 is unresponsive
```

<br>

### 파드 강제 삭제
kubelet이 파드가 더 이상 실행중이지 않음을 확인해주는 것을 기다리지 않고 API 서버에게 파드 삭제를 알리는 것  
노드가 더 이상 실행중이 아니거나 연결 불가함을 아는 경우가 아니라면 절대 금지(영구적으로 이렇게 유지)

```
$ kubectl delete pod kubia-0 --force --grace-period 0
warning: Immediate deletion does not wait for confirmation that the running
    resource has been terminated. The resource may continue to run on the
    cluster indefinitely.
pod "kubia-0" deleted

$ kubectl get pods
NAME     READY  STATUS              RESTARTS  AGE
kubia-0  1/1    ContainerCreating   0         15m
kubia-1  1/1    Running             0         14m
kubia-2  1/1    Running             0         13m
```

<br>
