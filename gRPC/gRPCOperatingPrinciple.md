# gRPC 동작 원리

## RPC 흐름
서버는 원격으로 호출되는 일련의 기능을 구현  
클라이언트는 동일한 함수에 대해 추상화를 제공하는 스텁을 생성해 원격 함수를 호출하는 스텁 함수를 직접 호출  
gRPC의 주요 차이점은 메시지를 인코딩하는 방식, 인코딩을 위해 gRPC는 프로토콜 버퍼를 사용  

<img width="500" height="350" alt="remote_procedure_call" src="https://github.com/user-attachments/assets/f9c068c6-2016-4714-95b2-4560283633fa" />

<br>

## 프로토콜 버퍼를 사용한 메시지 인코딩
gRPC는 프로토콜 버퍼를 사용해 서비스 정의를 작성  
프로토콜 버퍼의 서비스 정의는 원격 메서드 정의와 네트워크를 통해 보내려는 메시지 정의를 포함  
각 메시지는 필드 식별자(태그)와 인코딩된 값을 이용해서 구성  

<img width="500" height="200" alt="encoding_byte_stream" src="https://github.com/user-attachments/assets/d37128de-a399-4b85-93f3-860c67550437" />

<br>

해당 태그들은 필드 인덱스와 와이어 타입의 두 가지 값으로 구성  
필드 인덱스는 메시지 정의에서 할당된 고유 번호, 와이어 타입은 필드가 가질 수 있는 데이터 타입  
특정 필드의 필드 인덱스와 와이어 타입을 알고 있다면 아래 식을 이용해서 태그 값을 결정 가능  

```
Tag value = (field_index << 3) | wire_type
```

| 와이어 타입 | 종류 | 필드 타입 |
|--|--|--|
| 0 | 가변 길이 정수 | int32, int64, uint32, uint64, sint32, sint64, bool, enum |
| 1 | 64 비트 | fixed64, sfixed64, double |
| 2 | 길이 구분 | string, bytes, embedded messages, packed repeated fields |
| 3 | 시작 그룹 | groups(사용 중단) |
| 4 | 종료 그룹 | groups(사용 중단) |
| 5 | 32 비트 | fixed32, sfixed32, float |

<br>

메시지가 인코딩되면 해당 태그와 값이 바이트 스트림으로 연결  
스트림의 끝은 0이라는 태그 값을 전송해 표시  
프로토콜 버퍼는 다양한 필드 타입을 지원하며 일부 필드 타입에는 다른 인코딩 메커니즘을 갖음  

<br>

### 가변 길이 정수
하나 이상의 바이트를 사용해 정수를 직렬화하는 방법  
대부분의 숫자가 균등하게 분포돼 있지 않다는 아이디어를 기반으로 구현  
따라서 각 값에 할당된 바이트 수는 고정돼 있지 않고 값에 따라 상이  

<br>

가변 길이 정수에서 마지막 바이트를 제외한 각 바이트의 최상위 비트는 1(앞으로 더 많은 바이트가 존재한다는 뜻)  
각 바이트의 하위 7비트는 해당 수에 대한 2의 보수 표현으로 저장  
최하위 비트가 먼저 등장하기 때문에 하위 그룹에 연속 비트를 추가  

```
300을 가변 길이 정수로 전송
1010 1100  0000 0010

첫 번째 바이트의 최상위 비트가 1이기 때문에 다음 바이트까지 하나의 정수로 저장
또한 7비트만 사용
1010 1100  0000 0010 -> 010 1100  000 0010

최하위 그룹이 먼저 나옴(순서 변경)
010 1100  000 0010 -> 000 0010  010 1100

10 진수 계산
256 + 32 + 8 + 4 = 300
```

<br>

### 부호 있는 정수
양수와 음수를 모두 갖는 타입으로 sint32와 sint64 같은 필드 타입이 부호 있는 정수로 간주  
부호 있는 타입의 경우 지그재그 인코딩이 부호 있는 정수를 부호 없는 정수로 변환하는데 사용  
변환한 이후에는 가변 길이 정수 인코딩 방식 사용  

| 원래 값 | 매핑된 값 |
|--|--|
| 0 | 0 |
| -1 | 1 |
| 1 | 2 |
| -2 | 3 |
| 2 | 4 |

<br>

int32, int64 같은 일반 타입을 사용하는 경우 음수는 가변 길이 인코딩을 사용하기 때문에 sint32, sint64 권장  
음의 정수에 대한 가변 길이 정수 인코딩은 양의 정수보다 같은 바이너리 값을 나타내고자 더 많은 바이트가 필요  

<br>

### 비가변 길이 정수 숫자
가변 길이 정수 타입과 반대, 실제 값에 관계없이 고정된 바이트 수를 할당  
fixed, sfixed, double, float 같은 데이터 타입  

<br>

### 문자열 타입
문자열 타입은 길이로 구분된 와이어 타입에 속함  
지정된 바이트 수의 데이터가 뒤따르는 가변 길이 정수 인코딩 크기를 갖음  
문자열은 UTF-8 문자 인코딩을 사용  

<br>

## 길이-접두사 지정 메시지 프레이밍
일반적인 용어로 메시지 프레이밍 방식은 의도한 대상이 정보를 쉽게 추출할 수 있도록 관련 정보를 구성하는 것  
길이-접두사 지정 방식은 메시지 자체를 전송하기 전에 각 메시지 크기를 기록하는 메시지 프레이밍 방식  

<img width="500" height="400" alt="message_framing" src="https://github.com/user-attachments/assets/96e880a3-4877-473d-8e95-0b9770b480da" />

<br>

압축 플래그 값이 1인 경우는 HTTP 전송에서 선언된 헤더 중 하나인 메시지 인코딩 헤더에 선언된 메커니즘을 사용  
값이 0인 경우는 메시지 바이트 인코딩이 발생하지 않았음을 나타냄  
수신자는 첫 번째 바이트를 읽어 메시지 압축 여부를 확인  
이후 다음 4바이트를 읽어 인코딩된 바이너리 메시지 크기를 얻음  

<br>

## HTTP/2를 통한 gRPC
gRPC 채널은 HTTP/2 연결인 엔드포인트에 대한 연결을 나타냄  
채널이 생성되면 서버로 여러 개의 원격 호출을 보낼 수 있도록 재사용  

<img width="500" height="250" alt="grpc_and_http2" src="https://github.com/user-attachments/assets/cf3d9edd-6a3a-4e02-a00d-05b35bec4df6" />

<br>

### 요청 메시지
요청 메시지는 원격 호출을 시작하는 메시지  
요청 메시지는 항상 클라이언트 애플리케이션에 의해 트리거  
요청 헤더, 길이-접두사 지정 메시지, 스트림 종료 플래그라는 세 가지 주요 요소로 구성  

<img width="500" height="100" alt="request_message" src="https://github.com/user-attachments/assets/e2551061-018f-4598-814f-3d7f505c3d02" />

<br>

```
HEADERS (flags = END_HEADERS)
:method = POST
:schema = http
:path = /ProductInfo/getProduct
:authority = abc.com
te = trailers
grpc-timeout = 1S
content-type = application/grpc
grpc-encoding = gzip
authorization = Bearer xxxxxx
```

`:`으로 시작하는 헤더 이름은 예약 헤더로, HTTP/2에서는 다른 헤더보다 앞에 등장  
헤더는 통신 정의 헤더(`call-definition`)와 사용자 정의(`custom`) 메타데이터로 분류  
통화 정의 헤더는 HTTP/2에서 지원하는 사전에 정의된 헤더로 사용자 정의 메타데이터보다 먼저 전송  
사용자 정의 메타데이터는 애플리케이션 계층에서 정의한 임의의 키-값 세트(접두사로 `grpc-` 사용 불가)  

<br>

```
DATA (flags = END_STREAM)
<Length-Prefixed Message>
```

요청 메시지의 마지막은 최종 DATA 프레임에 `END_STREAM` 플래그 추가 필수  

<br>

### 응답 메시지
클라이언트 요청에 대한 응답으로 서버에 의해 성생  
요청 메시지와 유사하게 응답 헤더, 길이-접두사 지정 메시지, 트레일러 세 가지 주요 요소로 구성  

<img width="500" height="100" alt="response_message" src="https://github.com/user-attachments/assets/16484e43-1f9a-432e-8105-b3625f2ad690" />

<br>

```
HEADERS (flags = END_HEADERS)
:status = 200
grpc-encoding = gzip
content-type = application/grpc
```

```
DATA
<Length-Prefixed Message>
```

요청 메시지와는 달리 `END_STREAM` 플래그는 데이터 프레임과 함께 전송되지 않음  
트레일러라는 별도의 헤더로 전송  

```
HEADERS (flags = END_STREAM, END_HEADERS)
grpc-status = 0
grpc-message = xxxxxx
```

<br>

특정 시나리오에서는 요청 호출에 즉각적인 실패가 발생 가능  
해당 경우 서버는 데이터 프레임 없이 트레일러만 응답을 보냄  

<br>

## gRPC 통신 패턴 메시지 흐름

### 단순 RPC
요청 메시지에는 헤더와 길이-접두사 지정 메시지가 포함  
클라이언트 측에서 연결 절반 종료를 위해 EOS 플래그 추가  
연결 절반 종료는 클라이언트 측에서 연결을 닫았지만 서버에서 들어오는 메시지는 수신 가능을 의미  
서버는 전체 메시지를 받은 후에만 응답 메시지를 생성  

<img width="500" height="250" alt="unary_rpc_message_flow" src="https://github.com/user-attachments/assets/eda5b965-4b64-4dbe-9124-29735d5270a6" />

<br>

### 서버 스트리밍 RPC








