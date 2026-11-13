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

토픽 삭제는 돌이킬 수 없는 동작, 해당 토픽이 비어있는지 확인하는 절차도 없음  

<br>

```java
vertx.createHttpServer().requestHandler(request -> {
  String topic = request.getParam("topic");
  String timeout = request.getParam("timeout");
  int timeoutMs = NumberUtils.toInt(timeout, 1000);

  DescribeTopicsResult demoTopic = admin.describeTopics(
    Collections.singletonList(topic), new DescribeTopicsOptions().timeoutMs(timeoutMs)
  );

  // 비동기적 처리
  demoTopic.values().get(topic).wehnComplete((final TopicDescription td, final Throwable t) -> {
      if (t != null) {
        request.response().end("Error trying to describe topic " + topic + " due to " + t.getMessage());
      } else {
        request.response().end(td.toString());
      }
  });
}).listen(8080);
```

Future 객체의 결과를 블로킹해서 가져오는 방식이 아닌 비동기적인 방식을 원한다면 `KafkaFuture` 사용  

<br>

## 설정 관리
설정 가능한 자원에는 브로커, 브로커 로그, 토픽이 존재하며 `ConfigResource` 객체를 사용  

```java
ConfigResource configResource = new ConfigResource(ConfigResource.Type.TOPIC, TOPIC_NAME);
DescribeConfigResult configResult = admin.describeConfigs(Collections.singleton(configResource));
Config configs = configsResult.all().get().get(configResource);

// 기본값이 아닌 설정을 출력
configs.entries().stream().filter(e -> !e.isDefault()).forEach(System.out::println);

// 토픽에 압착 설정이 되어 있는지 확인
ConfigEntry compaction = new ConfigEntry(TopicConfig.CLEANUP_POLICY_CONFIG, TopicConfig.CLEANUP_POLICY_COMPACT);
if (!config.entrues().contains(compaction)) {
  Collection<AlterConfigOp> configOp = new ArrayList<AlterConfigOp>();
  configOp.add(new AlterconfigOp(compaction, AlterconfigOp.OpType.SET));
  Map<ConfigResource, Collection<AlterConfigOp>> alterConf = new HashMap<>();
  alterConf.put(configResource, configOp);
  admin.incrementalAlterConfigs(alterConf).all().get();
} else {
  System.out.println("Topic " + TOPIC_NAME + " is compacted topic");
}
```

<br>

## 컨슈머 그룹 관리
컨슈머 API를 사용해서 처리 지점을 되돌려 재처리 가능하지만 이러한 기능 자체가 애플리케이션에 재처리 기능 구현 필수  
설령 애플리케이션에 해당 기능이 없더라도 사고 발생 후 재해 복구 상황 또한 재처리에 해당  
AdminClient 객체를 사용해서 프로그램적으로 컨슈머 그룹과 커밋한 오프셋을 조회하고 수정하는 방법 존재  

<br>

### 컨슈머 그룹 조회

```java
admin.listConsumerGroups().valid().get().forEach(System.out::println);
```

가장 먼저 해야 할 일은 컨슈머 그룹의 목록을 조회하는 것  

<br>

```java
ConsumerGroupDescription groupDescription = admin
  .describeConsumerGroups(CONSUMER_GRP_LIST)
  .describeGroups().get(CONSUMER_GROUP).get();
System.out.println("Description of group " + CONSUMER_GROUP + ":" + groupDescription);
```

특정 그룹에 대한 더 상세한 정보를 조회할 때 사용  
여기에는 그룹 멤버, 멤버별 식별자, 호스트명, 할당된 파티션, 할당 알고리즘, 그룹 코디네이터 호스트명이 포함  

<br>

```java
// 브로커의 내부 토픽(__consumer_offsets)에서 해당 컨슈머 그룹이 각 파티션별로 마지막으로 커밋한 오프셋 정보 조회
Map<TopicPartition, OffsetAndMetadata> offsets = admin
  .listConsumerGroupOffsets(CONSUMER_GROUP)
  .partitionsToOffsetsAndMetadata().get();

// 아직 브로커와 통신하지 않고, 어떤 파티션의 어떤 위치(최신/가장오래된/특정시간)를 조회할지 조건만 담는 빈 Map
Map<TopicPartition, OffsetSpec> requestLatestOffsets = new HashMap<>();

// 컨슈머 그룹이 구독 중인 모든 파티션 목록을 순회하면서 조회 요청서 생성
for (TopicPartition tp : offsets.keySet()) {
  // OffsetSpec.latest()는 실제 오프셋 숫자를 가진 게 아니라 단순한 조회 옵션 객체이므로 재사용해도 무방
  requestLatestOffsets.put(tp, OffsetSpec.latest());
}

// 브로커는 요청서의 각 파티션마다 OffsetSpec.latest() 지시를 확인한 후에 해당하는 오프셋 번호를 찾아 응답
Map<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> latestOffsets = admin
  .listOffsets(requestLatestOffsets).all().get();

for (Map.Entry<TopicPartition, OffsetAndMetadata> e : offsets.entrySet()) {
  String topic = e.getKey().topic();
  int partition = e.getKey().partition();

  // 두 값의 차이가 컨슈머가 아직 못 읽고 밀려있는 메시지 수(Consumer Lag)
  long committedOffset = e.getValue().offset();
  long latestOffset = latestOffsets.get(e.getKey()).offset();
}
```

과거에는 각 파티션에 대한 마지막 커밋된 오프셋은 내부 토픽에 쓴 커밋 메시지를 가져와서 파싱하는 방식 사용  
내부 메시지 형식의 호환성 같은 것에 대해 아무런 보장을 하지 않아서 권장되지 않고 위의 AdminClient 사용하는 방식 권장  

<br>

### 컨슈머 그룹 수정
AdminClient는 컨슈머 그룹을 수정하기 위한 메서드 보유(그룹 삭제, 커밋 오프셋 삭제 또는 변경 등)  
오프셋을 삭제하면 컨슈머는 `auto.offset.reset` 설정에 의존해서 동작(맨 앞부터 읽기, 가장 마지막 최신부터 읽기)  
컨슈머 그룹은 컨슈머가 새로운 파티션을 할당받거나 새로 시작할 때만 오프셋 토픽에 저장된 값을 조회  
컨슈머가 모르는 으포셋 변경을 방지하기 위해 카프카는 현재 작업중인 컨슈머 그룹에 대한 오프셋 수정을 허용하지 않음  

```java
Map<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> earliestOffsets = admin
  .listOffsets(requestEarliestOffsets).all().get();

Map<TopicPartition, OffsetAndMetadata> resetOffsets = new HashMap<>();
for (Map.Entry<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> e : earliestOffsets.entrySet()) {
  resetOffsets.put(e.getKey(), new OffsetAndMetadata(e.getValue().offset()));
}

try {
  admin.alterConsumerGroupOffsets(CONSUMER_GROUP, resetOffsets).all().get();
} catch (ExecitionException e) {
  if (e.getCause() instanceof UnknownMemberIdException) {
    System.out.println("Check if consumer group is still active.");
  }
}
```

<br>

## 고급 어드민 작업
사고 대응중에 매우 중요하지만 잘 쓰이지 않는 기능  

<br>

### 토픽 파티션 추가
대체로 토픽의 파티션 수는 토픽이 생성될 때 결정되는 것이 보통  
같은 키를 가진 메시지들이 동일한 파티션에서 동일한 순서로 처리될 것을 기대하기 때문에 사용이 드물며 위험 부담 존재  
때때호 파티션이 처리할 수 있는 최대 처리량까지 부하가 차올라 파티션 추가 외에는 선택지가 없는 경우 사용  

```java
// 파티션 추가는 추가된 갯수가 아닌 추가 후 최종 갯수 지정
Map<String, NewPartitions> newPartitions = new HashMap<>();
newPartitions.put(TOPIC_NAME, NewPartitions.increaseTo(NUM_PARTITIONS + 2));
admin.createPartitions(newPartitions).all().get();
```

<br>

### 토픽 레코드 삭제
카프카는 토픽에 대해 데이터 보존 정책을 설정할 수 있지만 법적인 요구 조건을 보장할 수준의 기능은 아님  
`deleteRecords` 메서드는 호출 시점을 기준으로 지정된 오프셋보다 오래된 모든 레코드를 삭제 표시  
삭제 표시된 레코드를 디스크에서 실제로 지우는 작업은 비동기적으로 실행, 대신 삭제 표시된 레코드는 컨슈머가 접근 불가  
삭제된 레코드의 오프셋 중 가장 큰 값을 리턴하기 때문에 의도했던 대로 동작했는지 확인 가능  

```java
Map<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> olderOffsets = admin
  .listOffsets(requestOlderOffsets).all().get();
Map<TopicPartition, RecordsToDelete> recordsToDelete = new HashMap<>();
for (Map.Entry<TopicPartition, ListOffsetsResult.ListOffsetsResultInfo> e : olderOffsets.entrySet()) {
  recordsToDelete.put(e.getKey(), RecordsToDelete.beforeOffsets(e.getValue().offset()));
}
admin.deleteRecords(recordsToDelete).all().get();
```

<br>

### 리더 선출
해당 메서드는 두가지 서로 다른 형태의 리터 선출 가능  
1. 선호 리더 선출: 각 파티션은 선호 리더라 불리는 레플리카를 하나씩 보유
2. 언클린 리더 선출: 리더가 될 수 없는 레플리카를 그냥 리더로 삼아버리는 방식

<br>

```java
Set<TopicPartition> electableTopics = new HashSet<>();
electableTopics.add(new TopicPartition(TOPIC_NAME, 0));
try {
  admin.electLeaders(ElectionType.PREFERRED, electableTopics).all().get();
} catch (ExecutionException e) {
  if (e.getCause() instanceof ElectionNotNeededException) {
    System.out.println("All leaders are preferred already");
  }
}
```

해당 메서드 또한 비동기적으로 작동
선호 리더가 아닌 레플리카가 현재 리더를 맡고 있는 경우에만 수행  

<br>

### 레플리카 재할당
`alterPartitionReassignments`를 사용하면 파티션에 속한 각각의 레플리카의 위치를 정밀하게 제어 가능  
레플리카를 다른 브로커로 재할당하는 것은 브로커 간에 대량의 데이터 복제를 초래  

```java
Map<TopicPartition, Optional<NewPartitionReassignment>> reassignment = new HashMap<>();
reassignment.put(
  new TopicPartition(TOPIC_NAME, 0), Optional.of(new NewPartitionReassignment(Arrays.asList(0, 1)))
);
reassignment.put(
  new TopicPartition(TOPIC_NAME, 1), Optional.of(new NewPartitionReassignment(Arrays.asList(1)))
);
reassignment.put(
  new TopicPartition(TOPIC_NAME, 2), Optional.of(new NewPartitionReassignment(Arrays.asList(1, 0)))
);
reassignment.put(new TopicPartition(TOPIC_NAME, 3), Optional.empty());
admin.alterPartitionReassignments(reassignment).all().get();

demoTopic = admin.describeTopics(TOPIC_LIST);
topicDescription = demoTopic.values().get(TOPIC_NAME).get();
```

<br>

## 테스트
원하는 수만큼 브로커를 설정하고 초기화 가능한 `MockAdminClient` 테스트 클래스 제공  
카프카 API 일부가 아닌 만큼 사전 경고 없이 변경 가능하지만 편리함  

```java
public TopicCreator(AdminClient admin) {
  this.admin = admin;
}

public void maybeCreateTopic(String topicName) throws ExecutionException, InterruptedException {
  Collection<NewTopic> topics = new ArrayList<>();
  topics.add(new NewTopic(topicName, 1, (short) 1));
  if (topicName.toLowerCase().startsWith("test")) {
    admin.createTopics(topics);
    ConfigResource configResource = new ConfigResource.Type.TOPIC, topicName);
    ConfigEntry compaction = new ConfigEntry(TopicConfig.CLEANUP_POLICY_COMPACT);
    Collection<AlterConfigOp> configOp = new ArrayList<AlterConfigOp>();
    configOp.add(new AlterConfigOp(compaction, AlterConfigOp.OpType.SET));
    Map<ConfigResource, Collection<AlterConfigOp>> alterConf = new HashMap<>();
    alterConf.put(configResource, configOp);
    admin.incrementalAlterConfigs(alterConf).all().get();
  }
}
```

```java
@Before
public void setUp() {
  Node broker = new Node(0, "localhost", 9092);
  MockAdminClient adminClient = new MockAdminClient(Collections.singletonList(broker), broker);
  this.admin = spy(adminClient);

  AlterConfigsResult emptyResult = mock(AlterConfigsResult.class);
  doReturn(KafkaFuture.completedFuture(null)).when(emptyResult).all();
  doReturn(emptyResult).when(admin).incrementalAlterconfigs(any());
}
```

```java
@Test
public void testCreateTestTopic() throws ExecutionException, InterruptedException {
  TopicCreator tc = new TopicCreator(admin);
  tc.maybeCreateTopic("test.is.a.test.topic");
  verigfy(admin, times(1)).createTopics(any());
}

@Test
public void testNotTopic() throws ExecutionException, InterruptedException {
  TopicCreator tc = new TopicCreator(admin);
  tc.maybeCreateTopic("not.a.test");
  verify(admin, never()).createTopics(any());
}
```

<br>
