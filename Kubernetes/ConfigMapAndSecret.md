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

### 볼륨 안에 있는 컨피그맵 항목 사용
컨피그맵 항목에서 생성된 파일로 볼륨을 초기화하고 컨테이너에 마운트하는 방식  

<img width="500" height="300" alt="configmap_volume_mount" src="https://github.com/user-attachments/assets/c0d5b953-cac5-45c5-9a07-75fb5849ad2d" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-configmap-volume
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    ...
    - name: config
      # 컨피그맵 볼륨을 마운트하는 위치
      mountPath: /etc/nginx/conf.d
      readOnly: true
    ...
  volumes:
  ...
  - name: config
    # 참조하는 컨피그맵
    configMap:
      name: fortune-config
...
```

<br>

```
$ kubectl exec fortune-configmap-volume -c web-server ls /etc/nginx/conf.d
my-nginx-config.conf
sleep-interval
```

<br>

### 볼륨에 특정 컨피그맵 항목 노출
컨피그맵 볼륨을 컨피그맵 항목의 일부로만 채울 수 있음  

```yaml
volumes:
- name: config
  configMap:
    name: fortune-config
    # 볼륨에 포함할 항목을 조회해서 선택
    items:
    - key: my-ngonx-config.conf
      path: gzip.conf
```

<br>

### 디렉토리 안에 다른 파일을 숨기지 않고 개별 컨피그맵 항목을 파일로 마운트
전체 볼륨을 마운트하는 대신 `subPath` 속성으로 파일이나 디렉토리 하나를 볼륨에 마운트 가능  

<img width="550" height="300" alt="configmap_subpath" src="https://github.com/user-attachments/assets/230da312-f2f8-4b8c-b968-146b8c899f0b" />

<br>
<br>

```yaml
spec:
  containers:
  - image: some/image
    volumeMounts:
    - name: myvolume
      # 디렉토리가 아닌 파일 마운트
      mountPath: /etc/someconfig.conf
      # 전체 볼륨을 마운트하지 않고 해당 항목만 마운트
      subPath: myconfig.conf
```

<br>

### 컨피그맵 볼륨 안에 있는 파일 권한 설정
기본적으로 컨피그맵 볼륨의 모든 파일 권한은 `644(-rw-r-r--)`로 설정  
볼륨 정의 안에 있는 `defaultMode` 속성을 설정  

```yaml
volumes:
  - name: config
    configMap:
      name: fortune-config
      # 모든 파일 권한을 -rw-rw-----로 설정
      defaultMode: "6600"
```

<br>

### 애플리케이션 재시작하지 않고 애플리케이션 설정 업데이트
환경변수 또는 명령줄 인수의 단점은 프로세스가 실행되는 동안 업데이트 불가  
컨피그맵 볼륨을 사용하면 파드를 다시 생성하거나 컨테이너 재시작 없이 업데이트 가능  
컨피그맵 업데이트시 참조 볼륨 파일이 업데이트되고 해당 변경을 감지하고 다시 로드하는 프로세스 보유  

<br>

```
$ kubectl edit configmap fortune-config

// 파일 업데이트는 되었지만 nginx에는 아무런 영향이 없음
$ kubectl exec fortune-configmap-volume -c web-server
cat /etc/nginx/conf.d/my-nginx-config.conf

kubectl exec fortune-configmap-volume -c web-server -- nginx -s reload
```

<br>

### 파일 업데이트 방식
컨피그맵 볼륨에 있는 모든 파일 업데이트는 동시에 실행  
쿠버네티스는 심볼릭 링크를 이용해서 수행  

```
$ kubectl exec -it fortune-configmap-volume -c web-server -- ls -lA
/etc/nginx/conf.d
total 4
drwxr-xr-x  ... 12:15 ..4984_09_04_12_15_06.865837643
lrwxrwxrwx  ... 12:15 ..data -> ..4984_09_04_12_15_06.865837643
lrwxrwxrwx  ... 12:15 my-nginx-config.conf -> ..data/my-nginx-config.conf
lrwxrwxrwx  ... 12:15 sleep-interval -> ..data/sleep-interval
```

<br>

컨피그맵이 업데이트되면 쿠버네티스는 이와 같은 새 디렉토리를 생성  
모든 파일을 해당 디렉토리에 작성  
이후 `..data` 심볼릭 링크가 새 디렉토리를 가리키도록 수정  

<br>

## 시크릿
컨피그맵 데이터는 보안을 유지할 필요가 없는 일반적이고 민감하지 않은 데이터  
설정 안에 보안이 유지되야하는 자격증명과 암호화 키는 시크릿 사용  
컨피그맵과 굉장히 유사  

<br>

### 기본 토큰 시크릿
모든 실행 컨테이너가 마운트해서 갖고 있는 시크릿  
시크릿이 갖고 있는 세가지 항목(`ca.cert`, `namespace`, `token`)은 모두 파드 안에서 쿠버네티스 API 서버와 통신할때 필요한 것  

<img width="500" height="250" alt="default_secret" src="https://github.com/user-attachments/assets/a23d3b0c-b7a0-4e93-9bf2-798c39b5cc50" />

<br>
<br>

```
$ kubectl describe pod kubia
...
Volumes:
  default-token-cfee9:
    Type:       Secret (a volume populated by a Secret)
    SecretName: default-token-cfee9
Mounts:
  /var/run/secrets/kubernetes.io/serviceaccount from default-token-cfee9
...

$ kubectl get secrets
NAME                 TYPE                                 DATA  AGE
default-token-cfee9  kubernetes.io/service-account-token  3     39d

$ kubectl describe secrets
Name:         default-token-cfee9
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=default
              kubernetes.io/service-account.uid=cc04bb39-b53f-42010af00237
Type:         kubernetes.io/service-account-token
Data
===
ca.crt:       1139 bytes
namespace:    7 bytes
token:        eyJhbGci0iJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

<br>

### 시크릿 생성
컨피그맵을 작성하는 것과 크게 다르지 않음  

```
$ kubectl create generic fortune-https --from-file=https.key --from-file=https.cert --from-file=foo
secret "fortune-https" created
```

<br>

- `stringData` 필드를 사용해서 쓰기 전용으로(Base64 인코딩 텍스트) 생성 가능

```yaml
kind: Secret
apiVersion: v1
# 쓰기 전용
stringData:
  # plain text는 자동으로 Base64 인코딩을 하지 않음
  foo: plain text
data:
  # 직접 Base64 인코딩된 값을 삽입
  https.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQ...
  https.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcE...
```

<br>

### 컨피그맵과 시크릿 비교
시크릿 항목의 내용은 Base64 인코딩 문자열로 표시(시크릿 항목으로 바이너리 값도 담을 수 있음)  
컨피그맵 내용은 일반 텍스트로 표시  

```
kubectl get secret fortune-https -o yaml
apiVersion: v1
data:
  foo: YmFyCg==
  https.cert: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCekNDQ...
  https.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcE...
kind: Secret
...
```

<br>

```
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

### 파드에서 시크릿 사용
nginx 설정을 한다면 기존에 만든 컨피그맵 수정 필요  

<img width="550" height="400" alt="pod_and_secret_and_configmap" src="https://github.com/user-attachments/assets/df94b583-5fc6-49aa-8ced-d3c3a7d55a26" />

<br>
<br>

```
$ kubectl edit configmap fortuen-config
```

<br>

```yaml
data:
  my-nginx-config.conf |
    server {
      ...
      ssl_certificate      certs/https.cert;
      ssl_certificate_key  certs/https.key;
      ...
    }
...
```

<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune-https
spec:
  containers:
  - image: luksa/fortune:env
    name: html-generator
    env:
    - name: INTERVAL
      valueFrom:
        configMapKeyRef:
          name: fortune-config
          key: sleep-interval
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:apline
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    # nginx 서버가 해당 경로에서 읽도록 설정했기 때문에 시크릿 볼륨을 해당 위치로 마운트
    - name: config
      mountPath: /etc/nginx/conf.d
      readOnly: true
    - name: certs
      mountPath: /etc/nginx/crets/
      readOnly: true
    ports:
    - containerPort: 80
    - containerPort: 443
  volumes:
  - name: html
    emptyDir: {}
  - name: config
    configMap:
      name: fortune-config
      items:
      - key: my-nginx-config.conf
        path: https.conf
  # 시크릿 참조를 위한 시크릿 볼륨
  - name: certs
    secret:
      secretName: fortune-https
```




























