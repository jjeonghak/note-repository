# DownwardAPI
애플리케이션 자신에 관한 상세 정보를 포함해 실행중인 환경 관련 정보와 클러스터 내의 다른 구성 요소 정보가 필요한 경우  

<br>

## Downward API
파드의 ip, 호스트 노드 이름, 파드 자체 이름과 같이 실행 시점까지 알려지지 않은 데이터  
파드의 레이블이나 어노테이션 같이 이미 설정된 메타데이터  
환경변수 또는 `downwardAPI` 파일로 파드와 해당 환경의 메타데이터를 전달 가능  

<br>

<img width="550" height="350" alt="downwardapi" src="https://github.com/user-attachments/assets/ec24e03d-2da2-4fc1-adaf-fc85270eb67a" />

<br>
<br>

### 사용 가능한 메타데이터
- 파드 이름
- 파드 ip 주소
- 파드가 속한 네임스페이스
- 파드가 실행중인 노드 이름
- 파드가 실행중인 서비스 어카운트 이름
- 각 컨테이너 cpu, 메모리 요청
- 각 컨테이너 cpu, 메모리 제한
- 파드 레이블
- 파드 어노테이션

<br>

<img width="600" height="400" alt="downward_metadata" src="https://github.com/user-attachments/assets/7d2f8b0d-ff65-4b55-bc11-f9fc17238ea2" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
spec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldref:
          fieldPath: spec.nodeName
    - name: SERVICE_ACCOUNT
      valueFrom:
        fieldRef:
          fieldPath: spec.serviceAccountName
    - name: CONTAINER_CPU_REQUEST_MILLICORES
      valueFrom:
        resourceFieldRef:
          resource: requests.cpu
          divisor: 1m
    - name: CONTAINER_MEMORY_LIMIT_KIBIBYTES
      valueFrom:
        resourceFieldRef:
          resource: limits.memory
          divisor: 1Ki
```

<br>

```
$ kubectl exec downward env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=downward
CONTAINER_MEMORY_LIMIT_KIBIBYTES=4096
POD_NAME=downward
POD_NAMESPACE=default
POD_IP=10.0.0.10
NODE_NAME=gke-kubia-default-pool-32a2cac8-sgl7
SERVICE_ACCOUNT=default
CONTAINER_CPU_REQUEST_MILLICORES=15
KUBERNETES_SERVICE_HOST=10.3.240.1
KUBERNETES_SERVICE_PORT=443
...
```

<br>

### downwardAPI 볼륨에 파일로 메타데이터 전달
환경변수 대신 파일로 메타데이터를 노출하는 경우 `downwardAPI` 볼륨을 정의해 컨테이너에 마운트 가능  

<img width="550" height="450" alt="downward_in_container" src="https://github.com/user-attachments/assets/98ab44bb-e0c5-4d94-b2de-90453081c2fe" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward
  labels:
    foo: bar
  annotations:
    key1: value1
    key2: |
      multi
      line
      value
epec:
  containers:
  - name: main
    image: busybox
    command: ["sleep", "9999999"]
    resources:
      requests:
        cpu: 15m
        memory: 100Ki
      limits:
        cpu: 100m
        memory: 4Mi
    volumeMounts:
    - name: downward
      mountPath: /etc/downward
  volumes:
  - name: downward
    downwardAPI:
      itmes:
      - path: "podName"
        fieldRef:
          fieldPath: metadata.name
      - path: "podNamespace"
        fieldRef:
          fieldPath" metadata.namespace
      - path: "labels"
        fieldRef:
          fieldPath" metadata.labels
      - path: "annotations"
        fieldRef:
          fieldPath" metadata.annotations
      - path: "containerCpuRequestMilliCores"
        resourcefieldRef:
          containerName: main
          resource: request.cpu
          divisor: 1m
      - path: "containerMemoryLimitBytes"
        resourcefieldRef:
          containerName: main
          resource: limits.memory
          divisor: 1
```

<br>

```
$ kubectl exec downward -- ls -l: /etc/downward
-rw-r--r-- 1  root root  134  May 25 10:23 annotations
-rw-r--r-- 1  root root    2  May 25 10:23 containerCpuRequestMilliCores
-rw-r--r-- 1  root root    7  May 25 10:23 containerMemoryLimitBytes
-rw-r--r-- 1  root root    9  May 25 10:23 labels
-rw-r--r-- 1  root root    8  May 25 10:23 podName
-rw-r--r-- 1  root root    7  May 25 10:23 podNamespace
```

<br>

### 레이블과 어노테이션 업데이트
레이블이나 어노테이션이 변경괼 경우 가지고 있는 파일을 업데이트  
만약 환경변수로 레이블이나 어노테이션이 노출 가능하다면 해당 부분에서 문제 발생(그래서 지원안함)  

<br>
