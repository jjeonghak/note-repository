# 디플로이먼트
쿠버네티스 클러스터에서 실행디는 애플리케이션을 무중단 업데이트하는 방법  
해당 작업은 레플리카셋으로 사용 가능하나 레플리카셋 기능을 활용하는 디플로이먼트 리소스를 제공  

<br>

## 파드에서 실행 중인 애플리케이션 업데이트
- 기존 파드를 모두 삭제한 후 새 파드를 시작
- 새로운 파드를 먼저 시작하고 기존 파드 삭제

<br>

### 기존 파드 삭제 후 새 파드로 교체
레플리케이션컨트롤러는 새 인스턴스를 생성할때 업데이트된 파드 템플릿을 사용  
기존 파드가 삭제되고 업데이트되는 동안 짧은 시간의 다운 타임 발생  

<img width="600" height="350" alt="update_pod_v1" src="https://github.com/user-attachments/assets/2c041361-75c7-44d9-afb5-254f27a9f8e4" />

<br>
<br>

### 새 파드 가동 후 기존 파드 삭제
짧은 시간 동안 두배의 파드가 생성  
- 블루 그린 배포
- 롤링 업데이트

<br>

<img width="600" height="300" alt="blue_green" src="https://github.com/user-attachments/assets/2898f9fc-b059-40dc-b5ec-f32cb9e7653d" />

<br>
<br>

<img width="600" height="300" alt="rolling" src="https://github.com/user-attachments/assets/d73b8bd6-0b97-45b8-9c1a-078b18b35be7" />

<br>
<br>

## 레플리케이션컨트롤러 자동 업데이트
수동이 아닌 자동으로 `kubectl`을 사용해서 업데이트 가능  
하지만 이제는 사용하지 않는 오래된 업데이트 방식  
업데이트 주체가 서버가 아닌 `kubectl` 클라이언트이기 때문에 네트워크 이슈가 발생하면 중간 단계에서도 배포 중단 발생 가능  

<img width="550" height="200" alt="replicationcontroller_rolling" src="https://github.com/user-attachments/assets/6b550141-ca9a-4869-b7ce-09be958d953e" />

<br>
<br>

```
$ kubectl rolling-update kubia-v1 kubia-v2 --image=luksa/kubia:v2
Create kubia-2
Scaling up kubia-v2 from 0 to 3, scaling down kubia-v1 from 3 to 0 (keep 3
    pods available, don't exceed 4 pods)
...
```

<br>

기존 레플리케이션컨트롤러를 복사하고 해당 파드 템플릿에서 이미지를 변경해 새 레플리케이션컨트롤러 생성  
하지만 레이블 셀렉터가 기존 파드 레이블과 새 파드 레이블을 구분 못하기 때문에 기존 레플리케이션컨트롤러의 셀렉터도 수정  

<img width="600" height="250" alt="replicationcontroller_rolling_labels" src="https://github.com/user-attachments/assets/090c6a83-325c-4ede-b971-f4c7044432fa" />

<br>
<br>

## 선언적 업데이트를 위한 디플로이먼트
레플리케이션컨트롤러 또는 레플리카셋 대신 애플리케이션을 배포하고 선언적 업데이트를 하기 위한 높은 수준의 리소스  
디플로이먼트 생성시 레플리카셋 리소스가 그 아래 생성  
디플로이먼트로 생성된 레플리카셋과 파드 이름 중간에는 해시값이 포함(디플로이먼트와 파드 템플릿 해시값)  

<img width="400" height="100" alt="deployment" src="https://github.com/user-attachments/assets/be8e702e-f93d-4be7-94ff-8044a51e705f" />

<br>
<br>

### 디플로이먼트 생성

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  # 애플리케이션의 여러 버전을 관리하기 때문에 버전 정보는 없이
  name: kubia
spec:
  replicas: 3
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v1
        name: nodejs
```

<br>

```
$ kubectl create -f kubia-deployment-v1.yaml --record
deployment "kubia" created

$ kubectl rollout status deployment kubia
deployment kubia successfully rolled out

$ kubectl get pods
NAME                    READY  STATUS   RESTARTS  AGE
kubia-1506449474-otnnh  1/1    Running  0         14s
kubia-1506449474-vmn7s  1/1    Running  0         14s
kubia-1506449474-xis6m  1/1    Running  0         14s

$ kubectl get replicasets
NAME              DESIRED  CURRENT  AGE
kubia-1506449474  3        3        10s
```

<br>

### 디플로이먼트 업데이트
디플로이먼트 리소스에 정의된 파드 템플릿을 수정하면 업데이트 완료  
내부적으로 알아서 관리  
기본적으로 `RollingUpdate` 전략을 사용하고 대안으로 `Recreate` 전략 존재  
`Recreate` 전략을 사용하는 경우 새 파드를 만들기 전에 기존 파드를 모두 삭제  

<img width="550" height="250" alt="deployment_pod_template_update" src="https://github.com/user-attachments/assets/6c44defe-2ede-4d47-a050-1d00791f1fd0" />

<br>
<br>

<img width="600" height="200" alt="deployment_rolling_update" src="https://github.com/user-attachments/assets/b4828878-6e6c-472a-af01-78d5c061eff0" />

<br>
<br>

```
$ kubectl set image deployment kubia nodejs=luksa/kubia:v2
deployment "kubia" image updated
```

<br>

### 디플로이먼트 롤백
디플로이먼트는 개정 이력(`revision history`)을 유지하므로 롤백이 가능  
이력은 기본 레플리카셋에 저장  
개정 내역의 수는 디플로이먼트 리소스의 `editionHistoryLimit` 속성에 의해 제한(기본값 2)  

```
$ kubectl rollout undo deployment kubia
deployment "kubia" rolled back
```

<br>

```
$ kubectl rollout history deployment kubia
deployments "kubia":
REVISION  CHANGE-CAUSE
2         kubectl set image deployment kubia nodejs=luksa/kubia:v2
3         kubectl set image deployment kubia nodejs=luksa/kubia:v3
```

<br>

특정 디플로이먼트 개정으로 롤백도 가능  

```
$ kubetl rollout undo deployment kubia --to-revision=1
```

<img width="500" height="200" alt="deployment_undo_rollout" src="https://github.com/user-attachments/assets/e202b122-5063-4d2e-ac30-ec03fe7711aa" />

<br>

### 롤아웃 속도 제어
`maxSurge`와 `maxUnavailable` 속성으로 한번에 몇 개의 파드를 교체할지 결정  

```yaml
spec:
  strategy:
    rolloingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
```

<br>

- `maxSurge`: 디플로이먼트가 의도하는 레플리카 수보다 얼마나 많은 파드 인스턴스 수를 허용하는지 결정
- `maxUnavailable`: 업데이트 중에 의도하는 레플리카 수를 기준으로 사용할 수 없는 파드 인스턴스 수를 결정

<br>

<img width="600" height="350" alt="maxsurge_and_maxunavailable" src="https://github.com/user-attachments/assets/6bffb866-6217-4c56-9a9f-d3691c79ea8b" />

<br>
<br>

<img width="500" height="350" alt="maxsurge_and_maxunavailable2" src="https://github.com/user-attachments/assets/5d87292a-f02c-4297-8828-5f4f9fb1ab22" />

<br>
<br>

### 잘못된 버전의 롤아웃 방지
`minReadySeconds` 속성은 롤아웃 속도를 늦춤  
모든 파드를 한번에 교체하지 않고 오작동 버전의 배포를 방지  
파드를 사용 가능한 것으로 취급하기 전에 새로 만든 파드를 준비할 시간을 지정  

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 3
  minReadySeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
      - image: luksa/kubia:v3
        name: nodejs
        readinessProbe:
          periodSeconds: 1
            httpGet:
              path: /
              port: 8080
```

<br>
