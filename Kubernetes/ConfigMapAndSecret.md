# 컨피그맵과 시크릿
쿠버네티스에서 사용하는 설정을 환경변수를 전달하는 방법  

<br>

## 컨테이너화된 애플리케이션 설정  
일반적으로 컨테이너 설정은 명령줄 인수 또는 환경변수를 활용해서 전달  
환경변수를 사용하지 않는 경우 컨테이너 이미지 안에 포함하거나 설정이 포함된 파일을 볼륨에 마운트 필요  
설정 데이터를 저장하는 쿠버네티스 리소스는 컨피그맵(`ConfigMap`)  
민감한 정보의 경우 쿠버네티스 시크릿(`Secret`) 사용  

- 컨테이너 명령줄 인수 전달
- 각 컨테이너를 위한 사용자 정의 환경변수 지정
- 특수한 유형의 볼륨(`gitRepo`)을 통해 설정 파일을 컨테이너에 마운트

<br>

### 컨테이너 명령줄 인자 전달
도커에서 전체 명령이 명령어와 인자의 두부분으로 구성  
기본적으로 `ENTRYPOINT` 명령어로 실행하고 기본 인자를 정의하려는 경우에만 `CMD` 지정  
- `ENTRYPOINT`: 컨테이너가 시작될때 호출될 명령어 정의
- `CMD`: `ENTRYPOINT`에 전달되는 인자를 정의

<br>

```
$ docker run <image>
$ docker run <image> <arguments>
```

<br>

`exec`과 `shell` 명령어는 두가지 서로 다른 형식을 지원  
차이점은 내부에서 정의된 명령을 쉘로 호출하는지 여부  
- `exec`: `ENTRYPOINT ["node", "app.js"]`
- `shell`: `ENTRYPOINT node app.js`

<br>

- `exec` 형식은 컨테이너 내부에서 프로세스를 직접 실행

```
$ docker exec 4675d ps x
PID  TTY  STAT  TIME  COMMAND
  1  ?    Ssl   0:00  node app.js
 12  ?    Rs    0:00  ps x
```

<br>

- `shell` 형식은 쉘 내부에서 실행(메인 프로세스가 쉘 프로세스)

```
$ docker exec -it e4bad ps x
PID  TTY  STAT  TIME  COMMAND
  1  ?    Ss    0:00  /bin/sh -c node app.js
  7  ?    Sl    0:00  node app.js
 13  ?    Rs+   0:00  ps x
```

<br>

### 쿠버네티스에서 명령과 인자 재정의
컨테이너를 정의할때 `command`, `args` 속성을 같이 지정  
대부분의 경우 사용자 정의 인자만 지정하고 명령을 재정의하는 경우는 거의 없음  

```yaml
kind: Pod
spec:
  containers:
  - image: some/image
    command: ["/bin/commnad"]
    args: ["arg1", "arg2", "arg3"]
```

<br>

## 컨테이너 환경변수 설정
컨테이너 명령이나 인자와 마찬가지로 환경변수 목록도 파드 생성 후에는 업데이트 불가  
파드 정의에 하드코딩된 값을 가져오는 것은 다른 환경에서 실행되는 파드 또는 컨테이너마다 분리된 정의 필요  

<img width="300" height="350" alt="container_env" src="https://github.com/user-attachments/assets/b6048e7d-091c-43e9-bd91-883f5899a6e2" />

<br>
<br>

```yaml
kind: Pod
spec:
  containers:
  - image: luska/fortune:env
    # 파드 레벨이 아닌 컨테이너 레벨의 환경변수
    env:
    - name: INTERVAL
      value: "30"
    name: html-generator
    ...
```

<br>

### 변수값에서 다른 환경변수 참조
`$(VAR)` 구문을 이용해 이미 정의된 환경변수나 기타 기존 변수 참조 가능  

```yaml
env:
- name: FIRST_VAR
  value: "foo"
- name: SECOND_VAR
  value: "$(FIRST_VAR)bar"
```

<br>

## 컨피그맵으로 설정 분리
애플리케이션 구성의 요점은 환경에 따라 변경되는 설정 옵션을 소스 코드와 별도로 유지하는 것  
파드 정의에서 하드 코딩된 환경변수를 분리하는 것이 목적  

<br>

### 컨피그맵
짮은 문자열에서 전체 설정 파일에 이르는 값을 가지는 키/값으로 구성된 맵  
맵의 내용은 컨테이너의 환경변수 또는 볼륨 파일로 전달  

<img width="400" height="300" alt="configmap_and_volume" src="https://github.com/user-attachments/assets/3974b98f-e1db-42cc-b5cd-ab99b10efe94" />

<br>
<br>

각각 다른 환경에 관해 동일한 이름으로 컨피그맵에 관한 여러 매니페스트 유지 가능  
파드는 컨피그맵을 이름으로 참조하기 때문  

<img width="550" height="350" alt="diff_env" src="https://github.com/user-attachments/assets/99a778b4-d086-4672-94b4-1387a3a001ce" />

<br>
<br>

### 컨피그맵 생성

<img width="600" height="600" alt="configmap_creation" src="https://github.com/user-attachments/assets/439c1546-12c2-4e67-9e2e-8beca7590175" />

<br>
<br>

- 일반 문자열로 생성

```
$ kubectl create configmap fortune-config --from-literal=sleep-interval=25
configmap "fortune-config" created
```

<br>

```yaml
apiVersion: v1
data:
  # 이 맵의 항목
  sleep-interval: "25"
kind: ConfigMap
metadata:
  creationTimestamp: 2016-08-11T20:31:08Z
  # 해당 이름으로 참조
  name: fortune-config
  namespace: default
  resourceVersion: "910025"
  selfLink: /api/v1/namespaces/default/configmaps/fortune-config
  uid: 88c4167e-6002-11e6-a50d-42010af00237
```

<br>

- 파일 내용으로 생성

```
$ kubectl create configmap my-config --from-file=config-file.conf
$ kubectl create configmap my-config --from-file=customkey=config-file.conf
```

<br>

- 디렉토리 파일로 생성
- 이때 해당 디렉토리 내부에 파일 이름이 컨피그맵 키로 사용하기에 유효한 파일만 추가

```
$ kubectl create configmap my-config --from-file=/path/to/dir
```

<br>

### 컨피그맵 항목을 환경변수로 컨테이너에 전달
`valueFrom` 필드를 통해 가능  

<img width="550" height="300" alt="configmap_container_connection" src="https://github.com/user-attachments/assets/15d5af6f-4fd8-4056-809d-42472f89c96e" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-env-from-configmap
spec:
  containers:
  - image: luksa/fortune:env
    env:
    - name: INTERVAL
      # 고정값을 사용하지 않고 컨피그맵 키에서 값을 가져와 초기화
      valueFrom:
        configMapKeyRef:
          # 참조하는 컨피그맵 이름
          name: fortune-config
          # 컨피그랩에서 해당 키 아래 저장된 값으로 변수 설정
          key: sleep-interval
```

<br>

### 모든 항목을 환경변수로 전달

```yaml
spec:
  containers:
  - image: some-image
  # env 대신 envFrom 사용
  envFrom:
  # 모든 환경변수는 CONFIG_ 접두사
  - prefix: CONFIG_
  configMapRef
    name: my-config-map
...
```

<br>

### 명령줄 인자로 컨피그맵 항목 전달

<img width="550" height="250" alt="configmap_args" src="https://github.com/user-attachments/assets/8bfa9024-f5b6-4af0-9f5f-ede92ff4abd0" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-args-from-configmap
spec:
  containers:
  - image: luksa/fortune:args
    # 컨피그맵 환경변수 정의
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    # 인자로 앞에서 정의한 환경변수 지정
    args: ["$(INTERVAL)"]
```

<br>

### 컨피그맵 볼륨을 이용해 컨피그맵 항목을 파일로 노출
환경변수 또는 명령줄 인자로 설정 옵션을 전달하는 것은 일반적으로 짧은 변수값에 대해서 사용  
컨피그맵은 모든 설정 파일들을 컨테이너에 노출시키기 위해 컨피그맵 볼륨을 사용  

<img width="300" height="200" alt="configmap_file" src="https://github.com/user-attachments/assets/60b34f9c-6956-4f11-b5f3-b5c0d2f83d50" />

<br>
<br>

- 값으로 사용할 nginx 설정 파일

```nginx
server {
  listen        80;
  server_name   www.kubia-example.com;

  gzip on;
  gzip_types text/plain application/xml;

  location / {
    root    /usr/share/nginx/html;
    index   index.html index.htm;
  }
}
```

<br>

```
$ kubectl create configmap fortune-config --from-file=configmap-files
configmap "fortune-config" created

$ kubectl get configmap fortune-config -o yaml
apiVersion: v1
data:
  my-nginx-config.conf: |
    server {
      listen        80;
      server_name   www.kubia-example.com;
    
      gzip on;
      gzip_types text/plain application/xml;
    
      location / {
        root    /usr/share/nginx/html;
        index   index.html index.htm;
      }
    }
  sleep-interval: |
    25
kind: ConfigMap
...
```

<br>































