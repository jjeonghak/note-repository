# 카프카 컨슈머
데이터를 읽기 위해서 토픽을 구독하고 구독한 토픽들로부터 메시지를 받기 위해 카프카 컨슈머 사용  

<br>

## 카프카 컨슈머 개념

### 컨슈머와 컨슈머 그룹

<img width="600" height="300" alt="kafka_consumer_and_partition" src="https://github.com/user-attachments/assets/e803e33a-d330-4cd8-98ac-989b2bd8be3e" />

프로듀서의 메시지 전송 속도와 컨슈머의 메시지 처리 속도의 차이로부터 확장 가능  
여러 프로듀서가 동일 토픽에 메시지를 쓰듯이 여러 컨슈머가 같은 토픽으로부터 데이터 분할해서 읽기 가능  
동일한 컨슈머 그룹에 속한 여러 컨슈머들이 동일한 토픽을 구독할 경우 각각의 컨슈머는 서로 다른 파티션의 메시지 조회  
컨슈머 그룹에 컨슈머를 추가하는 것이 토픽에서 읽어오는 데이터 양을 확장하는 주된 방법  
이것이 토픽을 생성할 때 파티션 수를 크게 잡아주는 것이 좋은 이유  

<br>

<img width="600" height="400" alt="kafka_another_consumer_group" src="https://github.com/user-attachments/assets/3d634d6a-8182-4a5c-9bfc-5ec1d5ba1db0" />

동일한 토픽에 대해 새로운 컨슈머 그룹을 추가한 경우 각각의 컨슈머 그룹에 동일한 메시지 전달  
즉 용도에 따라 컨슈머 그룹을 분리해서 운용 가능  

<br>

### 컨슈머 그룹과 파티션 리밸런스
컨슈머 그룹에 속한 컨슈머들은 토픽의 파티션들에 대한 소유권을 공유  
새로운 컨슈머 추가시 이전의 다른 컨슈머가 읽고 있던 파티션으로부터 메시지를 읽기 시작  
오류 상황에서 기존 컨슈머가 나가면 잔류 컨슈머 중 하나가 대신 파티션을 받아서 읽기 시작  

<br>

파티션 재할당 작업은 컨슈머 그룹이 읽고 있는 토픽이 변경되었을 때도 발생  
컨슈머에 할당된 파티션을 다른 컨슈머에게 할당해주는 작업을 리밸런스라고 부름  
리밸런스에는 컨슈머 그룹이 사용하는 파티션 할당 전략에 따라 2가지로 구분  

<br>

### 1. 조급한 리밸런스  

<img width="700" height="300" alt="kafka_eager_rebalance" src="https://github.com/user-attachments/assets/3bd93e8e-6203-4cef-9b2c-67cc9845d33a" />

모든 컨슈머는 읽기 작업을 멈추고 자신에게 할당된 모든 파티션 소유권을 포기  
그 후 컨슈머 그룹에 다시 참여하여 완전히 새로운 파티션을 할당  
3.1 이전에는 기본값이었지만 현재는 삭제될 예정인 방식  

<br>

### 2. 협력적 리밸런스

<img width="700" height="300" alt="kafka_cooperative_rebalance" src="https://github.com/user-attachments/assets/e9c50b37-30d7-45bd-8eaf-f8fae3d46a40" />

한 컨슈머에게 할당되어 있던 파티션만 다른 컨슈머에 재할당  
재할당되지 않은 파티션에서 레코드를 읽어서 처리하던 컨슈머들은 작업에 방해받지 않음  
2개 이상의 단계에 걸쳐서 수행, 우선 컨슈머 그룹 리더가 다른 컨슈머에게 재할당 통보  
이후 컨슈머들은 해당 파티션에 대한 소유권 포기 후 파티션 재할당 진행  
컨슈머는 해당 컨슈머 그룹의 코디네이터 역할을 지정받은 카프카 브로커에 하트비트를 전송  

<br>

## 정적 그룹 멤버십
기본적으로 컨슈머 그룹의 멤버십은 일시적, 컨슈머가 그룹을 떠나는 순간 리밸런싱  
`group.instance.id` 설정을 통해서 컨슈머 그룹의 정적인 멤버로 지정하지 않는 경우에만 유효  
해당 설정을 통해 일시적인 컨슈머 장애에 대해 유휴 기간 동안 리밸런싱 방지  
정적 그룹 멤버십은 각 컨슈머가 파티션의 내용물을 사용해 로컬 상태나 캐시를 유지할 때 유용  
`session.timeout.ms` 설정을 통해 유휴 기간 설정 가능  

<br>

## 카프카 컨슈머 생성
반드시 지정해야만 하는 속성은 아래 3가지  
이외에도 필수는 아니지만 매우 일반적으로 사용되는 네번째 속성인 `group.id` 존재  
- `bootstrap.servers`
- `key.deserializer`
- `value.desecializer`

```java
Properties props = new Properties();
props.put("bootstrap.servers", "broker1:9092,broker2:9092");
props.put("group.id", "CountryCounter");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
KafkaConsumer<String, String> consumer = new KafkaConsumer<String, String>(props);
```

<br>

## 토픽 구독하기
컨슈머를 생성한 후에 1개 이상의 토픽 구독 필수  
정규식을 매개변수로 구독 가능, 정규식과 매치되는 이름을 가진 새로운 토픽 생성시 바로 구독 가능  
하지만 만약 토픽의 목록이 굉장히 많고 컨슈머도 굉장히 많은 경우 정규식을 사용한 구독은 상당한 오버헤드 발생  

```java
consumer.subscribe(Collections.singletonList("customerCountries"));
consumer.subscribe(Pattern.compile("test.*"));
```

<br>

## 폴링 루프
컨슈머 API의 핵심은 서버에 추가 데이터가 들어왔는지 폴링하는 단순한 루프  
새 컨슈머에서 처음으로 `poll()` 메서드를 호출하면 컨슈머는 코디네이터를 찾아서 컨슈머 그룹에 참가  
해당 메서드가 `max.poll.interval.ms` 설정 이상으로 호출되지 않는 경우 컨슈머가 죽은 것으로 판정  

```java
Duration timeout = Duration.ofMillis(100);

while (true) {
  ConsumerRecords<String, String> records = consumer.poll(timeout);
  for (ConsumerRecord<String, String> record : records) {
    System.out.printf(
      "topic = %s, partition = $d, offset = %d, customer = %s, value = %s\n",
      record.topic(), record.partition(), record.offset(), record.key(), record.value()
    );
    int updatedCount = 1;
    if (custValueMap.containsKey(record.value()))) {
      updatedCount = custValueMap.get(record.value()) + 1;
    }
    custValueMap.put(record.value(), updatedCount);
    JSONObject json = new JSONObject(custCountryMap);
    System.out.println(json.toString());
  }
}
```

<br>

### 스레드 안전성
하나의 스레드에서 동일한 그룹 내에 여러 개의 컨슈머 생성 불가  
같은 컨슈머를 다수의 스레드가 안전하게 사용하는 것도 불가, 하나의 스레드 당 하나의 컨슈머가 원칙  
애플리케이션에서 동일한 그룹에 속하는 여러 개의 컨슈머 운용은 다수의 스레드를 띄워 각각의 컨슈머를 운용  
또 다른 방법은 이벤트를 받아서 큐에 넣는 컨슈머 하나와 이벤트를 꺼내서 처리하는 여러 개의 워커 스레드를 사용하는 것  

<br>

## 컨슈머 설정
대부분의 매개변수는 합리적인 기본값을 보유  
몇몇 매개변수는 컨슈머의 성능과 가용성에 영향을 줌  

1. `fetch.min.bytes`: 레코드를 얻어올 때 받는 데이터의 최소량
2. `fetch.max.wait.ms`: 컨슈머에게 응답하기 전 충분한 데이터가 모일 때까지 기다리는 시간
3. `fetch.max.bytes`: 컨슈머가 브로커를 폴링할 때 카프카가 리턴하는 최대 바이트 수
4. `max.poll.records`: `poll()` 메서드 호출 때마다 리턴되는 최대 레코드 수
5. `max.partition.fetch.bytes`: 서버가 파티션별로 리턴하는 최대 바이트 수
6. `session.timeout.ms`: 신호를 주고받지 않고도 살아 있는 것으로 판전되는 최대 시간
7. `max.poll.interval.ms`: 컨슈머가 폴링을 하지 않고도 죽은 것으로 판정되지 않을 수 있는 최대 시간
8. `default.api.timeout.ms`: 컨슈머 API 호출에 적용되는 타임아웃 값
9. `request.timeout.ms`: 컨슈머가 브로커로부터 응답을 기다릴 수 있는 최대 시간
10. `auto.offset.reset`: 오프셋을 커밋한 적이 없거나 커밋된 오프셋이 유효하지 않는 경우 파티션 읽기 시작 작동 정의
11. `enable.auto.commit`: 컨슈머가 자동으로 오프셋을 커밋할지 여부 결정
12. `partition.assignment.strategy`: 컨슈머에게 어느 파티션이 할당될지 결정
13. `client.id`: 브로커가 요청을 보낸 클라이언트를 식별할때 사용하는 문자열
14. `client.rack`: 다수의 클라우드 가용 영역 중 컨슈머와 같은 영역에 있는 레플리카를 설정
15. `group.instance.id`: 정적 그룹 멤버십 기능을 적용하기 위해 사용하는 설정
16. `receive.buffer.bytes`: 소켓이 사용하는 TCP 수신 버퍼 크기
17. `offsets.retention.minutes`: 브로커 설정, 그룹이 비게된 경우 커밋된 오프셋을 보관하는 기간

<br>

## 오프셋과 커밋
컨슈머가 카프카를 사용해서 각 파티션에서의 위치를 추적 가능  
파티션에서 현재 위치를 업데이트하는 작업을 오프셋 커밋(`offset commit`)이라고 부름. 
전통적인 메시지 큐와 다르게 레코드를 개별적으로 커밋하지 않고 컨슈머는 파티션에서 성공적으로 처리해 낸 마지막 메시지를 커밋  
카프카에 특수 토픽인 `__consumer_offsets` 토픽에 각 파티션 별로 커밋된 오프셋을 업데이트하도록 메시지를 보냄  
오프셋 자동/수동 여부에 상관없이 `poll()` 메서드가 리턴한 마지막 오프셋 바로 다음 오프셋을 커밋하는 것이 기본적인 동작  

<br>

<img width="450" height="250" alt="kafka_consumer_duplication" src="https://github.com/user-attachments/assets/eacb66f6-3d05-4b5a-87b3-c19a5349469e" />

만약 커밋된 오프셋이 클라이언트가 이미 처리한 마지막 메시지 오프셋보다 작을 경우 중복 처리 발생  

<br>

<img width="450" height="250" alt="kafka_consumer_missing_message" src="https://github.com/user-attachments/assets/566b1c24-d1e0-45e7-8e1e-20747c3b8314" />

반대로 커밋된 오프셋이 클라언트가 처리한 마지막 메시지 오프셋보다 큰 경우 누락 발생

<br>

### 자동 커밋
오프셋을 커밋하는 가장 쉬운 방법인 컨슈머가 대신 커밋하는 것  
`enable.auto.commit=true` 설정을 통해 5초에 한 번, `poll()` 메서드를 통해 받은 마지막 메시지의 오프셋을 커밋  
5초는 기본값으로 `auto.commit.interval.ms` 설정으로 변경 가능  
해당 방식은 윈도우 크기에 따라 크래시 상황에서 중복이 발생 가능성이 존재, 완전히 중복을 없애는 것은 불가능  
또한 리턴된 모든 이벤트들이 다음 `poll()` 메서드 호출 전에 반드시 처리되어야 하는게 중요  

<br>

### 현재 오프셋 커밋
컨슈머 API는 타이머 시간이 아닌 애플리케이션 개발자가 원하는 시간에 현재 오프셋을 커밋하는 옵션 제공  
`enable.auto.commit=false` 설정을 통해 애플리케이션이 명시적으로 커밋하려 할 때만 오프셋 커밋 가능  
가장 신뢰성 있는 커밋 API는 `commitSync()`, 리턴한 마지막 오프셋을 커밋한 뒤 커밋이 성공적으로 완료되면 리턴 아니면 예외  
이 역시 리턴된 마지막 오프셋을 커밋하기 때문에 레코드를 받고 처리 완료 전에 크래시 상황이 발생하면 메시지 누락  

```java
Duration timeout = Duration.ofMillis(100);
while (true) {
  ConsumerRecords<String, String> records = consumer.poll(timeout);
  for (ConsumerRecord<String, String> record : records) {
    System.out.printf(
      "topic = %s, partition = %d, offset = %d, customer = %s, value = %s\n",
      record.topic(), record.partition(), record.offset(), record.key(), record.value()
    );
  }
  try {
    consumer.commitSync();
  } catch (CommitFailedException e) {
    log.error("commit failed", e);
  }
}
```

<br>

### 비동기적 커밋
수동 커밋의 단점 중 하나는 브로커가 커밋 요청을 응답하기 전까지 애플리케이션이 블록된다는 것  
덜 자주 커밋한다면 처리량이 올라가겠지만 리밸런스에 의해 발생하는 잠재적인 중복 메시지의 수는 늘어남  

```java
Duration timeout = Duration.ofMillis(100);
while (true) {
  ConsumerRecords<String, String> records = consumer.poll(timeout);
  for (ConsumerRecord<String, String> record : records) {
    System.out.printf(
      "topic = %s, partition = %d, offset = %d, customer = %s, value = %s\n",
      record.topic(), record.partition(), record.offset(), record.key(), record.value()
    );
  }
  consumer.commitAsync();
}
```

<br>

해당 방식의 단점은 동기 방식은 재시도를 하지만 비동기 방식은 재시도를 하지 않음  
서버로부터 응답을 받은 시점에는 이미 다른 커밋 시도가 성공했을 가능성이 있기 때문  
앞선 커밋이 실패했지만 이미 뒤이은 커밋이 성공해버리는 상황 발생 가능  
또한 콜백 지정을 통해 커밋 에러를 로깅하거나 커밋 에러 수를 지표 형태로 집계하는 것이 보통, 재시도 하지 않음  
만약 재시도를 원한다면 단조증가 번호를 콜백에 넣어서 현재 번호를 비교해서 같다면 재시도 가능  

```java
Duration timeout = Duration.ofMillis(100);
while (true) {
  ConsumerRecords<String, String> records = consumer.poll(timeout);
  for (ConsumerRecord<String, String> record : records) {
    System.out.printf(
      "topic = %s, partition = %d, offset = %d, customer = %s, value = %s\n",
      record.topic(), record.partition(), record.offset(), record.key(), record.value()
    );
  }
  consumer.commitAsync(new OffsetCommitCallback() {
    public void onComplete(Map<TopicPartition, OffsetAndMetadata> offsets, Exception e) {
      if (e != null) {
        log.error("Commit failed for offsets {}", offsets, e);
      }
    }
  });
}
```

<br>

### 동기적 커밋과 비동기적 커밋 동시 사용
보통 재시도 없는 커밋이 실패한다고 해서 큰 문제가 발생하지 않음  
일시적인 문제일 경우 뒤이은 커밋이 성공할 것이기 때문  
하지만 컨슈머를 닫기 전 혹은 리밸런스 전 마지막 커밋이라면 성공 여부 확인이 필요한 경우 존재  
이런 경우 일반적인 패턴은 종료 직전에 동기/비동기 커밋을 함께 사용하는 것  

```java
Duration timeout = Duration.ofMillis(100);
try {
  while (!closing) {
    ConsumerRecords<String, String> records = consumer.poll(timeout);
    for (ConsumerRecord<String, String> record : records) {
      System.out.printf(
        "topic = %s, partition = %d, offset = %d, customer = %s, value = %s\n",
        record.topic(), record.partition(), record.offset(), record.key(), record.value()
      );
    }
    consumer.commitAsync();    // 정상적인 상황에서는 비동기 커밋
  }
  consumer.commitSync();       // 컨슈머를 닫는 상황에서는 다음 커밋이 있을 수 없으므로 동기 커밋 및 재시도
} catch (Exception e) {
  log.error("Unexpected error", e);
} finally {
  consumer.close();
}
```

<br>

### 특정 오프셋 커밋
가장 최근 오프셋을 커밋하는 것은 메시지 배치의 처리가 끝난 이후에만 수행 가능  
큰 배치를 처리하는 도중에 오프셋을 커밋하고 싶은 경우 사용  

```java
private Map<TopicPartition, OffsetAndMetadata> currentOffsets = new HashMap<>();
int count = 0;

...

Duration timeout = Duration.ofMillis(100);
while (true) {
  ConsumerRecords<String, String> records = consumer.poll(timeout);
  for (ConsumerRecord<String, String> record : records) {
    System.out.printf(
      "topic = %s, partition = %d, offset = %d, customer = %s, value = %s\n",
      record.topic(), record.partition(), record.offset(), record.key(), record.value()
    );
    currentOffsets.put(
      new TopicPartition(record.topic(), record.partition()),
      new OffsetAndMetadata(record.offset() + 1, "no metadata"    // 향후에 읽기 시작할 메시지 위치
    );
    if (count % 1000 == 0) {      // 1000개의 레코드마다 현재 오프셋을 커밋
      consumer.commitAsync(currentOffsets, null);
    }
    count++;
  }
}
```

<br>

## 리밸런스 리스너
컨슈머는 종료되기 전이나 리밸런싱이 시작되기 전에 정리 작업 필수  
파티션이 해제될 것이라는 걸 알게 된다면 해장 파티션에서 마지막으로 처리한 이벤트의 오프셋 커밋 필수  
`subscribe()` 메서드를 호출할 때 ConsumerRebalanceListener 리밸런스 리스터 전달 가능  

```java
public interface ConsumerRebalanceListner {
  // 컨슈머에게 파티션 재할당 후 컨슈머가 메시지를 읽기 시작하기 전에 호출
  // 리밸런스가 발생했음을 컨슈머에게 알려주는 역할, 새롭게 할당된 파티션이 없는 경우 빈 목록과 함게 호출
  public void onPartitionsAssigned(Collection<TopicPartition> partitions);

  // 컨슈머가 할당받았던 파티션이 할당 해제될 때 호출
  // 메서드가 호출될 때 빈 목록이 주어지는 경우는 없음
  public void onPartitionsRevoked(Collection<TopicPartition> partitions);

  // 협력적 리밸런스 알고리즘이 사용되었을 경우 해제되기 전에 다른 컨슈머에 먼저 할당된 예외적인 상황에서만 호출
  // 메서드가 호출되는 시점에서 이미 다른 컨슈머들에게 할당되어 있는 상태
  default void onPartitionsLost(Collection<TopicPartition> partitions) {
    onPartitionsRevoked(partitions);
  }
}
```

```java
private Map<TopicPartition, OffsetAndMetadata> currentOffsets = new HashMap<>();
Duration timeout = Duration.ofMillis(100);

private class HandleRebalance implements ConsumerRebalanceListener {
  public void onPartitionsAssigned(Collection<TopicPartition> partitions) {}
  public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
    System.out.println("Lost partitions in rebalance. Committing current offsets:" + currentOffsets);
    consumer.commitSync(currentOffsets);
  }
}

try {
  consumer.subscribe(topics, new HandleRebalance());
  ...
} catch (WakeupException ignore) {
} catch (Exception e) {
  log.error("Unexpected error", e);
} finally {
  consumer.close();
  System.out.println("Closed consumer and we are done");
}
```

<br>

## 특정 오프셋 레코드 조회
각 파티션의 마지막 커밋 오프셋이 아닌 특정 오프셋부터 읽기 기능 지원  
맨 앞에서부터 모든 메시지를 읽거나 전부 건너뛰고 맨 마지막 메시지부터 읽고 싶은 경우 `seekToBdgining`, `seekToEnd` 사용  

```java
Long oneHourEarlier = Instant.now().atZone(ZoneId.systemDefault()).minusHour(1).toEpochSecond();
Map<TopicPartition, Long> partitionTimestampMap = consumer.assignment()
  .stream()
  .collect(Collectors.toMap(tp -> tp, tp -> oneHourEalier));  // 컨슈머에 할당된 모든 파티션에 대해 되돌리고자 하는 타임스탬프 값
Map<TopicPartition, OffsetAndTimestamp> offsetMap = consumer.offsetsForTimes(partitionTimestampMap); // 실제 오프셋
for(Map.Entry<TopicPartition, OffsetAndTimestamp> entry : offsetMap.entrySet()) {
  consumer.seek(entry.getKey(), entry.getValue().offset());
}
```

<br>

## 폴링 루프 종료
컨슈머를 종료하고자 할 때 컨슈머가 `poll()` 메서드를 대기하고 있더라도 다른 스레드로 `consumer.wakeup()` 호출하면 탈출 가능  
해당 메서드 호출시 대기중인 `poll()` 메서드는 `WakeupException` 예외 발생시키며 중단  
컨슈머를 닫으면 오프셋을 커밋하고 그룹 코디네이터에게 컨슈머 그룹을 떠난다는 메시지 전송  

```java
Runtime.getRuntime().addShutdownHook(new Thread() {
  public void run() {
    System.out.println("Starting exit ...");
    consumer.wakeup();
    try {
      mainThread.join();
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
});
```

<br>

## 디시리얼라이저
직렬화와 역직렬화는 동전의 양면, 어차피 함께 쓰이기 때문에 같은 데이터 타입에 대해 같이 묶어 놓은 클래스 존재  
Avro 또한 시리얼라이저와 디시리얼라이저 둘 다 사용 가능  

<br>

### 커스텀 디시리얼라이저

```java
public class Customer {
  private int customerID;
  private String customerName;

  public Customer(int ID, String name) {
    this.customerID = ID;
    this.customerName = name;
  }

  public int getID() {
    return customerID;
  }

  public String getName() {
    return customerName;
  }
}
```

```java
public class CustomerDeserializer implements Deserializer<Customer> {
  @Override
  public void configure(Map configs, boolean isKey) {}

  @Override
  public Customer deserialize(String topic, byte[] data) {
    int id;
    int nameSize;
    String name;

    try {
      if (data == null) {
        return null;
      }
      if (data.length < 8) {
        throw new SerializationException("Size of data received by deserializer is shorter than expected");
      }
      ByteBuffer buffer = ByteBuffer.wrap(data);
      id = buffer.getInt();
      nameSize() = buffer.getInt();

      byte[] nameBytes = new byte[nameSize];
      buffer.get(nameBytes);
      name = new String(nameByte, "UTF-8");

      return new Customer(id, name);
    } catch (Exception e) {
      throw new SerializationException("Error when deserializing byte[] to Customer" + e);
    }
  }

  @Override
  public void close() {}
}
```

<br>

### Avro 디시리얼라이저

```java
Duration duration = Duration.ofMillis(100);
Properties props = new Properties();
props.put("bootstrap.servers", "broker1:9092,broker2:9092");
props.put("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer");
props.put("value.deserializer", "io.confluent.kafka.serializaers.KafkaAvroDeserializer");
props.put("specific.avro.reader", "true");
props.put("schema.registry.url", schemaUrl);
KafkaConsumer<String, Customer> consumer = new KafkaConsumer<>(props);
consumer.subscribe(Collections.singletonList("customerContacts"));
```


































