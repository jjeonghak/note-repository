# 복원력: 애플리케이션 네트워킹
이스티오를 사용해서 타임아웃, 재시도, 서킷 브레이커를 추가 가능  

<br>

## 클라이언트 측 로드 밸런싱

<img width="550" height="250" alt="client_side_load_balancing" src="https://github.com/user-attachments/assets/73b97729-872f-4180-a16d-276918494347" />

엔드포인트 간에 요청을 최적으로 분산시키기 위해 클라이언트에게 서비스에서 사용 가능한 여러 엔드포인트 목록을 주입  
중앙집중식 로드 밸런싱에 의존할 필요성 없고 여러 홉을 거치지 않고 특정 엔드포인트에 직접 요청 가능  

<br>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
```

<br>

## 지역 인식 로드 밸런싱

<img width="550" height="550" alt="istio_region" src="https://github.com/user-attachments/assets/1cfd0f71-21af-4d88-a928-7835d2980733" />

서비스 메시에서 전체 서비스 토폴로지를 이해할 때의 이점은 서비스와 피어 서비스의 위치 같은 휴리스틱을 바탕으로 라우팅 결정 가능  
워크로드의 위치에 따라 루트에 가중치를 부여하고 라우팅 결정  
쿠버네티스에 배포할 때 리전과 영역 정보를 노드 레이블에 추가 가능  
지역 인식 로드 밸런싱은 기본저긍로 활성화(`meshConfig.localityLbSetting.enabled: true`)  

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: simple-web
  name: simple-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: simple-web
    template:
      metadata:
        labels:
          app: simple-web
          istio-locality: us-west1.us-west1-a      # 지역성 레이블
      spec:
        serviceAccountName: simple-web
        containers:
        - image: nicholasjackson/fake-service:v0.14.1
          imagePullPolicy: IfNotPresent
          name: simple-web
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          securityCOntext:
            privileged: false
```

<br>

이스티오에서 지역 인식 로드 밸런싱이 작동하려면 마지막으로 헬스 체크 설정이 필수  
해당 설정이 없다면 로드 밸런싱 풀의 어느 엔드포인트가 비정상인지 판단 불가  

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 10
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutiveErrors: 1
      interval: 1m
      baseEjectionTime: 30s
```

<br>

### 가중치 분포를 사용한 지역 인식 로드 밸런싱 제어 강화













