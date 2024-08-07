## Observalbe 알림 구독
Observable 객체는 누군가 구독을 하지 않으면 이벤트 방출 안함  
subscriber() 계통 메서드 사용으로 구독  

````java
Observalbe<Tweet> tweets = ...
tweets.subscribe((Tweet tweet) -> System.out.println(tweet));

//인자를 통한 생성
tweets.subscribe(
    (Tweet tweet) -> System.out.print(tweet),
    (Throwable t) -> t.printStackTrace(),
    () -> this.noMore()
);
````

<br>

## 상수 Observable
향후 구독할 대상에 정확히 하나의 값 방출 후 종료  
````java
Observable.just(value)
````

<br>

Iterable&lt;T&gt; 또는 T[] 객체를 받아 해당 컬렉션의 값 방출 후 종료  
````java
Observable.from(values)
````

<br>

from부터 n개의 정수값을 스트림으로 생성 및 방출 후 종료  
````java
Observable.range(from, n)
````

<br>

아무 값도 방출하지 않고 종료  
````java
Observable.empty()
````

<br>

알림, 종료, 오류 이벤트 중 어떤 것도 방출하지 않고 종료  
````java
Observable.never()
````

<br>

모든 구독자에게 즉시 onError() 알림 방출  
````java
Observable.error()
````

<br>

## Observable.create()
상수 Observable 생성 팩토리 메서드는 기본적으로 동기적 실행  
create() 메서드는 다목적이라 상수 생성 팩토리 메서드 모방 가능  
subscribe() 메서드를 호출할 때마다 create() 메서드 안의 구독 핸들러 호출  
무한 스트림과 cache() 메서드를 함께 사용하는 경우 OutOfMemoryError 발생  
create() 메서드 안에서 스레드 사용 금지  

````java
Observable<Integer> ints = Observable.create(new Observable.OnSubscribe() {
      @Override
      public void call(Subscriber<? super Integer> subscriber) {
          subscriber.onNext(0);
          subscriber.onCompleted();
      }
  });

//동일한 값을 여러 구독자에게 전달하는 경우
Observable<Integer> ints = Observable.create(...).cache();
````

<br>

## 무한 스트림
무한 스트림 구현을 하는 람다식은 해당 스레드에서 바로 동작하므로 블록  

````java
Observable<BigInteger> naturalNumbers = Observable.create(
    subscriber -> {
        Runnable r = () -> {
            BigInteger i = ZERO;
            while (!subscriber.isUnsubscribed()) {
                subscriber.onNext(i);
                i = i.add(ONE);
            }
        };
        final Thread thread = new Thread(r);
        thread.start();
        subscriber.add(Subscriptions.create(thread::interrupt));
    }
)
Subscription subscription = naturalNumbers.subscribe(x -> log(x));
subscription.unsubscribe();
````

<br>

## 시간
timer() 메서드는 지정한 시간만큼 지연시킨 후 0L값 방출 후 종료  
````java
Observable.timer(1, TimeUnit.SECONDS)
    .subscribe(zero -> log(zero));
````

<br>

interval() 메서드는 long 타입 순열을 생성  
0부터 시작하며 각 인덱스 사이에 정해진 시간 지연 삽입  
````java
Observable.interval(1_000_000 / 60, TimeUnit.MICROSECONDS)
    .subscribe(i -> log(i));
````

<br>

## Cold & Hot Observable
1. Cold Observable  
    느긋한 실행  
    누군가 구독하지 않으면 이벤트 방출 안함  
    어떤 식으로든 캐시되지 않기때문에 어떤 구독자든지 각자 별도의 스트림 복사본을 받음  

2. Hot Observable  
    획득한 순간부터 즉시 이벤트 방출  
    다운스트림으로 이벤트를 밀어내기 때문에 이벤트 유실 발생  
    구독자로부터 독립적으로 Subscriber 존재 여부와 상관없이 동작  

<br>
    
### Twitter 예시 - 애매한 경계(통제할 수 없는 외부 이벤트, 구독해야만 이벤트 스트림 시작)
````java
Observable<Status> observe() {
    return Observable.create(subscriber -> {
        TwitterStream twitterStream = new TwitterStreamFactory().getInstance();
        twitterStream.addListener(new StatusListener() {
            @Override
            public void onStatus(Status status) {
                if (subscriber.isUnsubscribed()) {
                    twitterStream.shutdown();
                } else {
                    subscriber.onNext(status);
                }
            }

            @Override
            public void onException(Exception e) {
                if (subscriber.isUnsubscribed()) {
                    twitterStream.shutdown();
                } else {
                    subscriber.onError(e);
                }
            }
        });
        twitterStream.sample();
        subscriber.add(Subscriptions.create(twitterStream::shutdown));
    });
}
````

<br>

### 수동 subscriber 관리 - 많은 오류 발생
````java
class LazyTwitterObservalbe {
    private final Set<Subscriber<? super Status>> subscribers = new CopyOnWriteArraySet<>();
    private final TwitterStream twitterStream;
    private final Observable<Status> observable = Observable.create(subscriber -> {
       register(subscriber);
        subscriber.add(Subscriptions.create(() -> this.deregister(subscriber)));
    });

    public LazyTwitterObservable() {
        this.twitterStream = new TwitterStreamFactory().getInstance();
        this.twitterStream.addListener(new StatusListener() {
            @Override
            public void onStatus(Status status) {
                subscribers.forEach(s -> s.onNext(status));
            }

            @Override
            public void onException(Exception e) {
                subscribers.forEach(s -> s.onError(e));
            }
        });
    }
    
    public Observable<Status> oberve() {
        return observable;
    }

    private synchronized void register(Subscriber<? super Status> subscriber) {
        if (subscribers.isEmpty()) {
            subscribers.add(subscriber);
            twitterStream.sample();
        } else {
            subscribers.add(subscriber);
        }
    }

    private synchronized void deregister(Subscriber<? super Status> subscriber) {
        subscribers.remove(subscriber);
        if (subscribers.isEmpty()) {
            twitterStream.shutdown();
        }
    }
}
````
    
<br>

