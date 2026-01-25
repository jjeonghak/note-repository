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












