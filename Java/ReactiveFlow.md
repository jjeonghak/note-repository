## Flow
자바 9에서는 리액티브 프로그래밍을 제공하는 java.util.concurrent.Flow 추가  
정적 컴포넌트 하나를 포함하고 있으며 인스턴스화 불가능  
발행-구독 모델을 지원하기 위한 인터페이스 존재  
API를 만들 당시 Akka, RxJava 등 다양한 리액티브 스트림의 자바 코드 라이브러리가 이미 존재했기 때문에 구현은 제공하지 않음  

````java
//Publisher 인터페이스
@FunctionalInterface
public interface Publisher<T> {
    void subscribe(Subscriber<? super T> s);
}

//Subscriber 인터페이스
public interface Subscriber<T> {
    void onSubscrube(Subscription s);
    void onNext(T t);
    void onError(Throwable t);
    void onComplete();
}

//Subscription 인터페이스
public interface Subscription {
    void request(long n);
    void cancel();
}
    
//Processor 인터페이스
public interface Processor<T, R> extends Subscriber<T>, Publisher<R> { }

//이벤트 메서드 호출 정의
onSubscribe onNext* (onError | onComplete)?
````

<br>

## 발행-구독 프로토콜 규칙
1. Publisher는 반드시 Subscription의 request 메서드에 정의된 갯수 이하의 요소만 Subscriber에게 전달  
    지정된 갯수보다 적은 수의 요소를 onNext 메서드로 전달 가능  
    동작이 성공적으로 종료시 onComplete 메서드 호출  
    문제 발생시 onError 메서드 호출  
  
2. Subscriber는 요소를 받아 처리할 수 있음을 Publisher에게 알림  
    역압력을 행사하기 위함  
    Subscription.request() 메서드 호출 없이 언제든 종료 시그널 받을 준비  
    Subscription.cancel() 호출된 이후에도 한개 이상의 onNext를 받을 준비  
    
3. Publisher와 Subscriber는 정확하게 Subscription을 공유  
    각각이 고유한 역할을 수행  
    onSubscribe 및 onNext 메서드에서 Subscriber는 request 메서드를 동기적으로 호출  
    Subscription.cancel() 메서드는 몇 번을 호출해도 한번 호출한 것과 동일  
    
<br>

## 리액티브 어플리케이션
````java
public class TempSubscription implements Subscription {
    private static final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Subscriber<? super TempInfo> subscriber;
    private final String town;
    
    public TempSubscription(Subscriber<? super TempInfo> subscriber, String town) {
        this.subscriber = subscriber;
        this.town = town;
    }
    
    @Override
    public void request(long n) {
        executor.submit(() -> {   //스택오버플로를 방지하기 위해 다른 스레드에서 다음 요소를 구족자에게 전송
            for (long i = 0L; i < n; i++) {
                try {
                    subscriber.onNext(TempInfo.fetch(town));  //현재 온도를 Subscriber에게 전달
                } catch (Exception e) {
                    subscriber.onError(e);                    //실패시 Subscriber에게 오류 전달
                    break;
                }
            }
        });
    }
    
    @Override
    public void cancel() {
        subscriber.onComplete();    //구독 취소시 Subscriber에게 신호 전달
    }
}

public class TempSubscriber implements Subscriber<TempInfo> {
    private Subscription subscription;
    
    @Override
    public void onSubscribe(Subscription subscription) {  //구독 저장후 첫번째 요청 전달
        this.subscription = subscription;
        subscription.request(1);
    }
    
    @Override
    public void onNext(TempInfo tempInfo) {   //수신한 온도 출력후 다음 정보 요청
        System.out.println(tempInfo);
        subscription.request(1);
    }
    
    @Override
    public void onError(Throwable t) {    //오류 발생시 메시지 출력
        System.err.println(t.getMessage);
    }
    
    @Override
    public void onComplete() {
        System.out.println("Done");
    }
}

public class Main {
    public static void main(String[] args) {
        getTemperatures("New York").subscribe(new TempSubscriber());  //Publisher 생성후 구독
    }
    
    private static Publisher<TempInfo> getTemperaturs(String town) {
        return subscriber -> subscriber.onSubscribe(
            new TempSubscription(subscriber, town));
    }
}
````

<br>

## Processor
Processor 인테페이스는 Subscriber와 Publisher만 상속  
목적은 Publisher 구독한 다음 수시한 데이터를 가공한 후 다시 제공하는 것  

````java
public class TempProcessor implements Processor<TempInfo, TempInfo> {   //TempInfo -> TempInfo
    private Subscriber<? super TempInfo> subscriber;
    
    @Override
    public void onNext(TempInfo temp) {
        subscriber.onNext(new TempInfo(temp.getTown(),
            (temp.getTemp() - 32) * 5 / 9));    //섭씨로 변환후 다시 전송
    }
    
    @Override
    public void onSubscribe(Subscription subscription) {
        subscription.onSubscribe(subscription);
    }
    
    @Override
    public void onError(Throwable throwalbe) {
        subscriber.onError(throwable);
    }
    
    @Override
    public void onComplete() {
        subscriber.onComplete();
    }
}

public class Main {
    public static void main(String[] args) {
        getCelsiusTemperatures("New York").subscribe(new TempSubscriber());
    }
    
    public static Publisher<TempInfo> getCelsiusTemperatures(String town) {
        return subscriber -> {
            TempProcessor processor = new TempProcessor();
            processor.subscribe(subscriber);
            processor.onSubscribe(new TempSubscription(processor, town));
        };
    }
}
````

<br>

