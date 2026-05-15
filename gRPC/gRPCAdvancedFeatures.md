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

## 취소 처리
클라이언트와 서버는 모두 통신 성공 여부를 독립적으로 결정  
클라이언트와 서버는 RPC를 중단 가능하며, 취소 결정을 상대방에게 전파  

```java
Context.CancellableContext cancellableContext = Context.current().withCancellation();

cancellableContext.run(() -> {
  StreamObserver<StringValue> requestStream = asyncStub.processOrders(new StreamObserver<CombinedShipment>() {
    @Override
    public void onNext(CombinedShipment value) { ... }

    @Override
    public void onError(Throwable t) {
      Status status = Status.fromThrowable(t);
      System.out.println("RPC Status: " + status.getCode());
    }

    @Override
    public void onCompleted() { ... }
  });

  try {
    requestStream.onNext(StringValue.newBuilder().setValue("101").build());
    requestStream.onNext(StringValue.newBuilder().setValue("102").build());

    Thread.sleep(1000);

    // RPC 강제 취소
    cancellableContext.cancel(new Exception("User cancelled the RPC"));

    // 취소 이후 전송은 실패하거나 무시
    requestStream.onNext(StringValue.newBuilder().setValue("103").build());
    requestStream.onCompleted();
  } catch (Exception e) {
    e.printStackTrace();
  }
});
```

<br>


서버 측도 클라이언트의 연결 취소 요청을 실시간으로 확인 가능  

```java
public StreamObserver<StringValue> processOrders(StreamObserver<CombinedShipment> responseObserver) {
    // 서버에서 클라이언트의 취소 여부를 실시간으로 감지하고 싶을 때
    Context.current().addListener(context -> {
        System.out.println("Client cancelled the request or connection lost.");
    }, MoreExecutors.directExecutor());

    return new StreamObserver<StringValue>() {
        @Override
        public void onNext(StringValue value) {
            // 클라이언트가 취소하기 전까지 데이터 처리
        }

        @Override
        public void onError(Throwable t) {
            Status status = Status.fromThrowable(t);
            if (status.getCode() == Status.Code.CANCELLED) {
                System.out.println("RPC Cancelled: 서버 리소스 정리 시작...");
            }
        }

        @Override
        public void onCompleted() {
            responseObserver.onCompleted();
        }
    };
}
```

<br>

## 에러 처리
에러가 발생하면 에러 상태의 자세한 정보를 제공하는 선택적 에러 메시지와 함께 에러 상태 코드를 반환  
- OK: 성공적인 상태
- CANCELLED: 처리가 취소, 일반적으로 호출자에 의해 호출
- DEADLINE_EXCEEDED: 처리가 완료되기 전에 데드라인 만료
- INVALID_ARGUMENT: 클라이언트가 유효하지 않은 인자를 지정

```java
import com.google.rpc.BadRequest;
import com.google.rpc.Code;
import com.google.rpc.Status;
import io.grpc.protobuf.StatusProto;

if ("-1".equals(orderReq.getId())) {
  System.out.println("Order ID is invalid: " + orderReq.getId());

  BadRequest.FieldViolation violation = BadRequest.FieldViolation.newBuilder()
    .setField("ID")
    .setDescription(String.format("Order Id received is not valid %s : %s",
        orderReq.getId(), orderReq.getDescription())
    .build();

  BadRequest badRequest = BadRequest.newBuilder()
    .addFieldViolations(violation)
    .build();

  Status statuc = Statuc.newBuilder()
    .setCode(Code.INVALID_ARGUMENT_VALUE)
    .setMessage("Invalid information received")
    .addDetails(com.google.protobuf.Any.pack(badRequest))
    .build();

  responseObserver.onError(StatusProto.toStatusRuntimeException(status));
  return;
}
```

```java
try {
  Order order1 = Order.newBuilder().setId("-1").build();
  StringValue res = stub.addOrder(order1);
  System.out.println("AddOrder Response -> " + res.getValue());
} catch (StatusRuntimeException e) {
  com.google.rpc.Status status = io.grpc.protobuf.StatusProto.fromThrowable(e);

  if (status.getCode() == Code.INVALID_ARGUMET_VALUE) {
    System.out.println("Invalid Argument Error: " + status.getCode());
    for (com.google.protobuf.Any any : status.getDetailsList()) {
      try {
        if (any.is(BadRequest.class)) {
          BadRequest br = any.unpack(BadRequest.class);
          for (BadRequest.FieldViolation v : br.getFieldViolationsList()) {
            System.out.printf("Request Field Invalid: %s - %s\n", v.getField(), v.getDescription());
          }
        } else {
          System.out.println("Unexpected error type: " + any.getTypeUrl());
        }
      } catch (InvalidProtocolBufferException ex) {
        ex.printStackTrace();
      }
    }
  } else {
    System.out.println("Unhandled error: " + status.getCode());
  }
}
```

<br>

## 멀티플렉싱
gRPC 서버에서 여러 gRPC 서비스를 실행 가능  
여러 gRPC 클라이언트 스텁에 동일한 gRPC 클라이언트 연결을 사용 가능  

<img width="500" height="250" alt="multifexing" src="https://github.com/user-attachments/assets/70481d6f-5a6f-4bfe-9cef-1a0df0f5f027" />

<br>

두 gRPC 서비스가 하나의 gRPC 서버에서 실행 중이면 하나의 gRPC 연결만으로 호출 가능  

```java
import io.grpc.Server;
import io.grpc.ServerBuilder;

public class OrderManagementServer {
  private static final int PORT = 50051;

  public static void main(String[] args) throws IOException, InterruptedException {
    initSampleData();
    Server server = ServerBuilder.forPort(PORT)
      .addService(new OrderMgtServiceImpl())
      .addService(new HelloServiceImpl())
      .build();

    server.start();
    server.awaitTermination();
  }
}
```

```go
conn, err := grpc.Dial(address, grpc.WithInsecure())
...
orderManagementClient := pb.NewOrderManagementClient(conn)
...
res, addErr := orderManagementClient.AddOrder(ctx, &order1)
...
helloClient := hwpb.NewGreeterClient(conn)
...

helloResponse, err := helloClient.SayHello(hwcCtx, &hwpb.HelloRequest{Name: "gRPC Up and Running"})
```















