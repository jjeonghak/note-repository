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

<br>

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

해당 Canary 리소스에서는 어떤 Deployment가 대상인지, 어떤 Service, VirtualService가 자동 생성 대상인지 정의  
또한 카나리를 얼마나 빨리 진행할지, 생존 판단 메트릭, 성공 판단 임계값 등을 기술  

```
$ kubectl get canary catalog-release -w
NAME             STATUS        WEIGHT  LASTTRANSITIONTIME
catalog-release  Initializing  0       2021-01-20T22:50:16Z
catalog-release  Initializied  0       2021-01-20T22:51:11Z
catalog-release  Progressing   0       2021-01-20T22:58:41Z
catalog-release  Progressing   10      2021-01-20T22:59:26Z
catalog-release  Progressing   20      2021-01-20T23:00:11Z
catalog-release  Progressing   30      2021-01-20T23:00:56Z
catalog-release  Progressing   40      2021-01-20T23:01:41Z
catalog-release  Progressing   50      2021-01-20T23:02:26Z
catalog-release  Promoting     0       2021-01-20T23:03:11Z
catalog-release  Finalising    0       2021-01-20T23:03:56Z
catalog-release  Succeeded     0       2021-01-20T23:04:41Z
```

<br>

## 트래픽 미러링

<img width="600" height="350" alt="traffic_mirroring" src="https://github.com/user-attachments/assets/4e06323c-3829-42b3-ae37-65e30489d3b8" />

운영 환경 트래픽을 새 디플로이먼트로 미러링하는 것으로 사용자에게 영향을 주지 않고 새 코드 동작 검증 가능  
미러링된 요청은 보내고 잊는 방식으로 미러링된 클러스터에서 오는 응답을 모두 무시  
미러링된 요청은 호스트 이름에 `-shadow` 접미사가 붙음  

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
      weight: 100
    mirror:                    # 미러링 부분
      host: catalog
      subset: version-v2       # 서비스의 부분집합
```

<br>

## 서비스 디스커버리를 사용해 클러스터 외부 서비스 라우팅
기본적으로 이스티오는 트래픽이 서비스 메시 밖으로 향하는 것을 허용  
외부 트래픽을 차단하려면 메시에 간단한 보호 계층 추가 필수  

<img width="650" height="350" alt="istio_external_traffic" src="https://github.com/user-attachments/assets/995b358b-5427-48e6-8d02-a2e610699b27" />

```
$ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
```

<br>

<img width="700" height="200" alt="service_entry" src="https://github.com/user-attachments/assets/f17a7f71-43ac-4b4f-8bc2-71f07d9ec47c" />

모든 서비스가 서비스 메시 내에 있는 것은 아니므로 메시 내부의 서비스가 메시 외부와 통신할 방법 필요  
이스티오는 내부 서비스 저장소를 구축하는데 여기에 메시에서 인지하고 접근할 수 있는 모든 서비스 존재  
해당 저장소가 메시 내 서비스 디스커버리 저장소의 공식적인 표현  
이스티오 ServiceEntry 리소스는 이스티오의 서비스 저장소에 항목을 삽입하는데 사용 가능한 저장소 메타데이터 캡슐화  

<br>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: jsonplaceholder
spec:
  hosts:
  - jsonplaceholder.typicode.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
  location: MESH_EXTERNAL
```

ServiceEntry 리소스는 항목을 이스티오 서비스 저장소에 삽입  
JSON 플레이스홀더 서비스는 클러스터 외부에 있는 서비스와의 통신을 실험할 수 있는 REST API 노출  

<br>
