## RxJava 흐름 제어 방식
내장된 연산자를 사용한 샘플링이나 일괄 처리와 같은 다양한 흐름 제어 방식 구현  
구독자는 배압을 사용해서 처리할 수 있는 만큼 항목을 요청하고 전파  
배압은 최종단 구독자뿐만 아니라 모든 중간 연산자가 생상자에게 일정 수의 이벤트만 요청하도록 하는 장치  

<br>

## 주기적인 샘플링과 스로틀링
sample() 연산자는 업스트림 Observable을 주기적으로 관찰, 마지막 이벤트는 버림  
주기별로 관측값을 방출, 관측 중에 이벤트 발생 없다면 방출되는 다운스트림 없음  
2.1부터 sample(long period, TimeUnit unit, boolean emitLast) 오버로드 형태 제공  
인자로 Observable(샘플러) 가능  
throttleLast() 메서드로는 지정된 기간 내에 가장 최근 이벤트를 방출(sample())   
throttleFirst() 메서드는 지정된 기간 내에 첫 번째 이벤트를 방출(debounce())  

<br>

````java
long startTime = System.currentTimeMillis();
Observable
    .interval(7, TimeUnit.MILLISECONDS)
    .timestamp()
    .sample(1, TimeUnit.SECONDS)
    .map(ts -> ts.getTimestampMillis() - startTime + "ms: " + ts.getValue())
    .take(5)
    .subscribe(System.out::println);
````

````
//1초마다 관측값 방출
1088ms: 141
2089ms: 284
3090ms: 427
4084ms: 569
5085ms: 712
````

<br>

````java
Observable<String> names = Observable
    .just("Mary", "Patricia", "Linda", "Barbara", "Elizabeth", "Jennifer",
        "Maria", "Susan", "Margaret", "Dorothy");
Observable<Long> absoluteDelayMillis = Observable
    .just(0.1, 0.6, 0.9, 1.1, 3.3, 3.4, 3.5, 3.6, 4.4, 4.8)
    .map(d -> (long)(d * 1_000));
Observable<String> delayedNames = names
    .zipWith(absoluteDelayMillis, (n, d) -> Observable
        .just(n)
        .delay(d, MILLISECONDS))
    .flatMap(o -> o);
delayedNames
    .sample(1, SECONDS)
    //.throttleLast(1, SECONDS)
    .subscribe(System.out::println);
````

````java
//똑같은 동작
obs.sample(1, SECONDS);
obs.sample(Observable.interval(1, SECONDS));
````

<br>

## 리스트 버퍼링
buffer() 연산자는 이벤트 묶음을 실시간으로 List에 집계  
toList() 메서드와는 다르게 모든 이벤트를 하나로 모으지 않고 그룹화한 여러 목록으로 집계  
지정한 버퍼 크기가 될 때까지 버퍼링 후 전체 버퍼를 다운스트림으로 방출  
완료 알림이 온 시점에 내부 버퍼가 비어있지 않다면 그대로 방출  
윈도우 형식의 오버로드 존재  
시간 간격에 따라 일괄 처리하는 오버로드 존재  

<br>

````java
Observable
    .range(1, 7)
    .buffer(3)
    .subscribe((List<Integer> list) -> {
        System.out.println(list);
    });
````

````
[1, 2, 3]
[4, 5, 6]
[7]
````

<br>

### 세분화된 이벤트를 병합해서 연산 횟수 감소
````java
Observable
    .subscribe(repository::store);
Observable
    .buffer(10)
    .subscribe(repository::storeAll);
````

<br>

### 슬라이딩 윈도우 형식의 오버로드 buffer
````java
Observable
    .range(1, 7)
    .buffer(3, 1)
    .subscribe(System.out::println);
````

````
[1, 2, 3]
[2, 3, 4]
[3, 4, 5]
[4, 5, 6]
[5, 6, 7]
[6, 7]
[7]
````

<br>

### 두번째 인수는 버퍼 크기보다 클 수 있음
````java
Observable<Integer> odd = Observable
    .range(1, 7)
    .buffer(1, 2)
    .flatMapIterable(list -> list);
````

<br>

### 시간 간격으로 버퍼링
````java
Obseravble
    .range(1, 7)
    .delay(500, TimeUnit.MILLISECONDS)
    .buffer(1, TimeUnit.SECONDS)
    .subscriber(System.out::println);

Observable
    .range(1, 7)
    .delay(500, TimeUnit.MILLISECONDS)
    .buffer(1, TimeUnit.SECONDS)
    .map(List::size);
````

<br>

### 시간대별로 이벤트 처리
````java
Observable<Duration> insideBusinessHours = Observable
    .interval(1, TimeUnit.SECONDS)
    .filter(x -> isBusinessHour())
    .map(x -> Duration.ofMillis(100));
Observable<Duration> outsideBusinessHours = Observable
    .interval(5, TimeUnit.SECONDS)
    .filter(x -> !isBusinessHour())
    .map(x -> Duration.ofMillis(200));
Observable<Duration> openings = Observable
    .merge(insideBusinessHours, outsideBusinessHours);
Observalbe<TeleData> upstream = ...
Observable<List<TeleData>> samples = upstream
    .buffer(openings);

private static final LocalTime BUSINESS_START = LocalTime.of(9, 0);
private static final LocalTime BUSINESS_END = LocalTime.of(17, 0);

private boolean isBusinessHour() {
    ZoneId zone = ZoneId.of("Europe/Warsaw");
    ZonedDateTime zdt = ZonedDateTime.now(zone);
    LocalTime localTime = zdt.toLocalTime();
    return !localTime.isBefore(BUSINESS_START) && !localTime.isAfter(BUSINESS_END);
}
````

<br>

### 일괄처리 오버로드
````java
Observable<List<TeleData>> samples = upstream
    .buffer(openings, duration -> empty().delay(duration.toMillis(), MILLISECONDS));
````

<br>

## 윈도우
buffer() 연산자는 현재 버퍼를 다운스트림으로 전달할 때마다 임시 List 생성  
불필요한 가비지 컬렉션이나 메모리 사용을 유발할 가능성 존재  
즉시 이벤트를 처리하기 위한 window() 연산자  
하나의 일괄 처리 또는 버퍼를 포함하는 고정 리스트를 받는 대신 스트림의 스트림을 받음  
int를 인수로 받아 원본에서 이벤트를 고정 크기 목록으로 그룹화하는 오버로드 존재  
시간 단위를 받아 고정된 시간 간격 안에 이벤트를 그룹화하는 오버로드 존재  
개별 일괄 처리의 시작과 끝을 나타내는 사용자 정의 Observable을 인수로 받는 오버로드 존재  

<br>

### 많은 낭비
````java
Observable<KeyEvent> eventPerSecond = keyEvents
    .buffer(1, SECONDS)
    .map(List::size);
````

<br>

### buffer() 연산자와 다른 window()
````java
Observable<Observable<KeyEvent>> windows = keyEvents.window(1, SECONDS);
Observable<Integer> eventPerSecond = windows
    .flatMap(eventsInSecond -> eventsInSecond.count());
````

<br>

## 낡은 이벤트 건너뛰기 
위의 연산자들은 이벤트 사이의 경과 시간을 고려하지 않움  
바로 이어서 새로운 이벤트 발생시 이전 이벤트를 무시할 가능성 존재  
debounce() 또는 throttleWithTimeout() 연산자는 특정 이벤트 직후에 뒤따른 모든 이벤트를 버림  
지정된 이벤트 이후 타임 윈도우 안에 다른 이벤트가 나타나지 않는 경우 해당 이벤트를 방출  
즉 새로운 이벤트가 앞선 이벤트를 진압  

<br>

````java
//100ms 이내에 이벤트가 나타나는지 관찰, 나타나는 경우 다시 100ms 대기
Observable<BigDecimal> prices = tradingPlatform.priceOf("NFLX");
Observable<BigDecimal> debounced = prices.debounce(100, MILLISECONDS);

//이벤트 조건에 따른 상이한 관찰 시간 오버로드(debounceSelector)
prices.debounce(x -> {
    boolean goodPrice = x.compareTo(BigDecimal.valueOf(150)) > 0;
    return Observable
        .empty()
        .delay(goodPrice ? 10 : 100, MILLISECONDS);
});

Observable<BigDecimal> pricesOf(String ticker) {
    return Observable
        .interval(50, MILLISECONDS)
        .flatMap(this::randomDelay)
        .map(this::randomStockPrice)
        .map(BigDecimal::valueOf);
}

Observable<Long> randomDelay(long x) {
    return Observable
        .just(x)
        .delay((long) (Math.random() * 100), MILLISECONDS);
}

double randomStockPrice(long x) {
    return 100 + Math.random() * 10 + (Math.sin(x/100.0)) * 60.0;
}
````

<br>

## 이벤트 고갈 회피
이벤트가 지속적으로 자주 등장하는 경우 debounce() 연산자가 모든 이벤트 방출을 막는 경우  

````java
Observable
    .interval(99, MILLISECONDS)
    .debounce(100, MILLISECONDS)  //이벤트 방출 안됨
    .timeout(1, SECONDS)          //TimeoutException 발생
````

<br>

### timeout() 메서드로 회피 - 미묘한 버그
````java
ConnectableObservable<Long> upstream = Observable
    .interval(99, MILLISECONDS)
    .publish();
upstream
    .debounce(100, MILLISECONDS)
    .timeout(1, SECONDS, upstream.take(1));
upstream.connect();
````

<br>

### 재귀를 사용(defer() 메서드를 활용한 생성 지연)
````java
Observable<Long> timedDebounce(Observable<Long> upstream) {
    Observable<Long> onTimeout = upstream
        .take(1)
        .concatWith(defer(() -> timedDebounce(upstream)));    //defer() 메서드를 활용해 구독할 때 Observalbe 생성
    return upstream
        .debounce(100, MILLISECONDS)
        .timeout(1, SECONDS, onTimeout);
}
````

<br>

## 설거지 배압 예제
식당에서 끊임없이 설거지 작업을 진행

````java
class Dish {
    //oneKb 버퍼는 여분의 메모리 사용을 흉내
    private final byte[] oneKb = new byte[1_024];
    private final int id;

    Dish(int id) {
        this.id = id;
        System.out.println("Created: " + id);
    }

    public String toString() {
        return String.valueOf(id);
    }
}
````

<br>

### 느린 설거지 작업 속도
````java
Observable
    .range(1, 1_000_000_000)
    .map(Dish::new)
    .subscribe(x -> {
        System.out.println("Washing: " + x);
        sleepMillis(50);
    });
````

<br>

기본적으로 range() 메서드는 비동기적으로 동작하지 않음  
소비자에 속도에 맞춰 생상  
하나의 블로킹 요소가 전체 시스템을 느리게 만듬  

````
    Created: 1
    Washing: 1
    Created: 2
    Washing: 2
    Created: 3
    Washing: 3
    ...
````

<br>

### 어느 정도의 배압
````java
dishes
    .observeOn(Schedulers.io())
    .subscribe(x -> {
        System.out.println("Washing: " + x);
        sleepMillis(50);
    });
````

<br>

빠른 속도의 생산과 느린 속도의 소비  
처리되지 않은 이벤트가 쌓여 OutOfMemoryError 발생  
하지만 어느 정도 배압이 작용  
range() 메서드를 통해 일괄 처리가 즉시 생성 후 유휴 상태  

````
Created: 1
Created: 2
Created: 3
...
Created: 128
Washing: 1
Washing: 2
Washing: 3
...
Washing: 128
Created: 129
...
````

<br>

### 영원히 씻기지 않는 접시
````java
Observable<Integer> myRange(int from, int count) {
    return Observable.create(subscriber -> {
        int i = from;
        while (i < from + count) {
            if (!subscriber.isUnsubscribed()) {
                subscriber.onNext(i++);
            } else {
                return;
            }
        }
        subscriber.onCompleted();
    })
}

myRange(1, 1_000_000_000)
    .map(Dish:new)
    .observeOn(Schedulers.io())
    .subscribe(x -> {
            System.out.println("Washing: " + x);
            sleepMillis(50);
        }, Throwable::printStackTrace
    );
````

````
Created: 1
Created: 2
Created: 3
...
Created: 7177
rx.exceptions.MissingBackpressureException
    at rx.internal.operators...
    at rx.internal.operators...
````

<br>

## 내장 배압
구독을 위해 onNext(), onCompleted(), onError() 메서드 구현 가능  
구현해야할 다른 콜백 메서드로 onStart() 메서드 존재  

````java
Observalbe
    .range(1, 10)
    .subscribe(new Subscriber<Integer>() {
        @Override
        public void onStart() {
            request(3);
        }
        // 이후 onNext(), onCompleted, onError 구현
    });
````

<br>

### Subscriber 생성자를 사용 가능하지만 기괴
````java
.subscribe(new Subscriber<Integer> {
    {{
        request(3);
    }}
    // 이후 onNext(), onCompleted, onError 구현
})
````

<br>

request(n) 메서드를 통해 업스트림 소스에 이벤트 크기 지정  
건너뛰는 경우 request(Long.MAX_VALUE) 호출  
reuquest() 메서드를 가장 먼저 호출해야 수요 조절 가능, 이후 호출은 이미 방출을 시작  
Subscriber는 얼마나 많은 값을 받고 싶은지 결정 가능  
배압 친화적인 observeOn() 연산자가 생성하는 Subscriber는 배압 제어가 가능  
zip() 메서드 또한 대상 스트림 중 하나가 매우 활동적이라 해도 영향을 받지 않음  
128개 만큼만 요구, rx.ring-buffer.size 시스템 프로퍼티로 조절  

<br>

### 어떠한 배압도 기능도 없이 일반적인 Subscriber처럼 동작
````java
Observable
    .range(1, 10)
    .subscribe(new Subscriber<Integer>() {
        @Override
        public void onStart() {
            request(1);
        }

        @Override
        public void onNext(Integer integer) {
            request(1);
            log.info("Next {}", integer);
        }

    });
````

<br>

## 누락된 배압
MissingBackpressureException 오류는 보통 request() 호출을 무시하기 때문에 발생  
업스트림 Observable이 요청보다 더 많은 항목을 밀어냄  
막을 수 있는 방법은 구독취소지만 그저 조금 늦추고 싶은 경우 존재  
다운스트림 연산자는 수신하려는 이벤트의 수를 정확히 알고 있지만 소스 스트임은 이러한 요청을 무시  
요청된 이벤트 수를 존중하는 저수준 방식은 rx.Producer로 구현  
이 인터페이스는 create() 메서드 내부에 연결  
Producer 구현은 상태를 저장하지만 스레드 안전해야하며 빠른 속도를 요구  
Producer는 나중에 request() 메서드를 호출할 때마다 Subscriber 안에서 간접적으로 호출  

<br>

````java
Observable<Integer> myRangeWithBackpressure(int from, int count) {
    return Observable.create(new OnSubscribeRange(from, count));
}

class OnSubscribeRange implements Observable.OnSubscribe<Integer> {
    // 생성자 ...

    @Override
    public void call(final Subscriber<? super Integer> child) {
        child.setProducer(new RangeProducer(child, start, end));
    }
}

class RangeProducer implements Producer {
    @Override
    public void request(long n) {
        // 자식 구독자의 onNext() 메서드 호출
    }
}
````

<br>

## 배압 흉내
onBackpressure*() 계열의 연산자를 사용해서 어느 정도의 배압 흉내 가능   
연산자와 배압을 요구하는 구독자, 그리고 이를 지원하지 않는 Observale 상이의 연결에 사용   

<br>

1. onBackpressureBuffer()  
    onBackpressureBuffer() 연산자는 모든 업스트림 이벤트를 버퍼링하고 요청받은 데이터만을 다운스트림 구독자에게 제공  
    request(128) 요청을 무시하고 데이터를 밀어내는 경우 onBackpressureBuffer() 메서드가 내부적으로 제한 없는 버퍼를 유지  
    먼저 내부 버퍼를 고갈시키고 거의 미었을 경우에만 업스트림에 추가로 데이터 요청  
    메모리 고갈을 방지하기 위해 오버로드된 onBackpressureBuffer(N) 존재  

    ````java
    myRange(1, 1_000_000_000)
        .map(Dish::new)
        .onBackpressureBuffer()
        //.onBackpressureBuffer(1000, () -> log.warn("Buffer full"))
        .observeOn(Schedulers.io())
        .subscribe(x -> {
            System.out.println("Washing: " + x);
            sleepMillis(50);
        });
    ````

2. onBackpressureDrop()
    하드웨어와 OS의 한계를 극복하기 위한 onBackpressureDrop() 메서드 존재  
    request() 메서드 없이 나타나는 모든 이벤트를 버림  
  
    ````java
    .onBackpressureDrop(dish -> log.warn("Throw away {}", dish))
    ````

3. onBackpressureLatest()
    onBackpressureDrop() 메서드와 유사하지만 가장 최근 삭제된 이벤트의 참조를 유지  
    다운스트림에서 뒤늦게 request() 요청하면 마지막으로 본 값을 제공  

<br>

## ResultSet
다운스트림의 배압 요청을 지원하는 쉬운 방안은 range(), from(Iterable&lt;T&gt;)과 같은 내장 팩토리 메서드를 사용하는 것  
Iterable을 사용하여 소스를 만들지만 배압을 내장    
스트림으로 포장한 JDBC의 ResultSet은 배압이 가능한 Observable처럼 끌어오기 기반  
하지만 Iterable이나 Iterator가 아니므로 우선 Iterator&lt;Object[]&gt; 형태로 변환 필수  
Object[] 형태는 데이터베이스에서 하나의 행을 느슨하게 형식화한 표현  
ResultSet은 파괴적이며 완료시 닫아야한다는 점이 차이점  

<br>

### 오류 처리 기능없는 ResultSetIterator
````java
public class ResultSetIterator implements Iterator<Object[]> {

    private final ResultSet rs;

    public ResultSetIterator(ResultSet rs) {
        this.rs = rs;
    }

    @Override
    public boolean hasNext() {
        return !rs.isLast();
    }

    @Override
    public Object[] next() {
        rs.next();
        return toArray(rs);
    }

}
````

<br>

### 변환 메서드
````java
public static Iterable<Object[]> iterable(final Result rs) {
    return new Iterable<Object[]>() {
        @Override
        public Iterator<Object[]> iterator() {
            return new ResultSetIterator(rs);
        }
    };
}
````

<br>

### 배압 지원 Observable<Object[]>
````java
Connection con = ...
PreparedStatement stmt = con.prepareStatement("SELECT ...");
stmt.setFetchSize(1000);
ResultSet rs = stmt.executeQuery();
Observable<Object[]> result = Observable.from(ResultSetIterator.iterable(rs))
    .doAfterTerminate(() -> {
        try {
            rs.close();
            stmt.close();
            con.close();
        } catch (SQLException e) {
            log.warn("Unable to close", e);
        }
    });
````

<br>

내장된 from() 연산자를 지원  
Subscriber 처리량은 더이상 관련없이 MissingBackpressureException 오류 발생안함  
JDBC 드라이버는 모든 레코드를 메모리에 적재하려는 시도 때문에 setFetchSize() 메서드 필수  

<br>

## Producer 맞춤 구현
이 작업은 오류가 발생하기 쉬움  
도우미 클래스인 SyncOnSubscribe 사용  

````java
Observable.OnSubscribe<Double> onSubscribe = SyncOnSubscribe.createStateless(
    observer -> observer.onNext(Math.random())
);
Observable<Double> rand = Observable.create(onSubscribe);
````

<br>
