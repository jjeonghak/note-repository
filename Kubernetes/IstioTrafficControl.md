# 트래픽 제어
이스티오 서비스 프록시는 서비스 메시 클러스터 내부의 서비스 간 통신을 가로채 트래픽 제어 가능  

<br>

## 배포 위험 줄이기

<img width="700" height="450" alt="release_deployment" src="https://github.com/user-attachments/assets/ad83b5e5-c245-4497-a5e8-59c5228915d9" />

운영 환경에 배포할 때는 새 코드를 운영 환경 리소스에 설치하지만 트래픽을 보내지 않음  
해당 시점에 실행 중인 새 배포에 테스트를 실행해 동작 검증 가능  
릴리스는 실제 트래픽을 새 배포로 가져오는 것을 의미  
내부 직원들은 트래픽을 제어해 신 버전을 미리 사용하고 로그와 메트릭 수집을 통해 관찰 및 검증 가능  
새 코드를 모든 고객에게 노출할 때까지 라우팅 사용자 기준을 넓혀 릴리스하고 관찰 가능  

<br>

## 요청 라우팅
요청의 헤더를 평가하고 해당 콘텐츠에 따라 요청의 라우팅을 제어 가능  
특정 사용자들에게만 배포를 제공할 수 있는데 이것이 다크 런치(`dark launch`) 기법  

<br>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: catalog
spec:
  host: catalog
  subsets:
  - name: version-v1
    labels:
      version: v1
  - name: version-v2
    labels:
      version: v2
```

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog-vs-from-gw
spec:
  hosts:
  - "catalog.istioinaction.io"
  gateways:
  - catalog-gateway
  http:
  - match:
    - headers:
      x-istio-cohort:
        exact: "internal"
    route:
    - destination:
        host: catalog
        subset: version-v2
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

<br>

### 호출 그래프 내 깊은 위치 라우팅

<img width="600" height="300" alt="deep_routing" src="https://github.com/user-attachments/assets/d4adba21-8671-4d22-9815-b582b5de9d54" />

지금까지 이스티오 라우팅은 수행 위치가 에지/게이트웨이, 이런 트래픽 규칙은 호출 그래프 내 깊은 곳에도 적용 가능  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  gateways:
  - mesh                # 메시의 모든 사이드카에 적용
  http:
  - match:
    - headers:
        x-istio-cohort:
          exact: "internal"
    route:
    - destination:
        host: catalog
        subset: version-v2
  - route:
    - destination:
        host: catalog
        subset: version-v1
```

<br>

## 트래픽 전환
헤더 비교에 기반이 아닌 가중치 기반으로 특정 서비스에 여러 버전의 트래픽을 분배하는 방법 존재  
가중치 총합은 반드시 100  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  gateways:
  - mesh
  http:
  - route:
    - destination:
        host: catalog
        subset: version-v1
      weight: 90                  # 90% 트래픽만 라우팅
    - destination:
        host: catalog
        subset: version-v2
      weight: 10                  # 10% 트래픽만 라우팅
```

<br>

### Flagger 카나리 릴리스
이전까지는 라우팅 변경과 새로운 설정 적용을 CLI에서 수동으로 진행  
Flagger를 사용해서 서비스 릴리스를 자동화 가능  

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: catalog-release
  namespace: istioinaction
spec:
  targetRef:                          # 카나리 대상 디플로이먼트
    apiVersion: apps/v1
    kind: Deployment
    name: catalog
  progressDeadlineSeconds: 60
  service:                            # 서비스용 설정
    name: catalog
    port: 80
    targetPort: 3000
    gateways:
    - mesh
    hosts:
    - catalog
  analysis:                           # 카나리 진행 파라미터
    interval: 45s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 30s
```








































