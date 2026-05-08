# gRPC 통신 패턴
gRPC 기반 애플리케이션에는 단일 RPC, 서버 스트리밍, 클라이언트 스트리밍, 양방향 스트리밍 네 가지 기본 통신 패턴 존재  

<br>

## 단일 RPC(단순 RPC)
클라이언트가 서버의 원격 기능을 호출하고자 단일 요청을 서버로 보내고 응답을 받는 통신 패턴  

<img width="500" height="200" alt="unary_rpc" src="https://github.com/user-attachments/assets/a6c67d87-5a6b-4de6-af6b-10ac59db0f03" />

<br>

```proto
syntax = "proto3";

import "google/protobuf/wrappers.proto";

service OrderManagement {
  rpc getOrder(google.protobuf.StringValue) returns (Order);
}

message Order {
  string id = 1;
  repeated string items = 2;
  string description = 3;
  float price = 4;
  string destination = 5;
}
```

<br>

서비스 정의 프로토 파일을 사용해서 서버 스켈레톤 코드를 생성하고 메서드 로직 구현 가능  

```java
@Override
public void getOrder(StringValue request, StreamObserver<Order> responseObserver) {
  String orderId = request.getValue();
  Order ord = orderMap.get(orderId);
  responseObserver.onNext(ord);
  responseObserver.onCompleted();
}
```

<br>

서버 구현과 마찬가지로 클라이언트 스텁을 생성한 후 스텁을 사용해 서비스 호출  

```java
OrderManagementGrpc.OrderManagementBlockingStub orderMgtClient = PrderManagementGrpc.newBlockingStub(channel);
StringValue orderId = StringValue.newBuilder().setValue("106").build();
try {
  Order retrieveOrder = orderMgtClient.getOrder(orderId);
  System.out.println("GetOrder Response: " + retrievedOrder.toString());
} catch (StatusRuntimeException e) {
  System.out.println("RPC failed: " + e.getStatus());
}
```

<br>

## 서버 스트리밍 RPC
서버가 클라이언트의 요청 메시지를 받은 후 일련의 응답을 다시 보냄  
모든 서버 응답을 보낸 후 서버는 후행 메타데이터로 클라이언트에 전송해 스트림의 끝을 알림  

<img width="500" height="200" alt="server_strewaming_rpc" src="https://github.com/user-attachments/assets/c5621d6e-5d58-4d03-a830-c5a4ef61eb74" />

<br>

```proto
syntax = "proto3";

import "google/protobuf/wrappers.proto";

package ecommerce;

servier OrderManagement {
  rpc searchOrders(google.protobuf.StringValue) returns (stream Order);
}

message Order {
  string id = 1;
  repeated string items = 2;
  string description = 3;
  float price = 4;
  string destination = 5;
}
```

<br>

```java
@Override
public void searchOrders(StringValue searchQuery, StreamObserver<Order> responseObserver) {
  String query = searchQuery.getValue();
  for (Map.Entry<String, Order> entry : orderMap.entrySet()) {
    Order order = entry.getValue();
    for (String itemStr : order.getItemsList()) {
      if (itemStr.contains(query)) {
        responseObserver.onNext(order);
        System.out.println("Matching Order Found: " + entry.getKey());
        break;
      }
    }
  }
  responseObserver.onCompleted();
}
```

<br>

```java
OrderManagementGrpc.OrderManagementBlockingStub orderMgtClient = OrderManagementGrpc.newBlockingStub(channel);
StringValue searchQuery = StringValue.newBuilder().setValue("Google").build();
Iterator<Order> searchStream = orderMgtClient.searchOrders(searchQuery);
while (searchStream.hasNext()) {
  Order searchOrder = searchStream.next();
  System.out.println("Search Result: " + searchOrder.toString());
}
```

<br>

## 클라이언트 스트리밍 RPC
클라이언트가 하나의 요청이 아닌 여러 메시지를 서버로 보내고 서버는 클라이언트에게 단일 응답을 보냄  
서버는 클라이언트에서 모든 메시지를 수신해 응답을 보낼 때까지 기다릴 필요 없음  

<img width="500" height="200" alt="client_streaming_rpc" src="https://github.com/user-attachments/assets/5405ca1c-abe7-4e50-97f4-112f8d2a75ad" />

<br>

```proto
syntax = "proto3";

import "google/protobuf/wrappers.proto";

package ecommerce;

service OrderManagement {
  rpc updateOrders(stream Order) returns (google.protobuf.StringValue);
}

message Order {
  string id = 1;
  repeated string items = 2;
  string description = 3;
  float price = 4;
  string destination = 5;
}
```

<br>

```java
@Override
public StreamObserver<Order> updateOrders(StreamObserver<StringValue> responseObserver) {
  return new StreamObserver<Order>() {
    StringBuilder orderStr = new StringBuilder("Updated Order IDs: ");

    @Override
    public void onNext(Order order) {
      orderMap.put(order.getId(), order);
      System.out.println("Order ID " + order.getId() + ": Updated");
      orderStr.append(order.getId()).append(", ");
    }
  }

  @Override
  public void onError(Throwable t) {
    System.err.println("Order update failed: " + t.getMessage());
  }

  @Override
  public void onCompleted() {
    StringValue response = StringValue.newBuilder()
      .setValue("Orders processed " + orderStr.toString())
      .build();

    responseObserver.onNext(response);
    responseObserver.onCompledted();
  }
}
```

<br>

```java
OrderManagementGrpc.OrderManagementStub asyncStub = OrderManagementGrpc.newStub(channel);
StreamObserver<StringValue> responseObserver = new StreamObserver<StringValue>() {
  @Override
  public void onNext(StringValue value) {
    System.out.println("Update Orders Res: " + value.getValue());
  }

  @Override
  public void onError(Throwable t) {
    System.err.println("Error updating orders: " + t.getMessage());
  }

  @Override
  public void onCompleted() {
    System.out.println("Update completed by server.");
  }
};

StreamObserver<Order> updateStream = asyncStub.updateOrders(responseObserver);

try {
  updateStream.onNext(updOrder1);
  updateStream.onNext(updOrder2);
  updateStream.onNext(updOrder3);

  updateStream.onCompleted();
} catch (Exception e) {
  updateStream.onError(e);
}
```

<br>

## 양방향 스트리밍 RPC
클라이언트는 메시지 스트림으로 서버에 요청을 보내고 서버는 메시지 스트림으로도 응답  
호출은 클라이언트에서 시작하지만 그 후 통신은 로직에 따라 완전히 상이  
수신 스트림과 발신 스트림 모두 독립적으로 동작  

<img width="500" height="200" alt="bidirectional_streaming_rpc" src="https://github.com/user-attachments/assets/9e3fa32d-f7b4-42d3-adf8-9db015445920" />

<br>

```proto
syntax = "proto3";

import "google/protobuf/wrappers.proto";

service OrderManagement {
  rpc processOrders(stream google.protobuf.StringValue) returns (stream CombinedShipment);
}

message Order {
  string id = 1;
  repeated string items = 2;
  string description = 3;
  float price = 4;
  string destination = 5;
}

message CombinedShipment {
  string id = 1;
  string status = 2;
  repeated Order orderList = 3;
}
```

<br>

```java
@Override
public StreamObserver<StringValue> processorOrders(StreamObserver<CombinedShipment> responseObserver) {
  return new StreamObserver<StringValue>() {
    private int batchMarker = 0;
    private final int ORDER_BATCH_SIZE = 3;
    private Map<String, CombinedShipment> combinedShipmentMap = new HashMap<>();

    @Override
    public void onNext(StringValue orderId) {
      ...
      if (batchMarker == ORDER_BATCH_SIZE) {
        for (CombinedShipment comb : combinedShipmentMap.values()) {
          responseObserver.onNext(comb);
        }
        batchMarker = 0;
        combinedShipmentMap.clear();
      } else {
        batchMarker++;
      }
    }

    @Override
    public void onError(Throwable t) {
      System.out.println("Error in ProcessOrders: " + t.getMessage());
    }

    @Override
    public void onCompleted() {
      for (CombinedShipment comb : combinedShipmentMap.values()) {
        responseObserver.onNext(comb);
      }
      responseObserver.onCompleted();
    }
  };
}
```

<br>

```java
OrderManagementGrpc.OrderManagementStub asyncStub = OrderManagementGrpc.newStub(channel);
CountDownLatch finishLatch = new CountDownLatch(1);
StreamObserver<CombinedShipment> responseObserver = new StreamObserver<>() {
  @Override
  public void onNext(CombinedShipment value) {
    System.out.println("Combined shipment: " + value.getOrdersListList());
  }

  @Override
  public void onError(Throwable t) {
    t.printStackTrace();
    finishLatch.countDown();
  }

  @Override
  public void onCompleted() {
    System.out.println("Server has finished sending.");
    finishLatch.countDown();
  }
}

StreamObserver<StringValue> requestStream = asyncStub.processOrders(responseObserver);
try {
  requestStream.onNext(StringValue.newBuilder().setValue("102").build();
  requestStream.onNext(StringValue.newBuilder().setValue("103").build();
  requestStream.onNext(StringValue.newBuilder().setValue("104").build();
  Thread.sleep(1000);
  requestStream.onNext(StringValue.newBuilder().setValue("101").build();
  requestStream.onCompleted();

  if (!finishLatch.await(1, TimeUnit.MINUTES)) {
    System.out.println("ProcessOrders can not finish within 1 minute");
  }
} catch (InterruptedException e) {
  e.printStackTracd();
}
```

<br>
