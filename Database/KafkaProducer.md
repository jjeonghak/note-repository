# 카프카 프로듀서
카프카를 사용할 때는 카프카에 데이터를 쓸 때 사용하는 프로듀서나 읽어 올 때 사용하는 컨슈머 생성 필수  

<br>

## 프로듀서 개요

<img width="600" height="600" alt="kafka_producer" src="https://github.com/user-attachments/assets/e019a65e-2efa-4392-8f81-c42c4d48dee9" />

메시지를 쓰는 작업은 ProducerRecord 객체를 생성함으로 시작  
레코드가 저장될 토픽과 밸류 지정은 필수지만 키와 파티션 지정은 선택사항  
프로듀서가 메시지를 보낼 때 가장 먼저 하는 것은 키와 값 객체를 직렬화해서 바이트 배열로 변환하는 것  
파티션을 명시적으로 지정하지 않은 경우 해당 데이터를 파티셔너에게 전송  
브로커가 메시지를 받고 성공적으로 처리하면 토픽, 파티션, 레코드 오프셋을 담은 RecordMetadata 객체를 리턴  

<br>

## 카프카 프로듀서 생성
메시지를 쓰기 위해서 원하는 필수 속성 지정 후 프로듀서 객체 생성  
- `boostrap.servers`: 카프카 클러스터와 첫 연결을 생성하기 위해 프로듀서가 사용할 브로커의 `host:port` 목록
- `key.serializer`: 레코드의 키 값을 직렬화하기 위해 사용하는 시리얼라이저 클래스의 이름
- `value.serializer`: 레코드의 밸류값을 직렬화하기 위해 사용하는 시리얼라이저 클래스의 이름

```java
Properties kafkaProps = new Properties();
kafkaProps.put("bootstrap.servers", "brokder1:9092,brokder2:9092");

kafkaProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
kafkaProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

KafkaProducer<String, String> producer = new KafkaProducer<String, String>(kafkaProps);
```

<br>

프로듀서 객체를 생성한 후 메시지 전송 방법은 아래 세가지 존재
- `Fire and forget`: 메시지를 서버에 전송만 하고 결과에는 신경 쓰지 않음
- `Synchronous send`: 기본적으로 프로듀서는 비동기적으로 작동하지만 `Future` 객체를 받아서 `get()` 메서드를 호출하는 방식
- `Asynchronous send`: 콜백 함수와 함께 `send()` 메서드를 호출

<br>

## 메시지 전달

### Fire and forget

```java
ProducerRecord<String, String> record = new ProducerRecord<>("CustomerCountry", "Precision Products", "France");
try {
  producer.send(record);
} catch (Exception e) {
  e.printStackTrace();
}
```

<br>

### 동기적 전송

```java
ProducerRecord<String, String> record = new ProducerRecord<>("CustomerCountry", "Precision Products", "France");
try {
  producer.send(record).get();
} catch (Exception e) {
  e.printStackTrace();
}
```

<br>

### 비동기적 전송

```java
private class DemoProducerCallback implements Callback {
  @Override
  public void onCompletion(RecordMetadata recordMetadata, Exception e) {
    if (e != null) {
      e.printStackTrace();
    }
  }
]

ProducerRecord<String, String> record = new ProducerRecord<>("CustomerCountry", "Precision Products", "France");
producer.send(record, new DemoProducerCallback());
```

<br>

## 프로듀서 설정
수많은 설정값이 대부분 합리적인 기본값을 가지고 있기 때문에 몇몇 설정값만 주의
- `client.id`: 프로듀서가 보내온 메시지를 서로 구분하기 위해 사용하는 논리적 식별자
- `acks`: 쓰기 작업 성공 판단을 위해 얼마나 많은 파티션 레플리카가 해당 레코드를 받아야 하는지 결정

<br>

### 메시지 전달 시간

<img width="600" height="300" alt="kafka_producer_message_receive_step" src="https://github.com/user-attachments/assets/9a11728e-1c1a-49b9-a106-fbdfb71fb3fa" />

- `max.block.ms`: 프로듀서가 블록되있는 시간 결정
- `delivery.timeout.ms`: 레코드가 배치에 저장된 시점부터 브로커의 응답을 받는 시점까지 제한시간 결정
- `request.timeout.ms`: 프로듀서가 데이터를 전송할 때 서버로부터 응답을 받기 위해 얼마나 기다릴 것인지 결정
- `retries`, `retry.backoff.ms`: 일시적인 에러일 경우 재전송하는 횟수 결정

<br>

- `linger.ms`: 현재 배치를 전송하기 전까지 대기하는 시간
- `buffer.memory`: 메시지 전송하기 전에 메시지를 대기시키는 버퍼 크기 결정
- `compression.type`: 기본적으로 메시지는 압축되지 않은 상태로 전송하지만 압축 알고리즘 설정 가능
- `batch.size`: 같은 파티션에 다수의 레코드가 전송될 경우 프로듀서는 배치 단위로 모아서 한꺼번에 전송
- `max.in.flight.requests.per.connection`: 서버로부터 응답을 받지 못한 상태에서 전송 가능한 최대 메시지 수 결정
- `max.request.size`: 프로듀서가 전송하는 쓰기 요청의 크기를 결정
- `receive.buffer.bytes`, `send.buffer.bytes`: 소켓이 사용하는 TCP 송수신 버퍼의 크기를 결정
- `enable.idempotence`: exactly once 구조를 지원, 멱등적 프로듀서 기능 활성화

<br>

`enable.idempotence=true` 설정은 프로듀서가 레코드를 보낼 때마다 순차적인 번호를 붙여서 보냄  
브로커가 재시도로 인한 동일한 번호를 가진 레코드를 2개 이상 받을 경우 하나만 저장  
멱등적 프로듀서 기능을 활성화하기 위해서는 아래 설정이 추가로 필요, 설정하지 않은 경우 `ConfigException` 발생  
- `max.in.flight.requests.per.connection` 매개변수 5 이하
- `retries` 1 이상
- `acks=all`

<br>

## 시리얼라이저
카프카는 정수값을 직렬화할 때 사용하는 시리얼라이저 뿐만 아니라 바이트배열에 사용되는 시리얼라이저 등을 포함  
하지만 이것만으로 모든 데이터를 직렬화 불가, 더 일반적인 레코드 직렬화 방법 필요  
권장되는 대안으로는 아파치 에이브로 시리얼라이저 존재  

<br>

### 커스텀 시리얼라이저
카프카로 전송해야 하는 객체가 단순한 문자열이나 정수값이 아닌 경우 두 가지 방법 존재
1. 레코드 생성을 위해 에이브로, 스리프트, 프로토버프와 같은 범용 직렬화 라이브러리 사용
2. 사용하고 있는 객체 직렬화를 위한 커스텀 직렬화 로직 작성

<br>

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
public class CustomerSerializer implements Serializer<Customer> {
  @Override
  public void configure(Map configs, boolean isKey) {
    // nothing to configure
  }

  @Override
  public byte[] serialize(String topic, Customer data) {
    try {
      byte[] serializedName;
      int stringSize;
      if (data == null) {
        return null;
      } else {
        if (data.getName() != null) {
          serializedName = data.getName().getBytes("UTF-8");
          stringSize = serializedName.length;
        } else {
          serializedName = new byte[0];
          stringSize = 0;
        }
      }
      ByteBuffer buffer = ByteBuffer.allocate(4 + 4 + stringSize);
      buffer.putInt(data.getID());
      buffer.putInt(stringSize);
      buffer.put(serializedName);
      return buffer.array();
    } catch (Exception e) {
      throw new SerializationException("Error when serializing Customer to bypte[] " + e);
    }
  }

  @Override
  public void close() {
    // nothing to close
  }
}
```

해당 커스텀 방식은 객체의 필드가 추가되거나 변경되면 호환성을 유지해야 하는 심각한 문제 발생  
이러한 이유로 범용 라이브러리를 사용할 것을 권장  

<br>

### 아파치 에이브로 직렬화
아파치 에이브로는 언어 중립적인 데이터 직렬화 형식, 스키마 형태로 기술  
직렬화된 결과물이 저장된 파일을 읽거나 직렬화를 할 때 스키마 정보가 별도로 주어진다고 가정  
메시지를 쓰는 애플리케이션이 새로운 스키마로 전환하더라도 기존 스키마와 호환성을 유지  
즉 데이터를 읽는 쪽 애플리케이션을 전부 변경하지 않고 스키마를 변경해도 예외나 에러 없이 null 반환  

<br>

### 카프카 에이브로 레코드 사용

<img width="600" height="300" alt="kafka_avro_record" src="https://github.com/user-attachments/assets/a7290702-643c-4700-bbf9-357134935319" />

파일 안에 전체 스키마를 저장함으로써 약간의 오버헤드를 감수하는 에이브로 파일과는 차이점 존재  
카프카 레코드에 전체 스키마를 저장할 경우 전체 레코드 사이즈는 2배 이상될 가능성 존재  
하지만 에이브로는 레코드를 읽을 때 스키마 전체를 필요로 하기 때문에 스키마 저장이 필수  
카프카는 직접 스키마를 저장하는 방식이 아닌 스키마 레지스트리 패턴을 사용

<br>

```java
Properties props = new Properties();

props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "io.confluent.kafka.serializers.KafkaAvroSerializer");
props.put("value.serializer", "io.confluent.kafka.serializers.KafkaAvroSerializer");
props.put("schema.registry.url", schemaUrl);

String topic = "customerContacts";

Producer<String, Customer> producer = new KafkaProducer<>(props);
```

여기서 메시지로 사용한 객체는 일반적인 자바 클래스가 아닌 에이브로 코드 생성 기능을 사용한 특화 객체  
에이브로 시리얼라이저는 오직 에이브로 객체만을 직렬화 가능  
에이브로 클래스를 생성하는 것은 `avro-tools.jar` 또는 에이브로 메이븐 플러그인  

<br>

```java
props.put("bootstrap.servers", "localhost:9092");
props.put("key.serializer", "io.confluent.kafka.serializers.KafkaAvroSerializer");
props.put("value.serializer", "io.confluent.kafka.serializers.KafkaAvroSerializer");
props.put("schema.registry.url", schemaUrl);

String schemaString =
  "{\"namespace\": \"customerManagement.avro\", " +
  "\"type\": \"record\", " +
  "\"name\": \"Customer\", " +
  "\"fields\": [" +
  "{\"name\": \"id\", \"type\": \"int\"}, " +
  "{\"name\": \"name\", \"type\": \"string\"}, " +
  "{\"name\": \"email\", \"type\": [\"null\",\"string\"], \"default\":\"null\"}" +
  "]}";
Producer<String, GenericRecord> producer = new KafkaProducer<>(props);

Schema.Parser parser = new Schema.Parser();
Schema schema = parser.parse(schemaString);

GenericRecord customer = new GenericData.Record(schema);
customer.put("id", 1);
customer.put("name", "exampleCustomer");
customer.put("email", "example@google.com");

ProducerRecord<String, GenericRecord> data = new ProducerRecord<>("customerContacts", "exampleCustomer", customer);
producer.send(data);
```

에이브로를 사용하면 키-값 형태로 사용 가능한 제네릭 에이브로 객체 역시 사용 가능  
제네릭 에이브로 객체를 사용하려면 위와 같이 스키마 지정 필수  

<br>

## 파티션
ProducerRecord 객체는 토픽, 키, 밸류 값을 포함  
키의 기본값이 null이기 때문에 토픽과 밸류 값만 있어서 객체 생성 가능  
하지만 대부분의 경우 키 값이 지정된 객체를 사용, 같은 키 값을 가진 모든 메시지는 같은 파티션에 저장  
기본 파티셔너 사용 중 키 값이 null인 레코드는 현재 사용 가능한 토픽의 파티션 중 랜덤하게 저장  



























