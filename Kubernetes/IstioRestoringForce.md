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

<img width="550" height="400" alt="istio_refional_weight_distribution" src="https://github.com/user-attachments/assets/76b7c1bd-9363-49d2-845e-1e43f04f925e" />

지역 인식 로드 밸런싱은 종작 방식 일부를 제어할 수 있다는 것  
이스티오 기본 설정에서 서비스 프록시는 모든 트래픽을 동일 지역의 서비스로 보냄  
장애나 비정상 엔드포인트가 있을 때만 다른 지역으로 넘김  
하지만 트래픽 일부를 여러 지역에 분산하고 싶다면 지역 가중 분포를 사용  
특히 지역의 서비스가 피크 시간이나 계절성 트래픽으로 인해 과부될 것으로 예상한 경우 해당 방법 사용  

<br>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    loadBalancer:                            # 로드 밸런서 설정 추가
      localityLbSetting:
        distribute:
        - from: us-west1/us-west1-a/*        # 출발지 영역
          to:                                # 목적지 영역
            "us-west1/us-west1-a/*": 70
            "us-west1/us-west1-b/*": 30
      connectionPool:
        http:
          http2MaxRequests: 10
          maxRequestsPerConnection: 10
      outlierDetection:
        consecutive5xxErrors: 1
        interval: 5s
        baseEjectionTime: 30s
        maxEjectionPercent: 100
```

<br>

## 투명한 타임아웃과 재시도
네트워크에 분산된 구성 요소에 의존하는 시스템을 구축할 때 가장 큰 문제는 지연 시간과 실패  
이러한 문제를 다양한 종류의 타임아웃과 재시도를 설정해 신뢰성 문제를 극복 가능

<br>

### 타임아웃
중요한 점은 서비스 호출 사이의 타임아웃이 서로 상호작용하는 방법  
일반적으로 호출 그래프의 계층이 깊을수록 타임아웃이 짧고 얕을수록 긴 것이 합리적  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-backend-vs
spec:
  hosts:
  - simple-backend
  http:
  - route:
    - destination:
      host: simple-backend
    timeout: 0.5s      # 타임아웃 값 지정
```

<br>

### 재시도

<img width="550" height="400" alt="istio_retry" src="https://github.com/user-attachments/assets/de209bf2-d6ef-4eaa-bfb0-364433819525" />

무분별한 재시도는 연쇄 장애를 야기하는 등 시스템 상태 저하 발생 가능  
이스티오에서는 재시도가 기본적으로 활성화, 두 번까지 재시도  
- 커넥션 수립 실패(connect-failure)
- 스트림 거부됨(refused-stream)
- 사용 불가(gRPC 상태 코드 14)
- 취소됨(gRPC 상태 코드 1)
- 재시도할 수 있는 상태 코드들(이스티오에서 기본값은 HTTP 503)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-backend-vs
spec:
  hosts:
  - simple-backend
  http:
  - route:
    - destination:
      host: simple-backend
    retries:
      attempts: 2
```

<br>

이스티오 재시도 정책 활성화로 우회했기 때문에 실패는 있지만 호출자에게는 드러나지 않음  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-backend-vs
spec:
  hosts:
  - simple-backend
  http:
  - route:
    - destination:
      host: simple-backend
    retries:
      attempts: 2                                            # 최대 재시도 횟수
      retryOn: gateway-error,connect-failure,retriable-4xx   # 재시도 오류 목록
      perTryTimeout: 300ms                                   # 타임아웃
      retryRemoteLocalities: true                            # 재시도 시 다른 지역 엔드포인트에 시도할지 여부
```

<br>

### 타임아웃에 따른 재시도
각 재시도에는 자체적인 제한 시간 존재, `perTryTimeout`에 총 시도 횟수를 곱한 값이 전체 요청 제한 시간보다 작아야함  
그렇지 않다면 재시도를 모두 하기 전에 전체 요청 타임아웃이 발동  
또한 재시도 사이에는 백오프(`backoff`) 지연도 존재  

<br>

<img width="400" height="250" alt="istio_retry_flow" src="https://github.com/user-attachments/assets/81b79643-4422-4d2e-b70e-d184b45a0dc8" />

요청이 이스티오 서비스 프록시를 거칠때 업스트림 전달 실패시 요청 실패 표시 후 정의한 최대 재시도 횟수까지 재시도  
재시도 사이에 이스티오는 25ms를 베이스로 재시도 백오프 실행  

<br>

<img width="400" height="250" alt="istio_thundering_herd" src="https://github.com/user-attachments/assets/2c8e4086-5df9-4b58-8729-ec65c550358a" />

기본 재시도 횟수는 2지만 시스템 내의 계층이 다르면 재시도 횟수도 다르도록 재정의 가능  
너무 많은 재시도 횟수를 설정하면 천둥 무리(`thundering herd`) 문제 발생 가능  
해결 방법은 아키텍처 가장자리에서는 재시도 횟수를 1회 이하로 제한, 중간 요소는 0회로 설정  
호출 스택 깊숙한 곳에서만 재시도하게 하는 것  

<br>

재시도는 기본적으로 자기 지역의 엔드포인트에서 시도  
`retryRemoteLocalities` 설정이 해당 동작에 영향을 줌  

<br>

### 고급 재시도
재시도 기능 일부는 백오프 시간이나 재시도할 수 있는 상태 코드처럼 변경이 어려운 기본값들을 고려  
이스티오 확장 API를 사용해 엔보이 설정에서 해당 값들을 직접 변경 가능  
이때는 EnvoyFilter API를 함께 사용, 이는 비상용 해결책  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: simple-backend-retry-status-codes
  namespace: istioinaction
spec:
  workloadSelector:
    labels:
      app: simple-web
  configPatches:
  - applyTo: HTTP_ROUTE
    match:
      context: SIDECAR_OUTBOUND
      routeConfiguration:
        vhost:
          name: "simple-backend.istioinaction.svc.cluster.local:80"
    patch:
      operation: MERGE
      value:
        route:
          retry_policy:                  # 엔보이 설정
            retry_back_off:
              base_interval: 50ms        # 기본 간격 변경
            retriable_status_codes:      # 재시도 가능 코드 추가
            - 408
            - 400
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: simple-backend-vs
spec:
  hosts:
  - simple-backend
  http:
  - route:
    - destination:
        host: simple-backend
    retreis:
      attempts: 2
      retryOn: 5xx,retriable-status-codes    # 재시도 가능 상태 코드 포함
```

<br>

요청이 임계값에 도달해 시간을 초과하면 요청 헤징을 수행하도록 선택적으로 엔보이 설정 가능  
요청 헤징(`request hedging`)이란 타임아웃된 요청을 다른 호스트로도 요청을 보내 원래 타임아웃된 요청과 경쟁  
경쟁에서 이긴 요청을 다운스트림 호출자에게 반환  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: simple-backend-retry-hedge
  namespace: istioinaction
spec:
  workloadSelector:
    labels:
      app: simple-web
  configPatches:
  - applyTo: VIRTUAL_HOST
    match:
      context: SIDECAR_OUTBOUND
      routeConfiguration:
        vhost:
          name: "simple-backend.istioinaction.svc.cluster.local:80"
    patch:
      operation: MERGE
      value:
        hedge_policy:
          hedge_on_per_try_timeout: true
```

<br>

### 이스티오를 이용한 서킷 브레이킹
서킷 브레이커 기능을 사용하면 부분적이거나 연쇄적인 장애를 방지 가능  
이스티오에 서킷 브레이커라는 명시적인 설정은 없지만 부하 제한을 위한 두 가지 방법 존재  

<br>

<img width="400" height="300" alt="istio_endpoint_limit" src="https://github.com/user-attachments/assets/4bd84c66-ef44-4a1b-bd5b-dfb8827a7880" />

특정 서비스로의 커넥션 및 미해결 요청 개수를 얼마나 허용할지 관리  
DestinationRule의 connectionPool 설정을 사용해서 서비스 호출 누적 커넥션 요청 개수 제한 가능  
또한 로드 밸런싱 풀의 엔드포인트 상태를 관찰해 오동작하는 엔드포인트를 잠시 퇴출  

<br>

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1             # 커넥션 총개수
      http:
        http1MaxPendingRequests: 1    # 대기 중인 요청
        maxRequestPerConnection: 1    # 커넥션 당 요청 개수
        maxRetries: 1
        http2MaxRequests: 1           # 모든 호스트에 대한 최대 동시 요청 개수
```

- maxConnections: 커넥션 오버플로를 보고할 임계값
- http1MaxPendingRequests: 사용할 커넥션이 없어 보류 중인 요청을 얼마나 허용할지
- http2MaxRequests: 클러스터 내 모든 엔드포인트/호스트에 걸쳐 있는 병렬 요청의 최대 개수 제어

<br>

요청이 서킷 브레이커 임계값을 넘겨 실패하면 이스티오 서비스 프록시는 `x-envoy-overloaded` 헤더를 추가  
해당 해더를 확인하면 호출한 클라이언트에게 응답을 보내기 위해 대체 전략(`fallback`)을 사용하는 결정 가능  

<br>

### 이상값 감지로 비정상 서비스에 대응

<img width="400" height="300" alt="istio_consecutive" src="https://github.com/user-attachments/assets/7a807635-6db5-4364-95cb-724c45462634" />

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: simple-backend-dr
spec:
  host: simple-backend.istioinaction.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 5s
      baseEjectionTime: 5s
      maxEjectionPercent: 100
```

해당 설정은 consecutive5xxErrors 값을 1로 설정해서 잘못된 요청 하나만 발생해도 이상값 감지가 발동  
interval 설정은 이스티오 서비스 프록시가 얼마나 자주 호스트를 확인할지 지정  
서비스 엔드포인트가 제거된다면 제거되는 시간은 n(쫒겨난 횟수) * baseEjectionTime으로 결정  





























