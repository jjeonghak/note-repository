## collection
Observale&lt;T&gt;와 Iterable&lt;T&gt;는 쌍대(dual)  
기존 API 손상 및 시스템 호환성에 문제 발생 우려가 있으므로 이른 시점에 도입 권장  

````java
class PersonDao {
    List<Person> listPeople() {
        return query("SELECT * FROM PEOPLE");
    }

    private List<Person> query(String sql) {
        ...
    }
}

Observable<Person> listPeople() {
    final List<Person> people = query("SELECT * FROM PEOPLE");
    return Observale.from(people);
}
````

<br>

## 블로킹
블로킹 및 명령형 방식의 기존 코드에 결합할때는 Observable 객체를 평범한 컬렉션으로 변환 필요  
Observable 완료까지 블로킹 처리  
BlockingObservable을 사용, 블로킹 코드와 논블로킹 코드 결합에 불가피한 선택  
Observable 완료까지 BlockingObservable 연산자는 블록  

````java
Observable<Person> peopleStream = personDao.listPeople();
Observable<List<Person>> peopleList = peopleStream.toList();
BlockingObservable<List<Person>> peopleBlocking = peopleList.toBlocking();
List<Person> people = peopleBlocking.single();
````

<br>

## 느긋함 포용
조급한 Observable을 defer() 메서드로 포장  
defer() 메서드는 구독되기 전까지 대기, Observable 실제 생성을 늦춤  

````java
public Observable<Person> listPeople() {
    return Observable.defer(() -> Observabel.from(query("SELECT * FROM PEOPLE")));
}
````

<br>

### 기존 코드
````java
void bestBookFor(Person person) {
    Book book;
    try {
        book = recommend(person);
    } catch (Exception e) {
        book = bestSeller();
    }
    display(book.getTitle());
}
````

<br>

### RxJava 적용
````java
    void bestBookFor(Person person) {
        recommend(person)
            .onErrorResumeNext(bestSeller())
            .map(Book::getTitle)
            .subscribe(this::display);
    }
````

<br>

### 데이터를 덩어리로 나눠 느긋하게 불러오는 기법은 무척 유용
````java
List<Person> listPeople(int page) {
    return query("SELECT * FROM PEOPLE ORDER BY id LIMIT ? OFFSET ?",
        PAGE_SIZE, page * PAGE_SIZE);
}
````

<br>

### StackOverflowError 발생 가능성 있지만 구독 취소시 재귀 중단
````java
Observable<Person> allPeople(int initialPage) {
    return defer(() -> from(listPeople(inititalPage)))
        .concatWith(defer(() -> allPeople(initialPage + 1)));  
}
````

<br>

## 느긋한 페이지 분할 및 연결
전부를 가져온 후 원하는 만큼 취하는 것  
어리석어 보이지만 느긋함 덕분에 실현 가능  

````java
Observable<List<Person>> allPages = Observable
    .range(0, Integer.MAX_VALUE)
    .map(this::listPeople)
    .takeWhile(list -> !list.isEmpty);
Observable<Person> people = allPages.concatMap(Observable::from);
Observable<Person> people = allPages.concatMapIterable(Observable::from)  //Iterable<Person>
people.take(15);  //원하는 레코드 갯수 제한
````

<br>

## 명령형 방식의 동시성
대부분 스레드 하나가 요청 하나 처리  
톰캣은 요청 처리 스레드 갯수 default 200  
요청이 짧은 시간 몰리면 연결을 대기열에 보관, 지속되는 경우 연결 거부  

1. TCP/IP 연결  
2. HTTP 요청 해석  
3. 컨트롤러 혹은 서블릿 호출  
4. 데이터베이스 요청 및 블로킹  
5. 결과 처리  
6. 결과값 인코딩  
7. 클라이언트에 응답(바이트 패킷 전달)

````java
Flight       lookupFlight(String flightNo) { ... }
Passenger    findPassenger(long id) { ... }
Ticket       bookTicket(Flight flight, Passenger passenger) { ... }
SmtpResponse sendEmail(Ticket ticket) {...}
````

<br>

### 전형적인 블로킹 코드
````java
Flight flight = lookupFlight("LOT 783");
Passenger passenger = findPassenger(42);
Ticket ticket = bookTicket(flight, passenger);
sendEmail(ticket);
````

<br>

### 블로킹 코드 포장
````java
Observable<Flight> rxLookupFlight(String flightNo) {
    return Observable.defer(() -> Observable.just(lookupFlight(flightNo)));
}

Observable<Passenger> rxFindPassenger(long id) {
    return Observable.defer(() -> Observable.just(findPassenger(id)));
}
````

<br>

### 전형적인 블로킹 코드와 정확한 방식으로 동작
````java
Observable<Flight> flight = rxLookupFlight("LOT 783");
Observable<Passenger> passenger = rxFindPassenger(42);
Observable<Ticket> ticket = flight.zipWith(passenger, (f, p) -> bookTicket(f, p));
ticket.subscribe(this::sendEmail);
````

<br>

### 동기적으로 실행을 원할 경우, 권장하지 않는 마지막 수단
````java
Observable<Flight> flight = rxLookupflight("LOT 783")
    .subscribeOn(Scheduler.io());

Observable<Passenger> passenger = rxFindPassenger(42)
    .subscribeOn(Scheduler.io());
````

<br>

### 완전한 논블로킹
````java
Observable<Ticket> rxBookTicket(Flight flight, Passenger passenger) { ... }

Observable<Ticket> ticket = flight
    .zipWith(passenger, (f, p) -> Pair.of(f, p))
    .flatMap(pair -> rxBookTicket(pair.getLeft(), pair.getRight()));

Observable<Ticket> ticket = flight
    .zipWith(passenger, this::rxBookTicket)
    .flatMap(obs -> obs)  //항등 함수
````

<br>

## 비동기 체이닝 연산자
````java
List<Pair<Ticket, Future<SmtpResponse>>> tasks = tickets
    .stream()
    .map(ticket -> Pair.of(ticket, sendEmailAsync(ticket)))
    .collect(toList());

List<Ticket> failures = tasks.stream()
    .flatMap(pair -> {
        try {
            Future<SmtpResponse> future = pair.getRight();
            future.get(1, TimeUnit.SECONDS);
            return Stream.empty();
        } catch (Exception e) {
            Ticket ticket = pair.getLeft();
            log.warn("Failed to send {}", ticket, e);
            return Stream.of(ticket);
        }
    }).collect(toList());

private Future<SmtpResponse> sendEmailAsync(Ticket ticket) {
    return pool.submit(() -> sendEmail(ticket));
}
````

<br>

### 보편적이지 않은 동기 방식 Observable
````java
Observable<SmtpResponse> rxSendEmail(Ticket ticket) {
    return fromCallable(() -> sendEamil())
};
  
List<Ticket> failures = Observable.from(tickets)
    .flatMap(ticket -> rxSendEmail(ticket)
    .flatMap(response -> Observable.<Ticket>empty())
    //.ignoreElements() 메서드와 동일
    .doOnError(e -> log.warn("Failed to send {}", ticket, e))
    .onErrorReturn(err -> ticket))
    .subscribeOn(Schedulers.io())  //순차 실행 코드를 멀티 스레드 연산으로 변경
    .toList()
    .toBlocking()
    .single();
````

<br>

## 스트림 콜백 대체
자바 메시지 서비스(JMS)는 이벤트 리스너(콜백)을 제공 필수  
밀어내기 방식의 콜백 기반 API를 Observable로 변경하는 쉬운 방식은 Subject  

````java
@Component
class JmsConsumer {
    @JmsListener(destination = "orders")
    public void newOrder(Message msg) {
        ...
    }
}
````

<br>

### 외부에 있는 뜨거운 Observable과 유사
````java
private final PublishSubject<Message> subject = PublishSubject.create();

@JmsListener(destination = "orders", concurrency = "1")  //concurrency = "1" 복수의 스레드 호출 방지
public void newOrder(Message msg) {
    subject.onNext(msg);  //뜨거운 Observable, 이전 메시지는 그냥 버림
}

Observable<Message> observe() {
    return subject;
}
````

<br>

### Subject 대신 Observable
````java
public Observable<Message> observe(ConnectionFactory connectionFactory, Topic topic) {
    return Observable.create(subscriber -> {
        try {
            subscribeThrowing(subscriber, connectionFactory, topic);
        } catch (JMSException e) {
            subscriber.onError(e);
        }
    });
}

private void subscribeThrowing(
        Subscriber<? super Message> subscriber, ConnectionFactory connectionFactory, Topic topic) {
    Connection conneciton = connectionFactory.createConnection();
    Session session = connection.creaeteSesstion(true, AUTO_ACKNOWLEDGE);
    MessageConsumer consumer = session.createConsumer(orders);
    consumer.setMessageListener(subscriber::onNext);
    subscriber.add(onUnsubscribe(connection));
    connection.start();
}

private Subscription onUnsubscribe(Connection connection) {
    return Subscription.create(() -> {
        try {
            connection.close();
        } catch (Exception e) {
            log.error("Failed close", e);
        }
    });
}
````
<br>

### ActiveMQ 메시지 브로커로 메시지 소비
````java
ConnectionFactory connectionFactory = new ActiveMQConnectionFactory("tcp://localhost:61616");
Observable<String> txMessages = observe(connectionFactory, new ActiveMQTopic("orders"))
    .cast(TextMessage.class)
    //.map(x -> (TextMessage) x)와 유사
    .flatMap(m -> {
        try {
            return Observable.just(m.getText());
        } catch (JMSException e) {
            return Observable.error(e);
        }
    });
````

<br>

## 주기적 변경사항 폴링
최악의 블로킹 API 작업을 위해 변경 사항 폴링 필수  
변경 사항이 일어날때만 이벤트 방출  

````java
Observable<Item> observeNewItems() {
    return Observable
        .interval(1, TimeUnit.SECONDS)
        .flatMapIterable(x -> query())
        .distinct();
}

List<Item> query() {
    //파일 시스템 디렉토리 또는 데이터베이스 테이블의 스냅샷을 조회
}
````

<br>
