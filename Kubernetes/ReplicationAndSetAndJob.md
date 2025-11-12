# 레플리케이션
파드를 수동으로 생성, 감독, 관리하는 것은 실환경에서는 사용하지 않음  
대신 레플리케이션컨트롤러 또는 디플로이먼트와 같은 유형의 리소스를 생성해서 관리  

<br>

## 파드 유지
파드가 노드에 스케줄링되는 즉시, 해당 노드의 `Kubelet`은 파드의 컨테이너를 실행  
컨테이너의 주 프로세스에 크래시가 발생하면 컨테이너를 다시 시작  
만약 크래시가 아닌 무한 루프, 교착 상태에 빠져서 응답을 하지 않는 경우라면 외부에서 상태 체크 필수  

<br>

### 라이브니스 프로브
라이브니스 프로브(`liveness probe`)를 통해 컨테이너가 살아있는지 확인 가능  
파드의 스펙에 각 컨테이너의 라이브니스 프로브를 지정 가능하며, 주기적으로 프로브를 실행해서 체크  
- `HTTP GET Probe`: 지정한 ip 주소, 포트, 경로에 http get 요청 시도
- `TCP Socket Probe`: 지정된 포트에 tcp 연결 시도
- `Exec Probe`: 임의의 명령을 실행하고 명령의 종료 상태 코드 확인

<br>

### HTTP 라이브니스 프로브
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
spec:
  containers:
  - image: luksa/kubia-unhealthy
    name: kubia
    # http 라이브니스 프로브
    livenessProbe:
    httpGet:
      path: /
      port: 8080
    # 첫번째 프로브 실행까지 대기시간
    initialDelaySeconds: 15
```

<br>

## 레플리케이션컨트롤러
파드가 항상 실행되도록 보장  
노드가 사라지거나 노드에서 파드가 제거된 경우 사라진 파드를 감지해 교체 파드를 생성  

<img width="550" height="450" alt="replication_controller" src="https://github.com/user-attachments/assets/b4cb7c99-fe1d-4531-87da-af46d7077cb8" />

<br>
<br>

### 레플리케이션컨트롤러 동작
실행중인 파드 목록을 지속적으로 모니터링, 특정 레이블의 실제 파드 수가 의도하는 수와 같은지 확인  
이런 파드가 너무 적은 경우 새 복제복을 생성하고 많은 경우 초과 복제본 제거  

<img width="550" height="350" alt="replication_controller_loop" src="https://github.com/user-attachments/assets/7196362a-ee62-478e-83ec-b1db6b8be036" />

<br>
<br>

### 레플리케이션컨트롤러 요소
- 레이블 셀렉터(`label selector`): 레플리케이션컨트롤러 범위에 있는 파드 결정
- 레플리카수(`replica count`): 실행할 파드의 의도하는 수 지정
- 파드 템플릿(`pod template`): 새로운 파드 레플리카를 생성할때 사용

레이블 셀렉터와 파드 템플릿을 변경해도 기존 파드에는 영향을 미치지 않음  
레이블 셀렉터를 변경한 경우 기존 파드는 레플리케이션컨트롤러의 범위를 벗어나기 때문에 해당 파드 관리 중지  
파드 템플릿은 새 파드를 만들기 위한 쿠키 커터(`cookie cutter`)이기 때문에 영향 없음  

<br>

### 레플리케이션컨트롤러 생성
파드 셀렉터를 지정하지 않으면, 자동으로 파드 템플릿에서 레이블을 추출

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  # 의도하는 파드 수
  replicas: 3
  # 파드 셀렉터
  selector:
    app: kubia
# 새 파드에 적용할 파드 템플릿
template:
  metadata:
    # 파드 셀렉터 설정과 완전히 일치
    labels:
      app: kubia
  spec:
    containers:
    - name: kubia
      image: luksa/kubia
      ports:
      - containerPort: 8080
```

<br>

```
$ kubectl get pods
NAME          READY  STATUS    RESTARTS  AGE
kubia-53thy   1/1    Running   0         5s
kubia-k0xz6   1/1    Running   0         5s
kubia-q3vkg   1/1    Running   0         5s

$ kubectl delete pod kubia-53thy
pod "kubia-53thy" deleted

$ kubectl get pods
NAME          READY  STATUS             RESTARTS  AGE
kubia-53thy   1/1    Terminating        0         3m
kubia-oini2   0/1    ContainerCreating  0         2s
kubia-k0xz6   1/1    Running            0         3m
kubia-q3vkg   1/1    Running            0         3m

$ kubectl get rc
NAME    DESIRED  CURRENT  READY  AGE
kubia   3        3        2      3m
```

<br>

### 레플리케이션컨트롤러가 관리하는 파드에 레이블 추가

```
$ kubectl label pod kubia-dmdck type=special
pod "kubia-dmdck" labeled

$ kubectl get pods --show-labels
NAME          READY  STATUS    RESTARTS  AGE  LABELS
kubia-oini2   1/1    Running   0         11m  app=kubia
kubia-k0xz6   1/1    Running   0         11m  app=kubia
kubia-dmdck   1/1    Running   0         1m   app=kubia,type=special

$ kubectl label pod kubia-dmdck app=foo --overwrite
pod "kubia-dmdck" labeled

$ kubectl get pods -L app
NAME          READY  STATUS              RESTARTS  AGE  APP
kubia-2qneh   0/1    ContainerCreating   0         2s   kubia
kubia-oini2   1/1    Running             0         20m  kubia
kubia-k0xz6   1/1    Running             0         20m  kubia
kubia-dmdck   1/1    Running             0         10m  foo
```

<br>

### 파드 템플릿 변경
쿠키 커터와 유사하기 때문에 이후에 잘라낼 쿠키에만 영향  

<img width="600" height="250" alt="pod_template" src="https://github.com/user-attachments/assets/932dd214-56fc-402a-8a15-20ebc3947fb2" />

<br>
<br>

### 수평 파드 스케일링

```
$ kubectl scale rc kubia --replicas=10
```

<br>

### 레플리케이션컨트롤러 삭제
`kubectl delete`를 통해 레플리케이션컨트롤러를 삭제하는 경우 파드도 삭제  
레플리케이션컨트롤러만 삭제하려면 `--cascade=false` 옵션 필수  

```
$ kubectl delete rc kubia --cascade=false
replicationcontroller "kubia" deleted
```

<br>

## 레플리카셋
차세대 레플리케이션컨트롤러이며, 완전히 대체  
레플리카셋은 레플리케이션컨트롤러와 똑같이 동작하지만, 풍부한 표현식을 사용하는 파드 셀렉터를 보유  
특정 레이블이 없는 파드나 레이블의 값과 상관없이 특정 레이블의 키를 갖는 파드 매칭 가능  

<br>

### 레플리카셋 정의

```yaml
# 레플리카셋은 v1 api에 속하지 않음
apiVersion: apps/v1beta2
kind: ReplicaSet
metadata:
  name: kubia
spec:
  replicas: 3
  # 셀렉터가 상이
  selector:
    matchLabels:
      app: kubia
  template:
    metadata:
      labels:
        app: kubia
    spec:
      containers:
      - name: kubia
        image: luksa/kubia
```

<br>

```
$ kubectl get rs
NAME    DESIRED  CURRENT  READY  AGE
kubia   3        3        3      3s
```

<br>

### 표현적인 레이블 셀렉터
- `In`: 레이블 값이 지정된 값 중 하나와 일치
- `NotIn`: 레이블 값이 지정된 값과 불일치
- `Exists`: 지정된 키를 가진 레이블이 포함, 해당 연산자는 값 필드를 지정하지 않아야함
- `DoesNotExist`: 지정된 키를 가진 레이블이 미포함, 해당 연산자는 값 필드를 지정하지 않아야함

```yaml
# 파드의 키가 app이고 값이 kubia
selector:
  matchExpressions:
    - key: app
      operator: In
      values:
        - kubia
```

<br>

## 데몬셋
레플리케이션컨트롤러와 레플리카셋은 쿠버네티스 클러스터 내 어딘가에 지정된 수만큼 파드를 실행  
노드 당 하나의 파드를 실행하는 경우(시스템 수준 작업, 사이드카 파드) 데몬셋 사용  
생성되는 파드는 타깃 노드가 이미 지정되어 있어서 스케줄러 스킵  
노드 다운시 새 파드 인스턴스를 생성하지 않음  

<img width="550" height="400" alt="daemonset" src="https://github.com/user-attachments/assets/21c5d19d-3946-4948-9751-0dd07d69cb1c" />

<br>
<br>

### 특정 노드에서만 파드 실행
데몬셋 정의의 일부인 파드 템플릿에서 `node-Selector` 속성을 지정하면 특정 노드에서만 실행 가능  

<img width="550" height="300" alt="daemonset_node_selector" src="https://github.com/user-attachments/assets/37916333-1ff1-40e2-836c-c27340f97e4e" />

<br>
<br>

```yaml
apiVersion: apps/v1beta2
kind: DaemonSet
metadata:
  name: ssd-monitor
spec:
  selector:
    metchLabels:
      app: ssd-monitor
  template:
    metadata:
      labels:
        app: ssd-monitor
    spec:
      # 파드 템플릿 내의 노드 셀렉터 설정
      nodeSelector:
        disk: ssd
      containers:
      - name: main
        image: luksa/ssd-monitor
```

<br>

```
$ kubectl create -f ssd-monitor-daemonset.yaml
daemonset "ssd-monitor" created

$ kubectl get ds
NAME         DESIRED  CURRENT  READY  UP-TO-DATE  AVAILABLE  NODE-SELECTOR
ssd-monitor  0        0        0      0           0          disk=ssd

$ kubectl get node
NAME      STATUS  AGE  VERSION
minikube  Ready   4d   v1.6.0

$ kubectl label node minikube disk=ssd
node "minikube" labeled

$ kubectl get pods
NAME               READY  STATUS   RESTARTS  AGE
ssd-monitor-hgxwq  1/1    Running  0         35s
```

<br>

## 완료 가능한 단일 태스크 파드
레플리케이션컨트롤러, 레플리카셋, 데몬셋은 지속적인 태스크를 실행  
잡(`job`) 리소스로 해당 기능 지원  
노드 장애 발생시 해당 노드에 있던 잡이 관리하는 파드는 다른 노드로 스케줄링  
파드 스펙에 `activeDeadlineSeconds` 속성을 설정하면 도무지 완료되지 않는 경우에 잡 실패로 표시하고 종료  

<img width="550" height="350" alt="job" src="https://github.com/user-attachments/assets/91c090b0-3769-4840-a0c5-c149e9bf5870" />

<br>
<br>

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  # 파드 셀렉터를 지정하지 않음
  name: batch-job
spec:
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      # 잡은 기본 재시작 정책(Always) 사용 불가
      restartPolicy: OnFailure
      containers:
      - name: main
        image: luksa/batch-job
```

<br>

```
$ kubectl get jobs
NAME       DESIRED  SUCCESSFUL  AGE
batch-job  1        0           2s

$ kubectl get pods
NAME             READY  STATUS   RESTARTS  AGE
batch-job-28qf4  1/1    Running  0         4s
```

<br>

- 단일 태스크 완료 후 파드는 삭제되지 않고 종료

```
$ kubectl get pods -a
NAME             READY  STATUS     RESTARTS  AGE
batch-job-28qf4  0/1    Completed  0         2m

$ kubectl logs batch-job-28qf4
Fri Apr 29 09:58:22 UTC 2016 Batch job starting
Fri Apr 29 10:00:22 UTC 2016 Finished successfully

$ kubectl get jobs
NAME       DESIRED  SUCCESSFUL  AGE
batch-job  1        1           9m
```

<br>

- 여러 파드 인스턴스 실행

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  # 설정된 갯수의 파드를 순차적으로 실행
  completions: 5
  template:
    <template is the same as in listing 4.11>
```

<br>

- 병렬로 잡 파드 실행

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: multi-completion-batch-job
spec:
  completions: 5
  # 병렬 실행 설정
  parallelism: 2
  template:
    <same as in listing 4.11>
```

<br>

- 잡 실행 중에 `parallelism` 속성 변경 가능(잡 스케일링)

```
$ kubectl scale job multi-completion-batch-job --replicas 3
job "multi-completion-batch-job" scaled
```

<br>

## 주기적인 잡
리눅스나 유닉스의 크론 작업을 지원  
크론잡(`cron job`) 리소스를 만들어서 잡 실행을 위한 스케줄을 크론 형식으로 지정  

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: batch-job-every-fifteen-minutes
spec:
  schedule: "0,15,30,45 * * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: preiodic-batch-job
        spec:
          restartPolicy: OnFailure
          containers:
          - name: main
            image: luksa/batch-job
```




























