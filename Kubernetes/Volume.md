# 볼륨
외부 디스크 스토리지에 접근하고 컨테이너 간에 스토리지 공유하는 방법  
파드는 내부에 프로세스가 실행되고 CPU, RAM, 네트워크 인터페이스 등의 리소스를 공유하는 논리적 호스트와 유사  
하지만 파드 내부의 각 컨테이너는 고유하게 분리된 파일시스템을 보유  
스토리지 볼륨은 파드와 같은 최상위 리소스는 아니지만 파드 일부분으로 정의되며 파드와 동일한 라이프 사이클을 보유  

<br>

## 볼륨 소개
파드의 구성 요소로 컨테이너와 동일하게 파드 스펙에서 정의  
독립적인 쿠버네티스 오브젝트가 아니기때문에 자체적으로 생성, 삭제 불가  
파드의 모든 컨테이너에서 사용 가능하지만 접근하려면 컨테이너에서 각각 마운트 필수  

<img width="400" height="450" alt="storage_volume" src="https://github.com/user-attachments/assets/ef8426fd-6d1d-4eb0-acbb-da3dc054ad75" />

<br>
<br>

### 볼륨 유형
- `emptyDir`: 일시적인 데이터를 저장하는데 사용하는 빈 디렉토리
- `hostPath`: 워커 노드의 파일시스템을 파드의 디렉토리로 마운트
- `gitRepo`: 깃 레포지토리의 컨텐츠를 체크아웃해 초기화한 볼륨
- `nfs`: NFS 공유를 파드에 마운트
- `gcePersistentDisk`, `awsElasticBlockStorre`, `azureDisk`: 클라우드 프로바이더 전용 볼륨
- `cinder`, `cephfs`, `iscsi`, `flocker`, ... : 다른 유형의 네트워크 스토리지를 마운트
- `configMap`, `secret`, `downwardAPI`: 쿠버네티스 리소스나 클러스터 정보를 파드에 노출하는데 사용되는 볼륨
- `persistentVolumeClaim`: 사전에 혹은 동적으로 프로비저닝된 퍼시스턴트 스토리지를 사용하는 방법

<br>

### emptyDir 볼륨 사용
파드에 실행중인 애플리케이션은 어떤 파일이든 볼륨에 사용 가능  
파드 삭제시 볼륨 컨텐츠도 사라짐, 파드에 종속적이며 파드 내부에서만 사용  
동일 파드에서 실행 중인 컨테이너 간 파일 공유에 유용  

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: fortune
spec:
  containers:
  - image: luksa/fortune
    name: html-generator
    volumeMounts:
    - name: html
      mountPath: /var/htdocs
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /ver/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: html
    emptyDir: {}
    # 메모리로 저장할 경우
    # emptyDir:
    #   medium: Memory
```

<br>

### 깃 레포지토리를 볼륨으로 사용
기본적으로 emptyDir 볼륨이며, 파드가 시작되면 깃 레포지토리를 복제하고 특정 리비전을 체크아웃해 데이터로 채움  
볼륨이 생성된 직후에만 참조, 이후에는 레포지토리와 동기화하지 않음, 따로 추가 커밋을 푸시해도 볼륨에 있는 파일 변경되지 않음  
만약 깃 레포지포리에 새 버전을 푸시하고 반영하려면, 파드를 삭제 후 재생성 필수  
만약 동기화가 필요하다면 깃 동기화 프로세스 사이드카 컨테이너를 함께 사용  

<img width="550" height="250" alt="gitrepository_volume" src="https://github.com/user-attachments/assets/8cd00075-4eee-4f64-b555-c80d92f0fce5" />

<br>
<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gitrepo-volume-pod
spec:
  containers:
  - image: nginx:alpine
    name: web-server
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
      readOnly: true
    ports:
    - containerPort: 80
      protocol: TCP
  volumes:
  - name: html
    gitRepo:
      # private 레포지토리는 불가
      repository: https://github.com/luksa/kubia-website-example.git
      # master 브랜치 체크아웃
      revision: master
      # 볼륨의 루트 디렉토리레 깃 레포지토리 복제
      directory: .
```

<br>

## 워커 노드 파일시스템의 파일 접근
대부분의 파드는 호스트 노드를 인식 못하기 때문에 노드 파일시스템에 접근하면 안됨  
특정 시스템 레벨의 파드(데몬셋 관리 파드)는 노드 파일을 읽거나 파일시스템 사용이 필요할 가능성 존재  

<br>

### hostPath 볼륨
노드 파일시스템의 특정 파일이나 디렉토리를 가리킴  
동일 노드 내부의 파드들은 `hostPath` 볼륨의 동일 경로를 사용중이면 동일한 파일이 표시  
`persistent storage` 유형 중 하나, 노드 종속적이며 파드가 삭제되도 남아있음  
대부분 노드의 로그파일, kubeconfig, CA 인증서 접근을 위해 이 유형의 볼륨을 사용  

<img width="550" height="250" alt="hostPath" src="https://github.com/user-attachments/assets/9624901a-d3c8-44ab-a44d-3abc965410bb" />

<br>
<br>

```
$ kubectl get pods s --namespace kube-system
NAME                         READY  STATUS    RESTARTS  AGE
fluentd-kubia-4ebc2f1e-9a3e  1/1    Running   1         4d
fluentd-kubia-4ebc2f1e-e2vz  1/1    Running   1         31d
...

$ kubectl describe pod fluentd-kubia-4ebc2f1e-9a3e --namespace kube-system
Name:         fluentd-cloud-logging-gke-kubia-default-pool-4ebc2f1e-9a3e
Namespace:    kube-system
...
  Volumes:
   varlog:
     Type:    HostPath (bare host directory volume)
     Path:    /var/log
varlibdockercontainers:
     Type:    HostPath (bare host directory volume)
     Path:    /var/lib/docker/containers
```

<br>

## 퍼시스턴트 스토리지
실행 중인 애플리케이션이 디스크에 데이터를 유지해야 하고 파드가 다른 노드로 재스케줄링된 경우에도 동일한 데이터를 사용하는 경우  
이러한 데이터는 어떤 클러스터 노드에서도 접근이 필요하기 때문에 `NAS(network-attached storage)` 유형에 저장  

<br>

### GCE 퍼시스턴트 디스크를 파드 볼륨으로 사용
초기 버전의 쿠버네티스는 기반 스토리지를 수동으로 프로비저닝  
먼저 GCE 퍼시스턴트 디스크 생성(쿠버네티스 클러스터가 있는 동일 영역)  

<img width="550" height="200" alt="gce_persistent_storage" src="https://github.com/user-attachments/assets/6058ddda-0990-42fb-b7d6-21e6cf4336f1" />

<br>
<br>

```
$ gcloud container clusters list
NAME   ZONE           MASTER_VERSION  MASTER_IP
kubia  europ-west1-b  1.2.5           104.115.84.137

$ gcloud compute disks create --size=1Gib --zone=europe-west1-b mongodb
WARNING: You have selected a disk size of under [200GB]. This may result in
    poor I/O performance. For more information, see:
    https://developers.google.com/compute/docs/disk#pdperformance.
Created [https://www.googleapis.com/compute/v1/projects/rapid-pivot-
    136513/zones/europe-west1-b/disks/mongodb].
NAME     ZONE            SIZE_GB  TYPE         STATUS
mongodb  europe-west1-b  1        pd-standard  READY
```

<br>

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mongodb
spec:
  volumes:
  - name: mongodb-data
    # google cloud
    gcePersistentDisk:
      pdName: mongodb
      fsType: ext4
    # aws
    # awsElasticBlockStore:
    #   volumeId: my-volume
    #   fsType: ext4
  containers:
  - image: mongo
    name: mongodb
    volumeMounts:
    - name: mongodb-data
      mountPath: /data/db
    ports:
    - containerPort: 27017
      protocol: TCP
```

<br>

```
$ kubectl delete pod mongodb
pod "mongodb" deleted

$ kubectl create -f mongodb-pod-gcepd.yaml
pod "mongodb" created

$ kubectl exec -it mongodb mongo
MongoDB shell version: 3.2.8
connecting to: mongodb://127.0.0.1:27017
Welcome to the MongoDB shell.
...

> use mystore
switched to db mystore
> db.foo.find()
{"_id": ObjectId("57a61eb9de0cfd512374cc75"), "name": "foo"}
```

<br>

### NFS 볼륨
클러스터가 여러 대의 서버로 실행되는 경우 외장 스토리지를 볼륨에 마운트하는 경우  
`NFS-Server`에서는 서버의 특정 경로를 외부에서 마운트할 수 있도록 익스포트 경로를 지정  

```yaml
volumes:
- name: mongodb-data
  nfs:
    server: 1.2.3.4
    path: /some/path
```

<br>

## 기반 스토리지 기술과 파드 분리











































