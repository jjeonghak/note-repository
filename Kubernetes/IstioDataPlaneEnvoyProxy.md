# 이스티오 데이터 플레인: 엔보이 프록시
서비스 프록시는 애플리케이션과 함께 배치되지만 프로세스 외부에서 실행  
애플리케이션은 다른 서비스와 통신할 때 서비스 프록시를 거침  
이스티에서 엔보이 프록시는 서비스 메시에 참여하는 모든 애플리케이션 인스턴스와 함께 배치되어 데이터 플레인 형성  

<br>

## 엔보이 프록시

<img width="500" height="150" alt="proxy" src="https://github.com/user-attachments/assets/42430e32-0a34-4967-ac34-a82ad360e397" />

프록시는 클라이언트와 서버 간 통신의 중간에 위치한 네트워크 아키텍처의 중개 구성 요소  
엔보이 프록시는 특히 서비스 디스커버리, 로드 밸런싱, 헬스 체크 기능을 제공  
7계층 프로토콜 이해 및 기타 복원력 기능 추가 가능  

<br>

<img width="700" height="350" alt="envoy_ingress" src="https://github.com/user-attachments/assets/908c2594-e71b-4611-9b38-b62efa18a6bf" />

엔보이의 핵심 기능을 이해하기 위해 아래의 고수준 엔보이 개념 필요
- 리스너: 애플리케이션에 연결 가능한 외부 포트를 노출
- 루트: 리스너로 들어오는 트래픽을 처리하는 라우팅 규칙
- 클러스터: 엔보이가 트래픽을 라우팅할 수 있는 특정 업스트림 서비스

<br>

### 정적 설정
엔보이의 설정 파일을 이용해서 리스너, 라우팅 규칙, 클러스터를 지정 가능  
해당 설정은 15001 포트에 소켓을 열고 필터 체인을 붙이는 리스너 선언  
와일드카드로 모든 가상 호스트를 매칭하고 모든 트래픽을 `httpbin_service` 클러스터로 라우팅  

```yaml
static_resourves:
  listeners:                                    # 리스너 정의
  - name: httpbin-demo
    address:
      socket_address: { address: 0.0.0.0, port_value: 15001 }
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager    # http 필터
        config:
          stat_prefix: egress_http
          route_config:                        # 라우팅 규칙
            name: httpbin_local_route
            virtual_hosts:
            - name: httpbin_local_service
              domains: ["*"]                   # 와일드카드 가상 호스트
              routes:
              - match: { prefix: "/" }
                route:
                  auto_host_rewrite: true
                  cluster: httpbin_service     # 클러스터로 라우팅
          http_filters:
          - name: envoy.router
  cluster:
    - name: httpbin_service                    # 업스트림 클러스터
      connect_timeout: 5s
      type: LOGICAL_DNS
      dns_lookup_family: V4_ONLY
      lb_policy: ROUND_ROBIN
      hosts: [{ socket_address: { address: httpbin, port_value: 8000 }}]
```

<br>

### 동적 구성
엔보이는 특정 API군(xDS)을 사용해 다운타임이나 재시작 없이 설정을 실시간으로 업데이트 가능  
xDS 서비스는 최종적 일관성을 전제로 구축  
- LDS: 자신이 어떤 리스너를 노출해야 하는지 쿼리
- RDS: 리스너 설정의 일부, 사용할 루트를 지정, LDS 부분집합
- CDS: 클러스터 목록과 각 클러스터용 설정을 탐색 
- EDS: 클러스터 설정의 일부, 특정 클러스터에 어떤 엔드포인트를 사용하는지 지정, CDS 부분집합
- SDS: 인증서를 배부하는 데 사용
- ADS: 나머지 API에 대한 모든 변경 사항을 직렬화된 스트림으로 제공

```yaml
dynamic_resources:
  lds_config:                          # 리스너용 설정
    api_config_source:
      api_type: GRPC
      grpc_services:
        - envoy_grpc:                  # 해당 클러스터로 이동해 리스너 API 탐색
          cluster_name: xds_cluster
clusters:
- name: xds_cluster                    # gRPC 클러스터
  connect_timeout: 0.25s
  type: STATIC
  lb_policy: ROUND_ROBIN
  http2_protocol_options: {}
  hosts: [{ socket_address: { address: 127.0.0.3, port_value: 5678 }}]
```

<br>

## 엔보이 인 액션
엔보이는 C++로 작성돼 플랫폼에 맞게 컴파일  

<br>

### 엔보이 Admin API
Admin API를 사용해서 프록시 동작에 대한 통찰력을 향상 가능  
- `/cert`: 머신상 인증서
- `/clusters`: 엔보이에 설정한 클러스터
- `/config_dump`: 엔보이에 설정 덤프
- `/listeners`: 엔보이에 설정한 리스너
- `/logging`: 로깅 설정 확인 및 편집 가능
- `/stats`: 엔보이 통계
- `/stats/prometheus`: 엔보이 통계(프로메테우스 레코드 형식)

<br>

### 엔보이 요청 재시도

```yaml
- match: { prefix: "/" }
  route:
    auto_host_rewrite: true
    cluster: httpbin_service
    retry_policy:
      retry_on: 5xx    # 재시도 조건
      num_retries: 3   # 재시도 횟수
```

<br>
