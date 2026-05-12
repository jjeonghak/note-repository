# gRPC 고급 기능

## 인터셉터
클라이언트나 서버에 원격 함수 실행 전후 몇 가지 공통적인 로직을 실행할 필요 존재  
로깅, 인증, 메트릭 등과 같은 특정 요구 사항 충족을 위해 RPC 실행을 가로채는 것 가능  
단순 RPC의 경우 단일 인터셉터, 스트리밍 RPC의 경우 스트리밍 인터셉터를 사용  

<br>

### 서버 측 인터셉터
클라이언트가 원격 메서드 호출시 서버에서 인터셉터를 사용해 원격 메서드 실행 전 공통 로직 실행 가능  

<img width="500" height="300" alt="server_side_interceptor" src="https://github.com/user-attachments/assets/cdfccb77-817d-44af-9a66-896770622e0f" />

<br>

### 단일 인터셉터
서버 측 단일 인터셉터 구현은 일반적으로 전처리, 메서드 호출, 후처리의 세 부분으로 분류 가능  
후처리가 필요하지 않은 경우 단순하게 핸들러 호출을 바로 반환 가능  

```java
import io.grpc.*;

public class OrderUnaryServerInterceptor implements ServerInterceptor {
  @Override
  public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
        ServerCall<ReqT, RespT> call,
        Metadata headers,
        ServerCallHandler<ReqT, RespT> next) {

    // 전처리
    System.out.println("====== [Server Interceptor] " + call.getMethodDescriptor().getFullMethodName());

    // 실제 핸들러(서비스 로직) 호출
    // Java에서는 Listener를 통해 응답 시점을 가로챔
    ServerCall.Listener<ReqT> listener = next.startCall(call, headers);

    return new ForwardingServerCallListener.SimpleForwardingServerCallListener<ReqT>(listener) {
      @Override
      public void onMessage(ReqT message) {
        super.onMessage(message);
      }

      @Override
      public void onComplete() {
        // 후처리
        System.out.println(" Post Proc Message: Completed");
        super.onCompleted();
      }
    };
  }
}
```

```java
public static void main(String[] args) throws IOException, InterruptedException {
  Server server = ServerBuilder.forPort(50051)
      .addService(ServerInterceptors.intercept(new OrderMgtImpl(), new OrderUnaryServerInterceptor()))
      .build();
  
  server.start();
  server.awaitTermination();
}
```

<br>

### 스트리밍 인터셉터
모든 스트리밍 RPC 호출을 인터셉트  
전처리 단계와 스트림 종작 인터셉트 단계를 모두 포함  

```java
import io.grpc.*;

public class OrderServerStreamInterceptor implements ServerInterceptor {
  @Override
  public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
      ServerCall<ReqT, RespT> call,
      Metadata headers,
      ServerCallHandler<ReqT, RespT> next) {

  System.out.println("====== [Server Stream Interceptor] " + call.getMethodDescriptor().getFullMethodName());

  // 서버가 클라이언트로 보내는 메시지 가로채기
  ServerCall<ReqT, RespT> wrappedCall = new ForwardingServerCall.SimpleForwardingServerCall<ReqT, RespT>(call) {
    @Override
    public void sendMessage(RespT message) {
      System.out.println("====== [Server Stream Interceptor Wrapper] SendMsg: " + message);
      super.sendMessage(message);
    }
  };

  // 실제 핸들러 호출 및 클라이언트가 보내는 메시지 가로채기
  ServerCall.Listener<ReqT> listener = next.startCall(wrappedCall, headers);

  return new ForwardingServerCallListener.SimpleForwardingServerCallListener<ReqT>(listener) {
      @Override
      public void onMessage(ReqT message) {
        System.out.println("====== [Server Stream Interceptor Wrapper] RecvMsg: " + message);
        super.onMessage(message);
      }

      @Override
      public void onComplete() {
        super.onCompleted();
      }

      @Override
      public void onError(Throwable t) {
        System.err.println("RPC failed with error " + t.getMessage());
        super.onError(t);
      }
    };
  }
}
```

<br>

### 클라이언트 측 인터셉터
클라이언트가 원격 메서드를 호출시 해당 호출을 가로채는 것 가능  

<img width="500" height="300" alt="client_side_interceptor" src="https://github.com/user-attachments/assets/c05c1418-db1a-4e58-a829-6683744db01c" />

<br>

### 단일 인터셉터
서버 측 단일 인터셉터와 유사하게 여러 단계를 갖음  

```java
import io.grpc.*;

public class OrderUnaryClientInterceptor implements ClientInterceptor {
  @Override
  public <ReqT, RespT> ClientCall<ReqT, RespT> interceptCall(
        MethodDescriptor<ReqT, RespT> method,
        CallOptions callOptions,
        Channel next) {
    System.out.println("Method: " + method.getFullMethodName());
    return new ForwardingClientCall.SumpleForwardingClientCall<ReqT, RespT>(next.newCall(method, callOptions)) {
      @Override
      public void start(Listener<RespT> responseListener, Metadata headers) {
        super.start(new ForwardingClientCallListener.SimpleForwardingClientCallListener<RespT>(responseListener) {
          @Override
          public void onMessage(RespT message) {
            System.out.println("Reply: " + message);
            super.onMessage(message);
          }
        }, headers);
      }
    };
  }
}
```

```java
ManagedChannel channel = ManagedChannelBuilder.forAddress("localhost", 50051)
    .usePlaintext()
    .intercept(new OrderUnaryClientInterceptor())
    .build();
```

<br>

### 스트리밍 인터셉터
서버 측 구현과 매우 유사  

```java
import io.grpc.*;

public class OrderClientStreamInterceptor implements ClientInterceptor {
  @Override
  public <ReqT, RespT> ClientCall<ReqT, RespT> interceptCall(
      MethodDescriptor<ReqT, RespT> method,
      CallOPtions callOptions,
      Channel next) {
    System.out.println("====== [Client Interceptor] " + method.getFullMethodName());
    return new ForwardingClientCall.SimpleForwardingClientCall<ReqT, RespT>(next.newCall(method, callOptions)) {
      @Overrdie
      public void start(Listener<RespT> responseListener, Metadata headers) {
        super.start(new ForwardingClientCallListener.SimpleForwardingClientCallListener<RespT>(responseListener) {
          @Override
          public void onMessage(RespT message) {
            System.out.println(println("====== [Client Stream Interceptor] RecvMsg: " + message);
            super.onMessage(message);
          }
        }, headers);
      }

      @Override
      public void sendMessage(ReqT message) {
        System.out.println("====== [Client Stream Interceptor] SendMsg: " + message);
        super.sendMessage(message); 
      }
    };
  }
}
```

<br>

## 데드라인
타임아웃은 클라이언트 애플리케이션이 RPC가 완료될 때가지 에러로 종료되기 전 얼마의 시간 동안 기다릴지 지정  
각 서비스 호출마다 개별 RPC를 기준으로 타임아웃 적용이 가능하지만, 요청 전체 생명주기에는 데드라인을 사용  
요청을 시작하는 애플리케이션이 데드라인을 설정하면 전체 요청 체인은 데드라인까지 응답 필수  

<img width="500" height="150" alt="deadline" src="https://github.com/user-attachments/assets/99d01233-daea-4a4c-a9ec-c87db570e1d9" />

<br>

클라이언트 애플리케이션은 gRPC 서비스를 처음 연결할 때 데드라인을 설정  
해당 시간 내에 RPC 호출이 응답하지 않으면 `DEADLINE_EXCEEDED` 에러 반환  

```java
ManagedChannel channel = ManagedChannelBuilder.forAddress("localhost", 8080)
    .usePlaintext()
    .build();
try {
  OrderManagementGrpc.OrderManagementBlockingStub stub = OrderManagementGrpc.newBlockingStub(channel)
    .withDeadlineAfter(2, TimeUnit.SECOND);
  Order order1 = Order.newBuilder()
    .setId("101")
    .addItems("iPhone XS")
    .addItems("Mac Book Pro")
    .setDestination("San Jose, CA")
    .setPrice(2300.00f)
    .build();

  try {
    StringValue res = stubWithDeadline.addOrder(order1);
    System.out.println("AddOrder Response -> " + res.getValue());
  } catch (StatusRuntimeException e) {
    Status.Code code = e.getStatus().getcode();
    System.out.printf("Error Occured -> AddOrder : %s\n", code);
    if (code == Status.Code.DEADLINE_EXCEEDED) {
      System.out.println("Timeout");
    }
  } finally {
    channel.shutdown().awaitTermination(5, TimeUnit.SECONDS);
  }
}
```

<br>

서버 측에서도 클라이언트의 `DEADLINE_EXCEEDED` 상태를 확인 가능  
클라이언트가 이미 데드라인 초과 상태인지를 확인한 후 서버에서 RPC를 더 이상 진행하지 않고 에러를 반환  

<br>
