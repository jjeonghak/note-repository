# 코드로 카프카 관리
프로그램적인 관리 기능 API를 제공하기 위한 목적으로 AdminClient 추가  
토픽 목록 조회, 생성, 삭제, 클러스터 상세 정보 확인, ACL 관리 등 여러 기능 제공  

<br>

## AdminClient 개요

### 최종적 일관성을 지닌 비동기 API
AdminClient는 비동기적으로 작동하기 때문에 결과값으로 `Future` 객체를 `Result` 객체로 래핑해서 리턴  
비동기적으로 처리되기 때문에 모든 브로커가 전부 새로운 상태에 대해 알고 있지 않음  

<br>

## AdminClient 사용법

```java
Properties props = new Properties();
props.put(AdminClientConfig.BOOTSTRAP_SERVER_CONFIG, "localhost:9092");
AdminClient admin = AdminClient.create(props);
...
admin.close(Duration.ofSeconds(30));
```

생성할 때 반드시 있어야 하는 설정은 클러스터에 대한 URI 하나뿐  
`close()` 메서드 역시 실행중인 작업이 완료될 때까지 기다리기 위해 타임아웃 매개변수 필요  

1. `client.dns.lookup`: DNS 별칠을 사용하거나 다수의 IP 주소로 연결되는 DNS 사용하는 경우
2. `request.timeout.ms`: 응답을 기다릴 수 있는 최대 시간 정의

<br>

## 필수적인 토픽 관리 기능

```java
ListTopicResult topics = admin.listTopics();
topics.names().get().forEach(System.out::println);
```

Future 객체를 반환하기 때문에 get 메서드 호출해서 조회 가능  

<br>

```java
DescribeTopicsResult demoTopic = admin.describeTopics(TOPIC_LIST);

try {
  topicDescription = demoTopic.values().get(TOPIC_NAME).get();
  if (topicDescription.partitions().size() != NUM_PARTITIONS) {
    System.out.println("Topic has wrong number of partitions. Exiting");
    System.exit(-1);
  }
} catch (ExecutionException e) {
  if (!(e.getCause() instanceof UnknowntopicOrPartitionException)) {
    e.printStack();
    throw e;
  }
  // 해당 구간부터는 토픽이 확실히 존재하지 않음
  CreateTopicResult newTopic = admin.createTopics(
    Collections.singletonList(new NewTopic(TOPIC_NAME, NUM_PARTITIONS, REP_FACTOR))
  );

  // 토픽 생성 확인
  if (newTopic.numPartitions(TOPIC_NAME).get() != NUM_PARTITIONS) {
    System.out.println("Topic has wrong number of partitions.");
    System.exit(-1);
  }
}
```

모든 AdminClient result 객체는 카프카가 에러 응답을 보내면 `ExecutionException` 발생  

<br>

```java
admin.deleteTopics(TOPIC_LIST).all().get();

// 비동기 작업이기 때문에 삭제 확인 필요
try {
  topicDescription = demoTopic.values().get(TOPIC_NAME).get();
  System.out.println("Topic " + TOPIC_NAME + " is still around");
} catch (ExecutionException e) {
  System.out.println("Topic " + TOPIC_NAME + " is gone");
}
```









