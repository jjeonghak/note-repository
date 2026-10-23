# 이스티오

## 이스티오 컨트롤 플레인

<img width="600" height="350" alt="istio_control_plane" src="https://github.com/user-attachments/assets/16ff96f3-b7b9-4ec3-bb01-bc64ed6c4d33" />

서비스 메시의 사용자가 메시를 제어, 모니터링, 관리, 설정할 수 있는 방법 제공  
- 라우팅/복원력 동작 지정 API
- 데이터 플레인 설정 API
- 데이터 플레인용 서비스 디스커버리 추상화
- 사용 정책 지정 API
- 인증서 발급 및 로테이션
- 워크로드 ID 할당
- 통합된 텔레메트리 수집
- 서비스 프록시 사이드카 주입
- 네트워크 경계 및 접근 방법 정의

<br>

### istiod

<img width="700" height="350" alt="istiod" src="https://github.com/user-attachments/assets/895d2738-711c-4725-8612-f5a11df7c027" />

이스티오의 컨트롤 플레인 역할은 `istiod`로 구현  
서비스 프록시로 엔보이를 사용하므로 설정들은 엔보이 설정으로 변환  

<br>

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadat:
  name: catalog-service
spec:
  hosts:
  - catalog.prod.svc.cluster.local
  http:
  - match:                          # 요청 비교 조건
    - headers:                  
      x-dark-launch:
        exact: "v2"                 # 정확히 일치하는 경우
    route:
    - destination:                  # 일치하는 경우 라우팅할 곳
      host: catalog.prod.svc.cluster.local
      subset: v2
  - route:                          # 나머지 모든 트래픽 라우팅할 곳 
    - destination:
      host: catalog.prod.svc.cluster.local
      subset: v1
```

위의 설정은 헤더에 `x-dark-launch: v2`가 존재하는 경우에 대한 라우팅 설정을 명시  
해당 설정은 엔보이의 설정으로 변환, 데이터 플레인 API를 통해 서비스 프록시에 엔보이 설정으로 노출  

<br>

```json
"domains": [
  "catalog.prod.svc.cluster.local"
],
"name": "catalog.prod.svc.cliuster.local:80",
"routes": [
  {
    "match": {
      "headers": [
        {
          "name": "x-dark-launch",
          "value": "v2"
        }
      ],
      "prefix": "/"
    },
    "route": {
      "cluster": "outbound|80|v2|catalog.prod.svc.cluster.local",
      "use_websocket": false
    },
    {
      "match": {
        "prefix": "/"
      },
      "route": {
        "cluster": "outbound|80|v1|catalog.prod.svc.cluster.local",
        "use_websocket": false
      }
    }
  }
]
```

istiod가 노출하는 이 데이터 플레인 API는 엔보이의 디스커버리 API를 구현  
서비스 디스커버리용(`LDS`), 엔드포인트용(`EDS`), 라우팅 규칙용(`RDS`) 등과 같은 디스커버리 API를 `xDs API`라고 표현  

<br>

<img width="500" height="350" alt="istio_encryption" src="https://github.com/user-attachments/assets/c3647af8-88ad-4ecd-9060-f4f6577ad190" />

이스티오의 핵심 기능 중 하나는 각 워크로드 인스턴스에 ID를 할당하고 서비스 간 호출 전송을 암호화  
해당 기능은 서비스 메시가 요청 경로의 양 끝단 모두에 위치하기 때문에 가능(트래픽 암호화에 `X.509` 인증서 사용)  

<br>

### 인그레스 및 이그레스 게이트웨이

<img width="600" height="400" alt="istio_gateway" src="https://github.com/user-attachments/assets/019d7880-ac50-49dd-b794-dc960613c938" />

인그레스 및 이그레스는 이스티오 설정을 이해할 수 있는 엔보이 프록시  
해당 구성 요소는 컨트롤 플레인이 아닌 데이터 플레인에 위치  
애플리케이션과 함께 동작하는 서비스 프록시와 매우 유사하게 설정되지만 애플리케이션 워크로드에도 독립적  
오직 트래픽이 클러스터로 드나드는 것을 허용하는 역할  

<br>

### 이스티오 복원력
복원력 기능 중 하나는 간헐적/일시적 네트워크 오류에 대한 요청 재시도  
메시 내 서비스 간 상호작용에 대한 규칙을 지정 가능

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: catalog
spec:
  hosts:
  - catalog
  http:
  - route:
    - destination:
      host: catalog
    retries:
      attempts: 3
      perTryTimeout: 2s
```

<br>

### 이스티오 트래픽 라우팅
호출 그래프의 깊이에 상관없이 서비스 메시 내 요청을 세밀하게 제어 가능  

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

<br>
