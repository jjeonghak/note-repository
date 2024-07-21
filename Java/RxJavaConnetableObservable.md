## ConnectableObservable
여러 Subscriber를 조율하고 밑바탕의 구독 하나를 공유  
최대 하나의 Subscriber만 유지  
실질적으로 같은 기반 리소스를 여러 Subscriber가 공유  

<br>

## 구독 하나만 유지
publish().refCount() 메서드를 통해 기반 리소스 제어  
해당 메서드 연동은 기반 Observable을 둘러싸서 모든 구독자를 가로챔  

````java
Observable<Status> observable = Observable.create(subscriber -> {
    System.out.println("Establishing connection");
    TwitterStream twitterStream = new TwitterStreamFactory().getInstance();
    ...
    subscriber.add(Subscriptions.create(() -> {
        System.out.println("Disconnecting");
        twitterStream.shutdown();
    }));
    twitterStream.sample();
});

//각각의 Subscriber마다 새로운 연결 및 종료
Subscription sub1 = observable.subscribe();
System.out.println("Subscribed 1");
Subscription sub2 = observable.subscribe();
System.out.println("Subscribed 2");
sub1.unsubscribe();
System.out.println("Unsubscribed 1");
sub2.unsubscribe();
System.out.println("Unsubscribed 2");
````

````
Establishing connection
Subscribed 1
Establishing connection
Subscribed 2
Disconnecting
Unsubscribed 1
Disconnecting
Unsubscribed 2
````

<br>

### 하나의 연결로 여러 구독자 관리
````java
lazy = observable.publish().refCount();
Subscription sub1 = lazy.subscribe();
System.out.println("Subscribed 1");
Subscription sub2 = lazy.subscribe();
System.out.println("Subscribed 2");
sub1.unsubscribe();
System.out.println("Unsubscribed 1");
sub2.unsubscribe();
System.out.println("Unsubscribed 2");
````

````
Establishing connection
Subscribed 1
Subscribed 2
Unsubscribed 1
Disconnecting
Unsubscribed 2
````    

<br>

## refCount()
지금 순간에 얼마나 많은 Subscriber가 존재하는지 계산  
가비지 컬렉션 알고리즘인 참조 횟수 계산(reference counting)과 유사  
0에서 1로 변경되면 업스트림 Observable 구독  
1보다 큰 수는 무시하고 모든 다운스트림 Subscriber가 동일한 업스트림 Subscriber 공윺  
마지막 다운스트림 Subscriber가 구독을 해지하면 1에서 0으로 변경되고 즉시 해제  

<br>

## publish()
아무 Subscriber가 존재하지 않아도 구독 강제 가능  
어떤 Observable 객체이든 publish() 메서드 호출 가능(ConnectableObservable 반환)  
connect() 메서드가 호출되지 않으면 Subscriber 보류 및 구독안함  
connect() 메서드가 호출되면 중재 전용 Subscriber가 업스트림 Observable 구독  
이때 다운스트림 구독자 갯수는 상관없음  

````java
ConnectableObservable<Status> published = tweets.publish();
published.connect();
````

<br>

### 서버 시작과 함께 Hot Observable 알림 받기
````java
@Configuration
class Config implements ApplicationListener<ContextRefreshedEvent> {
    private final ConnectableObservable<Status> observable = Observable.<Status>create(
        subscriber -> {
            log.info("starting");
            ...
        }).publish();

    @Bean
    public Observable<Status> observable() {
        return observable;
    }

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        log.info("connecting");
        observable.connect();
    }
}

@Component
class Foo {
    @Autowired
    public Foo(Observable<Status> tweets) {
        tweets.subscribe(status -> {
            log.info(status.getText());
        });
        log.info("subscribed");
    }
}

@Component
class Bar {
    @Autowired
    public Bar(Observable<Status> tweets) {
        tweets.subscribe(status -> {
            log.info(status.getText());
        });
        log.info("subscribed");
    }
}
````

````
[Foo   ] subscribed
[Bar   ] subscribed
[Config] connecting
[Config] starting
[Foo   ] msg 1
[Bar   ] msg 1
[Foo   ] msg 2
[Bar   ] msg 2

//일반적인 Observable 사용시
[Config] starting
[Foo   ] subscribed
[Foo   ] msg 1
[Config] starting
[Bar   ] subscribed
[Foo   ] msg 2
[Bar   ] msg 2
````

<br>


