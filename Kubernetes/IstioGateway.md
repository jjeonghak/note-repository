# 이스티오 게이트웨이

<img width="700" height="400" alt="istio_traffic" src="https://github.com/user-attachments/assets/43d47649-6167-4196-924f-9d74c36f5ca8" />

클러스터 외부의 트래픽을 클러스터 내부로 유입시키기 위한 진입점  

<br>

## 트래픽 인그레스
인그레스란 네트워크 외부에서 발원해 네트워크 내부 엔드포인트를 향하는 트래픽  
인그레스 포인트는 모든 외부 트래픽을 받는 역할을 하며 네트워크 규칙과 정책을 집행  

<br>

### 가상 IP: 서비스 접근 단순화

<img width="700" height="400" alt="virtual_ip" src="https://github.com/user-attachments/assets/7087da78-5d50-4851-a0af-1ef4c87c388a" />

실제 IP가 아닌 가상 IP를 사용함으로 유연성을 증가  
가상 IP는 리버스 프록시라는 인그레스 포인트 유형에 바인딩  

<br>

### 가상 호스팅: 단일 접근 지점의 여러 서비스

<img width="700" height="350" alt="virtual_hosting" src="https://github.com/user-attachments/assets/add82175-6402-4dcd-960b-fbae6f66c731" />

두 호스트네임에 대한 요청을 모두 동일한 가상 IP로 해석 가능  
그에 따라 동일한 인그레스 리버스 프록시가 해당 요청들을 라우팅  
서로 다른 서비스 여러 개를 진입점 하나로 호스팅하는 것이 가상 호스팅  
HTTP/1.1에서는 `Host` 헤더, HTTP/2에서는 `:authority` 헤더로 분별 가능  

<br>

## 이스티오 인그레스 게이트웨이

<img width="700" height="400" alt="istio_ingress_gateway" src="https://github.com/user-attachments/assets/e0b18bb9-8bfb-4a9f-baea-babd6f6caf18" />

클러스터 외부에서 시작한 트래픽이 클러스터에 접근하는 것을 방어하고 제어  
또한 로드 밸런싱과 가상 호스트 라우팅도 처리  

<br>

```
$ kubectl -n istio-system exec deploy/istio-ingressgateway -- ps
PID  TTY    TIME CMD
  1  ?      00:00:04 pilot-agent
 14  ?      00:00:24 envoy
 44  ?      00:00:00 ps
```

이스티오 서비스 프록시가 이스티오 인그레스 게이트웨이에서 실제로 작동 중인지 확인하기 위한 명령
실행 결과에 `pilot-agent`와 `envoy`가 조회되어야 함  
`pilot-agent` 프로세스는 처음에 엔보이 프록시를 설정하고 부트스트랩 담당  

<br>

### Gateway 리소스 지정
이스티오에서 인그레스 게이트웨이를 설정하기 위해 Gateway 리소스 설정 필수  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway        # 게이트웨이 이름
spec:
  selector:
    istio: ingressgateway        # 게이트웨이 구현체
  servers:
  - port:
      number: 80                 # 노출할 포트
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istionation.io"    # 포트의 호스트
```

```
$ istioctl -n istio-system proxy-config listener deploy/istio-ingressgateway
ADDRESS  PORT  MATCH  DESTINATION
0.0.0.0  8080  ALL    Route: http.80
0.0.0.0  15021 ALL    Inline Route: /healthz/ready*
0.0.0.0  15090 ALL    Inline Route: /stats/prometheus*
```

<br>

### VirtualService 게이트웨이 라우팅
트래픽이 게이트웨이로 들어오면 그 트래픽을 서비스 메시 내 특정 서비스로 가져올 방법 필요  
VirtualService 리소스는 클라이언트가 특정 서비스와 통신하는 방법을 정의  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: webapp-vs-from-gw
spec:
  hosts:
  - "webapp.istioination.io"    # 비교할 가상 호스트네임
  gateways:
  - coolstore-gateway           # 해당 리소스를 적용할 게이트웨이
  http:
  - route:
    - destination:              # 트래픽의 목적 서비스
      host: webapp
      port:
        number: 8080
```




























