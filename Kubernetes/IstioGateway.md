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
    - "webapp.istionaction.io"    # 포트의 호스트
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
해당 설정을 통한 규칙은 지정된 게이트웨이와 가상 호스트에 대한 트래픽에만 적용  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: webapp-vs-from-gw
spec:
  hosts:
  - "webapp.istioinaction.io"    # 비교할 가상 호스트네임
  gateways:
  - coolstore-gateway           # 해당 리소스를 적용할 게이트웨이
  http:
  - route:
    - destination:              # 트래픽의 목적 서비스
      host: webapp
      port:
        number: 8080
```

<br>

### 전체적인 트래픽 흐름 개요

<img width="700" height="500" alt="istio_traffic_flow" src="https://github.com/user-attachments/assets/5f6ebae5-cc41-4285-bfa0-0e39f3b2cb10" />

Gateway 리소스는 서비스 메시 클러스터의 에지에서 리스닝하고자 하는 포트, 프로토콜, 가상 호스트 정의  
VirtualService 리소스는 에지에서 허용된 트래픽이 가야 할 곳을 정의  

<br>

### 쿠버네티스 인그레스 비교
이스티오가 일반 쿠버네티스 인그레스를 사용하지 않음  
쿠버네티스 인그레스의 사양은 HTTP 워크로드에만 맞춰져 매우 단순(Nginx, Treafik 등)  
실제로 인그레스 사양은 80 포트와 443 포트만 인그레스 포인트로 간주  
또한 복잡한 트래픽 라우팅 규칙, 트래픽 분할, 트래픽 섀도잉 같은 것들을 지정 불가  
이스티오 Gateway 리소스는 L4, L5 문제를 처리하고 VirtualService 리소스는 L7 문제를 처리  

<br>

## 게이트웨이 트래픽 보안
인그레스 게이트웨이의 기본 기능 중 하나는 트래픽을 보호해 시스템의 신뢰 구축을 돕는 것  
들어오는 TLS/SSL 트래픽을 종료하고 백엔드 서비스로 전달  

<br>

### TLS를 사용한 HTTP 트래픽

<img width="650" height="300" alt="istio_ingress_tls" src="https://github.com/user-attachments/assets/6929a130-1b78-409a-bcc2-5b0010715a1f" />

인증서와 키를 사용하려면 먼저 인증서/키를 쿠버네티스 시크릿으로 생성 필수  
사실상 쿠버네티스 시크릿은 평문으로 저장되기 때문에 적합하지 않음  

```yaml
apiVersion: networking.istio.io/v1alpha3
kiind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
  - port:
      number:                             # 보안 HTTPS 트래픽 허용
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE                        # 보안 커넥션
      credentialName: webapp-credential    # 인증서가 들어있는 쿠버네티스 시크릿 이름
    hosts:
    - "webapp.istioination.io"
```

<br>

<img width="700" height="300" alt="istio_internal_traffic_tls" src="https://github.com/user-attachments/assets/01e42451-4ab3-4a07-a337-60d55e1f9496" />

종단 간 암호화를 통해 이스티오 인그레스 게이트웨이를 향하는 트래픽을 보호  
서비스 메시 내에서 실행 중인 뒷단의 애플리케이션 서비스 사이의 홉은 서비스의 ID를 사용해 암호화  

<br>

### HTTP 리다이렉트
HTTPS 사용을 강제 가능  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
    tls:
      httpsRedirect: true          # HTTP를 HTTPS로 리다이렉트
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: webapp-credential
    hosts:
    - "webapp.istioination.io"
```

<br>

### 상호 TLS를 사용한 HTTP 트래픽(mTLS)

<img width="700" height="350" alt="mtls" src="https://github.com/user-attachments/assets/834728f2-e474-4187-8b40-28a856d40f63" />

클러스터 외부의 트래픽을 받아들이기 전에 클라이언트가 누군지 검증하고 싶은 경우 사용  
클라이언트가 자신의 공개 인증서를 보내게 하고 서버가 인증서를 신뢰하는지 검증  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "webapp.istioinaction.io"
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL                                # 상호 TLS 설정
      credentialName: webapp-credential-mtls      # 신뢰 가능한 CA 자격 증명
    hosts:
    - "webapp.istioinaction.io"
```

<br>

### 여러 가상 호스트 TLS 서빙
인그레스 게이트웨이는 동일한 HTTPS 포트에서 자체 인증서와 비밀키가 있는 여러 가상 호스트 서빙 가능  
또한 인그레스 게이트웨이로 노출한 서비스용 VirtualService 리소스도 추가 필요  
엔보이가 TLS의 SNI(서버 이름 표시)를 구현하기 때문에 올바른 인증서 제시 및 라우팅 가능  

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: coolstore-gateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https-webapp
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: webapp-credential
    hosts:
    - "webapp.istioinaction.io"
  - port:
      number: 443
      name: https-catalog
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: catalog-credential
```

<br>

## TCP 트래픽
인그레스 게이트웨이로 TCP 접근 트래픽 노출 가능(데이터베이스, 메시지 큐 등)  
이스티오가 트래픽을 단순 TCP로 다루면 재시도, 요청 수준 서킷 브레이킹, 복잡한 라우팅 등 유용한 기능 사용 가능  

<br>

### 이스티오 게이트웨이에서 TCP 포트 노출























