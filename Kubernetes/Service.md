# 서비스
클라이언트가 파드를 검색하고 통신을 가능하게 지원  
시스템 관리자가 클라이언트 구성 파일에 서비스를 제공하는 서버의 정확한 ip 주소나 호스트 이름을 지정하는 것과 다름  
- 파드는 일시적, 공간 확보나 여러 이유에 의해 파드는 제거되거나 다른 노드로 이동 가능
- 노드에 파드를 스케줄링한 후 파드가 시작되면 그때 파드 ip 주소를 할당(미리 알 수 없음)
- 스케일링이 되어있다면, 여러 파드의 고유한 ip 주소가 아닌 단일 ip 필요

<br>

## 서비스 소개
동일한 서비스를 제공하는 파드 그룹에 지속적인 단일 접점을 만들기 위한 리소스  
각 서비스는 서비스가 존재하는 동안 절대 변경되지 않는 ip 주소와 포트를 보유  
즉 클라이언트는 개별 파드의 위치, ip 주소를 알 필요 없음  

<img width="550" height="350" alt="service" src="https://github.com/user-attachments/assets/2dae4023-f9c1-4633-a948-0877525f00f8" />

<br>
<br>

### 서비스 생성
서비스를 지원하는 파드가 한개 혹은 그 이상 가능, 서비스 연결은 뒷단의 모든 파드로 로드밸런싱  
레플리케이션컨트롤러와 기타 파드 컨트롤러와 유사하게 레이블 셀렉터를 사용  

<img width="400" height="300" alt="service_label_selector" src="https://github.com/user-attachments/assets/ec986a98-5cc5-4a7e-9763-8c1f41729acf" />

<br>
<br>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  ports:
  # 서비스가 사용할 포트
  - port: 80
    # 서비스가 포워드할 컨테이너 포트
    targetPort: 8080
  # 레이블 셀렉터
  selector:
    app: kubia
```

<br>

```
$ kubectl get svc
NAME        CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
kubernetes  10.111.240.1    <none>       443/TCP  30d
kubia       10.111.249.153  <none>       80/TCP   6m

$ kubectl exec kubia-7nog1 -- curl -s http://10.111.249.153
You've hit kubia-gzwli
```

<br>

<img width="600" height="350" alt="service_test" src="https://github.com/user-attachments/assets/e877fd66-9eaa-411f-a59a-b89d75508f0c" />

<br>
<br>

### 서비스 세션 어피니티 구성
서비스 프록시가 각 연결을 임의의 파드를 선택해 연결  
반면 특정 클라이언트의 모든 요청을 매번 같은 파드로 리다이렉션하려면 세션 어피니티(`sessionAffinity`) 옵션 설정 필요  
쿠버네티스는 HTTP 수준이 아닌 TCP 수준에서 동작하기 때문에 `None`, `ClientIP` 두가지 유형의 서비스 어피니티만 지원  
즉 쿠키 기반으로는 세션 어피니티 사용 불가  

```yaml
apiVersion: v1
kind: Service
spec:
  # 기본값은 None
  sessionAffinity: ClientIP
  ...
```

<br>

### 동일한 서비스에 여러 포트 노출
서비스는 단일 포트만 노출하지만 여러 포트 지원 가능  
여러 포트가 있는 서비스의 경우 각 포트의 이름 지정 필수  

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia
spec:
  ports:
  - name: http
    port: 80
    targetPort: 8080
  - name: https
    port: 443
    targetPort: 8443
  selector:
    app: kubia
```

<br>

### 이름 지정 포트 사용
각 파드 포트에 이름을 지정하면 서비스에서 해당 포트의 이름 참조 가능  

```yaml
kind: Pod
spec:
  containers:
  - name: kubia
    ports:
    - name: http
      containerPort: 8080
    - name: https
      containerPort: 8443
```

```yaml
kind: Service
spec:
  ports:
  - name: http
    port: 80
    targetPort: http
  - name: https
    port: 443
    targetPort: https
```

<br>

## 서비스 검색

### 환경변수
파드가 시작되면 해당 시점에 존재하는 각 서비스를 가리키는 환경변수 세트를 초기화  
클라이언트 파드를 생성하기 전에 서비스를 생성하면 해당 파드의 프로세스는 환경변수를 검사해서 서비스 ip 주소와 포트를 얻음  

```
$ kubectl delete pod --all
pod "kubia-7nog1" deleted
pod "kubia-bf50t" deleted
pod "kubia-gzwli" deleted

$ kubectl exec kubia-3inly env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=kubia-3inly
KUBERNETS_SERVICE_HOST=10.111.240.1
KUBERNETS_SERVICE_PORT=443
...
KUBIA_SERVICE_HOST=10.111.249.153
KUBIA_SERVICE_PORT=80
...
```

<br>

### DNS
`kube-system` 네임스페이스에 `kube-dns` 파드 존재  
해당 파드는 DNS 서버를 실행하며 모든 파드는 자동으로 이를 사용(각 컨테이너의 `/etc/resolv.cong` 파일을 수정)  
파드가 내부 DNS 서버를 사용할지 여부는 각 파드 스펙의 `dnsPolicy` 속성으로 구성 가능  

<br>

### FQDN
프론트엔드 파드는 다음 FQDN(정규화된 도메인 이름)으로 서비스 연결 가능  

```
// 서비스이름.네임스페이스.클러스터로컬서비스이름
backend-database.default.svc.cluster.local
```

```
$ kubectl exec -it kubia-3inly bash
root@kubia-3inly:/#

root@kubia-3inly:/# curl http://kubia.default.svc.cluster.local
You've hit kubia-5asi2

root@kubia-3inly:/# cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local ...
```

<br>

## 클러스터 외부에 있는 서비스 연결
서비스가 클러스터 내에 있는 파드로 연결 전달이 아닌 외부 ip와 포트로 연결 전달하는 경우  

<br>

### 서비스 엔드포인트
서비스는 파드에 직접 연결되지 않고 엔드포인트 리소스가 그 사이에 존재  

```
$ kubectl describe svc kubia
Name:                kubia
Namespace:           default
Labels:              <none>
Selector:            app=kubia
Type:                ClusterIP
IP:                  10.111.249.153
Port:                <unset> 80/TCP
Endpoints:           10.108.1.4:8080,10.108.2.5:8080,10.108.2.6:8080
Session Affinity:    None
No events.
```

<br>

### 서비스 엔드포인트 수동 구성
- 셀렉터 없이 서비스 생성

<img width="500" height="200" alt="service_endpoint" src="https://github.com/user-attachments/assets/fa5fe6c8-322c-4be1-8f03-ef15751fc93a" />

<br>
<br>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  ports:
  - port: 80
```

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  # 서비스 이름과 엔드포인트 오브젝트 이름은 일치
  name: external-service
subsets:
  # 서비스가 연결을 전달할 엔드포인트 ip
  - addresses:
    - ip: 11.11.11.11
    - ip: 22.22.22.22
    ports:
    - port: 80
```

<br>

### 외부 서비스를 위한 별칭
외부 서비스 별칭으로 사용되는 서비스를 만들기 위해 `ExternalName` 설정 필수  
해당 서비스는 DNS 레벨에서만 구현되며 `CNAME` DNS 레코드만 생성(ClusterIP 없음)  

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-service
spec:
  # 서비스 유형 ExternalName
  type: ExternalName
  # 실제 서비스의 FQDN
  externalName: someapi.somecompany.com
  ports:
  - port: 80
```

<br>

## 외부 클라이언트에 서비스 노출
- 노드포트로 서비스 유형 설정
- 서비스 유형을 노드포트 유형으로 확장인 로드밸런서로 설정
- 단일 ip 주소로 여러 서비스를 노출하는 인그레스 리소스 생성

<br>

### 노드포트 서비스 사용
노드포트(`NodePort`) 서비스의 경우 각 클러스터 노드가 노드 자체에서 포트를 열고 트래픽을 서비스로 전달  
일반 서비스(실제 유형은 ClusterIP)와 유사하지만 서비스 내부 클러스터 ip 뿐만 아니라 모든 노드의 ip와 포트로 서비스 엑세스 가능  

<img width="550" height="450" alt="nodeport" src="https://github.com/user-attachments/assets/b04a91d9-56c7-4e53-83ae-3d9b47b92544" />

<br>
<br>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-nodeport
spec:
  # 서비스 유형 NodePort
  type: NodePort
  ports:
  # 클러스터 내부 ip
  - port: 80
    # 서비스 대상 파드 포트
    targetPort: 8080
    # 각 클러스터 노드의 포트, 생략시 쿠버네티스가 임의의 포트 지정
    nodePort: 30123
  selector:
    app: kubia
```

<br>

```
$ kubectl get svc kubia-nodeport
NAME            CLUSTER-IP      EXTERNAL-IP  PORT(S)       AGE
kubia-nodeport  10.111.254.223  <nodes>      80:30123/TCP  2m

$ kubectl get nodes -o jsonpath='{.items[*].status.address[?(@.type=="ExternalIP")].address}'
130.211.97.55 130.211.99.206

$ curl http://130.211.97.55:30123
You've hit kubia-ym8or
```

<br>

### 외부 로드밸런서로 서비스 노출
클라우드 공급자에서 실행되는 쿠버네티스 클러스터는 일반적으로 로드밸런서를 제공  
만약 지원하지 않는 환경이라도 로드밸런서 서비스는 노드포트 서비스의 확장  
노드포트 서비스와는 달리 방화벽 설정이 필요 없음  

<img width="550" height="500" alt="loadbalancer" src="https://github.com/user-attachments/assets/f4a41bf3-e263-4c2a-8234-cde7575619ed" />

<br>
<br>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-loadbalancer
spec:
  # 서비스 유형 LoadBalancer
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: kubia
```

<br>

```
$ kubectl get svc kubia-loadbalancer
NAME                CLUSTER-IP      EXTERNAL-IP     PORT(S)       AGE
kubia-loadbalancer  10.111.241.153  130.211.53.173  80:32143/TCP  1m

$ curl http://130.211.53.173
You've hit kubia-xueq1
```

<br>

### 외부 연결 특성
외부 클라이언트가 노드포트(로드밸런서) 서비스에 접속할 경우 연결 파드가 동일한 노드가 아닐 가능성 존재  
이 경우 파드에 도달하려면 추가적인 네트워크 홉이 필요  
외부의 연결을 수신한 노드에서 실행 중인 파드로만 외부 트래픽을 전달하도록 `externalTrafficPolicy` 속성 설정 필수  
해당 설정시 서비스 프록시는 로컬에 실행중인 파드를 선택  

<img width="450" height="250" alt="external_traffic_policy" src="https://github.com/user-attachments/assets/2982e2e3-4450-4620-bd77-49410ad7ceff" />

```
spec:
  externalTrafficPolicy: Local
```

<br>

### 인그레스 리소스
로드밸런서 서비스는 자신의 공용 ip 주소가 필요하지만, 인그레스는 하나의 ip로 수십개의 서비스에 접근 가능  
인그레스 리소스 작동을 위해 클러스터에 인그레스 컨트롤러(`nginx`) 실행 필수  

<img width="600" height="250" alt="ingress" src="https://github.com/user-attachments/assets/a56adc87-5360-4769-888a-9293622d866c" />

<br>
<br>

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  rules:
  # 도메인 이름을 서비스에 매핑
  - host: kubia.example.com
    http:
    paths:
    - path: /
      backend:
        serviceName: kubia-nodeport
        servicePort: 80
```

<br>

```
$ kubectl get ingress
NAME   HOST               ADDRESS         PORTS  AGE
kubia  kubia.example.com  192.168.99.100  80     29m
```




















