# 파드
배치된 컨테이너 그룹이며 쿠버네티스 기본 빌딩 블록  
컨테이너를 개별적으로 배포하기보다는 컨테이너를 가진 파드를 배포하고 운영  
파드는 기본적으로 하나의 컨테이너만을 포함하지만, 여러 컨테이너를 가진 경우 꼭 하나의 워커 노드에서만 실행  

<img width="600" height="300" alt="pod" src="https://github.com/user-attachments/assets/d13ff528-7dc9-4ace-9bd0-b5758c5a514f" />

<br>
<br>

### 파드 필요성
`IPC(Inter-Process Communication)` 혹은 로컬 파일을 통해 통신하는 여러 프로세스로 구성  
여러 프로세스를 실행하는 단일 컨테이너는 여러 입출력에 대해 프로세스 분리하는 또 다른 매커니즘 필요  
또한 컨테이너를 함께 묶고 하나의 단위로 관리할 수 있는 또 다른 상위 구조가 필요  

<br>

### 같은 파드에서 컨테이너 간 부분 격리
그룹 안에 있는 컨테이너가 특정 리소스를 공유하기 위해 완벽하게 격리되지 않도록 구현  
파드 안에 있는 모든 컨테이너가 자체 네임스페이스가 아닌 동일한 리눅스 네임스페이스를 공유하도록 도커를 설정  
파드 안의 컨테이너가 동일한 `네트워크 네임스페이스`에서 실행되기 때문에 동일한 `ip 주소`와 `포트 공간`을 공유  

<br>

### 파드 간 플랫 네트워크
모든 파드는 하나의 플랫한 공유 네트워크 주소 공간에 상주  
모든 파드는 다른 파드의 ip 주소를 사용해 접근 가능  
둘 사이에 어떠한 `nat`도 존재하지 않지만 패킷을 보내면 상대방의 실제 ip 주소를 확인 가능  

<img width="600" height="300" alt="flat_network" src="https://github.com/user-attachments/assets/9b8f35cd-9677-44a1-9dac-39428df3a0dd" />

<br>
<br>

결과적으로 파드 사이에 통신은 단순하게 가능  
두 파드가 동일 혹은 서로 다른 워커 노드에 있는지는 중요하지 않음  
근거리 네트워크 `LAN` 통신과 유사한 통신  

<br>

### 파드 컨테이너 구성
한 호스트에 모든 유형의 애플리케이션을 넣었던 이전과 달리 특정한 애플리케이션만을 호스팅  
다계층 애플리케이션의 경우 프론트, 백엔드, 데이터베이스 컨테이너를 단일 파드보단 여러 파드로 분할하는 것 권장  
파드는 스케일링의 기본 단위이기 때문에 개별 확장을 위해서라도 분리  

<br>

### 파드에서 여러 컨테이너를 사용하는 이유
애플리케이션이 하나의 주요 프로세스와 하나 이상의 보완 프로세스로 구성된 경우  
보통 `사이드카` 컨테이너로 로그 로테이터, 수집기, 데이터 프로세서, 통신 어댑터 등 존재  

<img width="300" height="300" alt="sidecar" src="https://github.com/user-attachments/assets/2bafaecf-5d62-4a57-9916-4f752ae0b64d" />

<br>
<br>

### 파드 안 여러 컨테이너 결정
- 컨테이너를 꼭 함께 실행해야 하는가, 혹은 서로 다른 호스트에서 실행 가능한가?
- 여러 컨테이너가 모여 하나의 구성 요소를 나타내는가?
- 컨테이너가 함께 스케일링돼야 하는가?

<img width="600" height="400" alt="pod_and_container" src="https://github.com/user-attachments/assets/eea4d35f-0b20-4421-a52c-a3e31babaf17" />

<br>
<br>

## YAML 또는 JSON 디스크립터로 파드 생성
파드를 포함한 다른 쿠버네티스 리소스는 일반적으로 쿠버네티스 REST API 엔드포인트에 매니페스트 전송  
`kubectl run` 명령처럼 간단하게 가능하지만 제한된 속성 집합만 설정 가능  
또한 yaml, json 파일로 관리한 경우 쿠버네티스 오브젝트 버전 관리 가능  

<br>

### 디스크립터 예제

```
$ kubectl get pod kubia-zxzij -o yaml
```

```yaml
# 디스크립터에서 사용한 쿠버네티스 api 버전
apiVersion: v1
# 쿠버네티스 오브젝트(리소스) 유형
kind: Pod
# 리소스 메타데이터(이름, 레이블, 어노테이션 등)
metadata:
  annotations:
    kubernetes.io/created-by: ...
  creationTimestamp: 2016-03-18T12:37:50Z
  generateName: kubia-
  labels:
    run: kubia
  name: kunia-zxzij
  namespace: default
  resourceVersion: "294"
  selfLink: /api/v1/namespaces/default/pods/kubia-zxzij
  uid: 3a56dc0-ed06-11e5-ba3b-42010af00004
# 리소스 정의
spec:
  containers:
    - image: luksa/kubia
      imagePullPolicy: IfNotPresent
      name: kubia
      ports:
      - containerPort: 8080
        protocol: TCP
      resources:
        requests:
          cpu: 100m
        terminationMessagePath: /dev/termination-log
        volumeMounts:
        - mountPath: /var/run/secrets/k8s.io/servacc
          name: default-token-kvcqa
          readonly: true
  dnsPolicy: ClusterFirst
  nodeName: gke-kubia-e8fe08b8-node-txje
  restartPolicy: Always
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  volumes:
  - name: default-token-kvcqa
    secret:
      secretName: default-token-kvcqa
# 상세 상태
status:
  conditions:
    - lastProbeTime: null
      lastTransitionTime: null
      status: "True"
      type: Ready
  containerStatuses:
  - containerID: docker://f0276994322d247ba...
    image: luksa/kubia
    imageID: docker://4c325bcc6b40c110226b89fe...
    lastState: {}
    name: kubia
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: 2016-03-18T12:46:05Z
  hostIP: 10.132.0.4
  phase: Running
  podIP: 10.0.2.3
  startTime: 2016-03-18T12:44:32Z
```

<br>

- `metadata`: 이름, 네임스페이스, 레이블 및 파드에 관한 기타 정보를 포함
- `spec`: 파드 컨테이너, 볼륨, 기타 데이터 등 파드 자체에 관한 실제 명세
- `status`: 파드 상태, 각 컨테이너 설명과 상태, 파드 내부 ip, 기타 기본 정보 등 현재 실행 중인 파드 정보

<br>

### 컨테이너 포트 지정
포트 정의 안에서 포트를 지정한 것은 단지 정보에 불과  
컨테이너가 `0.0.0.0` 주소에 열어 둔 포트를 통해 접속 허용한 경우 다른 파드에서 항상 해당 파드에 접속 가능  

<br>

### kubectl 명령

- 매니페스트 작성시 속성 설명 조회

```
$ kubectl explain pods
DESCRIPTION
Pod is a collection of containers that can run on a host. This resource
            is created by clients and scheduled onto hosts.
FIELDS:
  kind      <string>
  metadata  <Object>
  spec      <Object>
  status    <Object>

$kubectl explain pod.spec
REDOURCE: spec <Object>
DESCRIPTION:
    Specification of the desired behavior of the pod...
    podSpec is a description of a pod.
FIELD:
  hostPID      <boolean>
  volumes      <[]Object>
  Containers   <[]Object> -required-
```

<br>

- pod 생성 및  조회

```
$ kubectl create -f kubia-manual.yaml
pod "kubia-manual" created

$ kubectl get pod kubia-manual -o json

$ kubectl get pods
NAME           READY  STATUS    RESTARTS  AGE
kubia-manual   1/1    Running   0         32s
kubia-zxzij    1/1    Running   0         1d
```

<br>

- 컨테이너 로그 조회

```
// 로그는 하루 단위로, 로그 파일이 10MB 크기에 도달할 때마다 순환
$ kubectl logs kubia-manual
Kubia server starting...

// 특정 컨테이너 로그
$ kubectl logs kubia-manual -c kubia
Kubia server starting...
```

<br>

- 파드 요청 보내기

```
// 서비스를 거치지 않고 포트포워딩 사용
$ kubectl port-forward kubia-manual 8888:8080
... Forwarding from 127.0.0.1:8888 -> 8080
... Forwarding from [::1]:8888 -> 8080

$ curl localhost:8888
You've hit kubia-manual
```

<img width="600" height="200" alt="port_forward" src="https://github.com/user-attachments/assets/2e400d93-a6a9-40b6-88bb-0393c0f3d244" />

<br>
<br>

## 레이블을 이용한 파드 구성








