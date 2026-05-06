# gRPC
로컬 함수를 호출하는 것만큼 쉽게 분산된 이기종 애플리케이션을 연결, 호출, 운영, 디버깅할 수 있는 통신 기술  
가장 먼저 서비스 인터페이스 정의 필요  
서버는 스켈레톤, 클라이언트는 스텁을 통해 서버 및 클라이언트 측 코드 생성 가능  

<br>

## 서비스 정의
gRPC는 프로토콜 버퍼를 IDL로 이용해서 서비스 인터페이스를 정의  
해당 프로토콜 버퍼는 언어에 구애받지 않고 플랫폼 중립적으로 구조화된 데이터를 직렬화  
서비스 인터페이스 정의는 프로토(`proto`) 파일에 표현  

```proto
syntax = "proto3";
package ecommerce;

service ProductInfo {
  rpc addProduct(Product) returns (ProductID);
  rpc getProduct(ProductID) returns (Product);
}

message Product {
  string id = 1;
  string name = 2;
  string description = 3;
}

message ProductID {
  string value = 1;
}
```

<br>

서비스는 원격으로 호출될 수 있는 메서드의 모음  
입력과 출력 파라미터는 사용자 정의 타입이거나 프로토콜 버퍼의 이미 알려진 타입 가능  
메시지의 필드는 이름-값 형식의 논리적 레코드이며 메시지 바이너리 형식에서 필드를 식별하기 위한 고유 필드번호 보유  

<br>

### gRPC 서버
서비스 정의 완료후 이를 사용해 프로토콜 버퍼 컴파일러인 `protoc`를 사용해 서버 또는 클라이언트 측 코드 생성 가능  
서비스 로직을 구현하기 위해서 서비스 정의에서 서비스 스켈레톤을 먼저 생성  

```go
import (
  ...
  "context"
  pb "github.com/grpc-up-and-running/samples/ch02/productinfo/go/proto"
  "google.golang.org/grpc"
  ...
)

// 제품 등록을 위한 원격 메서드
func (s *server) AddProduct(ctx context.Context, in *pb.Product) (
        *pb.ProductID, error) {
  // 업무 로직
}

// 제품 조회용 원격 메서드
func (s *server) GetProduct(ctx context.Context, in *pb.ProductID) (
        *pb.Product, error) {
  // 업무 로직
}
```

<br>

서비스 구현후 서버를 실행해 클라이언트에서의 요청을 수신하고 해당 요청을 서비스 구현으로 지정  

```go
func main() {
  lis, _ := net.Listen("tcp", port)
  s := grpc.NewServer()
  pb.RegisterProductInfoServer(s, &server{})
  if err := s.Serve(lis); err != nil {
    log.Fatalf("failed to serve: %v", err)
  }
}
```

<br>

### gRPC 클라이언트
서버 측과 마찬가지로 서비스 정의를 사용해 클라이언트 스텁을 생성  
해당 스텁은 서버와 동일한 메서드를 제공, 클라이언트 코드에서 메서드들의 호출을 네트워크상 원격 함수 호출로 변환  

```java
ManagedChannel channel = ManagedChannelBuilder.forAddress("localhost", 8080)
    .usePlaintext(true)
    .build();

ProductInfoGrpc.ProductInfoBlockingStub stub = ProductInfoGrpc.newBlockingStub(channel);

StringValue productID = stub.addProduct(
  Product.newBuilder()
    .setName("Apple iPhone 11")
    .setDescription("Meet Apple iPhone 11")
    .build()
);
```

<br>

### 클라이언트-서버 메시지 흐름
클라이언트가 서비스를 호출할 때 프로토콜 버퍼를 사용해 원격 프로시저 호출 프로토콜 버퍼 형식으로 마샬링(`marshal`)  
서버 측에서는 요청을 언마샬링(`unmarshal`)하고 각 프로시저 호출을 프로토콜 버퍼에 의해 실행  
마샬링은 파라미터와 원격 함수를 네트워크상에 전송되는 메시지 패킷으로 피킹하는 프로세스  

<br>

## 프로세스 간 통신의 역사
RPC는 클라이언트-서비스 애플리케이션 사이에서 로컬 메서드를 호출하는 것처럼 원격으로 메서드의 기능을 호출하는 통신  
이런 RPC 구현은 상호운용성을 저해하는 TCP와 같은 통신 프로토콜로 구축되고 과장된 규격에 기반을 두기 때문에 복잡  
SOAP은 서비스 지향 아키텍처에서 서비스 간 XML 기반의 구조화된 데이터 교환용 표준 통신 기술  
SOAP 중심으로 구축된 규격의 복잡성과 메시지 포맷의 복잡성 때문에 분산 애플리케이션의 민텁성을 저해  
HTTP와 JSON을 사용한 REST 아키텍처 스타일은 마이크로서비스 구축에 용이하지만 최신 요구사항을 충족하지 못함  

<br>

### 비효율적 텍스트 기반 메시지 프로토콜
본질적으로 RESTful 서비스는 HTTP1.x와 같은 텍스트 기반 전송 프로토콜로 구축  
서비스 간 통신의 경우 사람이 읽을 수 있는 텍스트 기반 포맷은 필요가 없기 때문에 JSON과 같은 텍스트 포맷은 비효율적  
해당 방식보다는 서비스와 소비자의 비즈니스 로직으로 바로 매핑될 수 있는 바이너리 형식으로 쉽게 전송하는 것이 효율적  

<br>

### 엄격한 타입 점검 부족
폴리글랏(`ployglot`) 기술로 구축되는 서비스가 증가함에 따라 명확하고 엄격한 점검 서비스 정의가 중요  
기존 RESTful 서비스의 경우 대부분 서비스 정의 기술이 근간의 아키텍처 스타일이나 메시징 프로토콜에 처음부터 고려되지 않음  

<br>

### gRPC의 시작
구글은 스터비(`Stubby`)라는 범용 RPC 프레임워크를 사용해 여러 데이터센터의 서로 다른 기술로 구축된 서비스를 연결  
스터비는 여러 좋은 기능이 있지만 내부 인프라에 종속적이어서 범용 프레임워크로 표준화되지 못함  
이후 구글은 오픈소스 RPC 프레임워크로 gRPC를 출시  

<br>

### gRPC 장점
- 프로세스 간 통신 효율성: 프로토콜 버퍼 기반 바이너리 프로토콜 사용
- 간단 명확한 서비스 인터페이스와 스키마: 인터페이스 정의 후 구현 세부 사항을 작업
- 엄격한 타입 점검 형식: 통신에 사용할 데이터 타입을 명확하게 정의
- 폴리글랏: 여러 프로그래밍 언어와 작동하도록 설계
- 이중 스트리밍: 스트리밍을 기본적으로 지원
- 유용한 내장 기능 지원: 인증, 암호화, 복원력, 메타데이터 교환, 압축, 로드밸런싱, 서비스 검색 등 지원
- 클라우드 네이티브 생태계와 통합: CNCF의 일부며 대부분의 최신 프레임워크와 기술은 기본적으로 지원

<br>

### gRPC 단점
- 외부 서비스 부적합: 강력한 타입 속성을 갖기 때문에 외부 당사자에게 노출되는 서비스의 유연성을 방해
- 서비스 정의의 급격한 변경에 따른 개발 프로세스 복잡성: 스키마 변경시 일반적으로 클라이언트와 서버 코드 모두 수정
- 상대적으로 작은 생태계: REST나 HTTP 프로토콜에 비해 상대적으로 작음

<br>
