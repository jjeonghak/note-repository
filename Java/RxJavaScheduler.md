## Scheduler
RxJava는 동시성과 무관하고 자체적으로 동시성 도입하지 않음  
Scheduler는 Rx 규약을 맞추기 위한 추상화를 제시  
스케줄러는 특정 유형의 Observable을 만들 때 subscribeOn(), observeOn() 연산자 사용  
스케줄러는 코드 스케줄링과 실행을 담당하는 Worker 객체만 생성  
RxJava에서 어떤 코드를 스케줄링한다면 Scheduler에 Worker 제공 요청 후 Worker를 사용해서 후속 작업  


1. Schedulers.newThread()  
    subscribeOn(), observeOn() 메서드를 통해 요청을 받으면 새로운 스레드를 시작  
    스레드 시작시 지연 발생 및 스레드 재사용 불가로 권장하지 않음  
    미리 스택 공간 할당(1MB 정도, JVM -Xss 인자로 조절)  
    작업들이 큰 단위(coarsegrained)인 경우 유용  

2. Schedulers.io()  
    newThread() 메서드와 유사하지만 이미 시작된 스레드를 재사용 가능  
    풀 크기의 제한이 없는 java.util.concurrent.ThreadPoolExecutor와 유사하게 동작  
    매번 새로운 Worker 요청하면 새로운 스레드 시작 또는 대기 중인 스레드 재사용  
    CPU 리소스가 거의 필요없는 I/O 바운드 작업인 경우 사용  
    
3. Schedulers.computation()  
    작업이 전적으로 CPU 기반인 경우 사용  
    계산 능력이 필요하고 디스크 읽기, 네트워크, 잠금 대기 같은 블로킹 코드가 없는 상황  
    CPU 코어 하나를 완전히 점유하리라 가정, 가용 코어 숫자보다 더 많은 작업을 병렬로 실행하는 경우 이득 없음  
    Runtime.getRuntime() 유틸리티 클래스의 availableProcessors() 반환값으로 제한  
    기본값과 다른 스레드 갯수가 필요한 경우 rx.scheduler.max-computation-threads 속성을 사용  
    스레드 갯수를 제한하여 CPU를 유휴 상태로 변경해두면 스레드 풀은 과부하 상태라도 서버를 포화시키지 않음  
    모든 스레드를 앞에 제한을 두지 않는 개별 큐를 할당해서 모든 코어가 사용중인 경우 큐에 작업 대기  
    제한된 스레드 갯수를 유지할 수 있지만 개별 스레드 큐의 크기는 계속 증가  
    observeOn() 메서드를 사용하면 Scheduler에 과부하를 조절 가능  

4. Schedulers.from(Executor executor)  
    Scheduler는 내부적으로 java.util.concurrent.Executor보다 훨씬 복잡  
    Executor는 개념적으로 유사하기 때문에 포장하여 Scheduler로 생성 가능  
    Executor에서 Scheduler 생성은 높은 부하를 처리하는 프로젝트에서 권장  
    Executor 내부에서 생성되는 독립적인 스레드에 대한 제어는 불가능  
    캐시 지역성(locality)을 향상시키기 위한 작업을 같은 스레드에서 처리 불가능  

    ````java
    ThreadFactory threadFactory = new ThreadFactoryBuilder()
        .setNameFormat("MyPool-%d")
        .build();
    Executor executor = new ThreadPoolExecutor(
        10,                                 //corePoolSize
        10,                                 //maximumPoolSize
        0L, TimeUnit.MILLISECONDS,          //keepAliveTime, unit
        new LinkedBlockingQueue<>(1000),    //workQueue
        threadFactory
    );
    Scheduler scheduler = Schedulers.from(executor);
    ````

<br>

5. Schedulers.immediate()  
    비동기 방식이 아닌 클라이언트 스레드에서 블로킹 방식으로 작업 진행  
    주어진 작업을 즉시 시작(trampoline() 메서드와의 차이)  
    API에서 명시적으로 요구하지 않는 경우 사용할 일 없음  

6. Schedulders.trampoline()  
    immediate() 메서드와 매우 유사  
    같은 스레드에서 작업을 수행하므로 사실상 블로킹  
    곧 이어질 작업을 앞서 그케줄링된 모든 작업이 끝난 후 시작  
    호출 스택의 무한한 증가 없이도 재귀를 구현 가능  
    처음에는 immediate() 메서드를 수반  

   ````java
    Scheduler scheduler = Schedulers.immediate();
    Scheduler.Worker worker = scheduler.createWork();
  
    log.info("main start");
    worker.schedule(() -> {
        log.info("  outer start");
        sleepOneSecond();
        worker.schedule(() -> {
            log.info("    middle start");
            sleepOneSecond();
            worker.scheduler(() -> {
                log.info("      inner start");
                sleepOneSecond();
                log.info("      inner end");
            })
            log.info("    middle end");
        });
        log.info("  outer end");
    });
    log.info("main end");
    worker.unsubscribe();
   ````
   ````
    //immediate() 메서드 사용
    1029 | main | main start
    1091 | main |   outer start
    2093 | main |     middle start
    3095 | main |       inner start
    4096 | main |       inner end
    4099 | main |     middle end
    4099 | main |   outer end
    4099 | main | main end
  
    //trampoline() 메서드 사용
    1041 | main | main start
    1095 | main |   outer start
    2099 | main |   outer end
    2099 | main |     middle start
    3101 | main |     middle end
    3101 | main |       inner start
    4102 | main |       inner end
    4102 | main | main end
   ````

<br>

7. Schedulers.test()  
    단지 테스트 목적으로 만들어 실제 코드에선 볼 일 없음  
    임의로 시계를 돌려 시간의 흐름을 시뮬레이션 가능  

<br>

## 세부 구현  
Scheduler는 작업과 그 실행을 분리할 뿐만 아니라 시간도 추상화  
Scheduler와 Worker 모두 재정의 가능한 시간 기준인 now() 메서드 보유  
이는 주어진 작업을 언제 시작할지 결정할 때 사용  
Scheduler는 스레드 풀, Worker는 풀 내부의 스레드와 유사  
동일한 Worker에 스케줄링된 두 개의 작업이 절대로 동시에 수행되지 않도록 제한  
같은 Scheduler라도 서로 다른 Worker라면 동시 작업 가능  

````java
abstract class Scheduler {
    abstract Worker createWorker();

    long now();

    abstract static class Worker implements Subscription {
        abstract Subscription schedule(Action0 action);
        abstract Subscription schedule(Action0 action, long delayTime, TimeUnt unit);
        long now();
    }
}

public final class SimplifiedHandlerScheduler extends Scheduler {
    @Override
    public Worker createWorker() {
        return new HandlerWorker();
    }

    static class HandlerWorker extends Worker {
        private final Handler handler = new Handler(Looper.getMainLooper());
        private final CompositeSubscription compositeSubscription = new CompositeSubscription();

        @Override
        public void unsubscribe() {
            compositeSubscription.unsubscribe();
        }

        @Override
        public boolean isUnsubscribed() {
            return compositeSubscription.isUnsubscribed();
        }

        @Override
        public Subscriprion schedule(final Action0 action) {
            return schedule(action, 0, TimeUnit.MILLISECONDS);
        }

        @Override
        public Subscription schedule(Action0 action, long delayTime, TimeUnit unit) {
            if (compositeSubscription.isUnsubscribed()) {
                return Subscriptions.unsubscribed();
            }
            final ScheduledAction scheduledAction = new ScheduledAction(action);
            scheduledAction.addParent(compositeSubscription);  //취소시 자신을 제거할 부모 
            compositeSubscritipion.add(scheduledAction);       //모든 Subscrption 추적
            handler.postDelayed(scheduledAction, unit.toMillis(delayTime));
            scheduledAction.add(Subscriptions.create(() -> handler.removeCallbacks(scheduledAction)));
            return scheduledAction;
        }
    }
}
````

<br>

## 선언적 구독
Observable.create() 메서드는 블로킹 방식  
subscribeOn() 메서드를 통해 비동기적으로 사용 가능  
subscribeOn() 메서드는 OnSubscribe(create() 메서드 내부의 람다식)를 호출할때 어떤 스케줄러를 사용할지 선택  
완전한 리엑티브 시스템에서는 모든 Observable이 비동기이며 subscribeOn() 메서드는 사용하지 않음  
Observable과 subscribe() 메서드 사이에 여러 subscribeOn() 메서드 존재시 Observable에 가장 가까운 subscribeOn() 메서드 사용  
블로킹 Observable 사용시 주의점  
    Scheduler 없는 Observable은 블로킹 메서드 호출이 서로 값을 전달하는 단일 스레드처럼 동작  
    단일 subscribeOn() 메서드는 백그라운드 스레드 하나에서 큰 작업을 하는 것과 유사  
    flatMap() 메서드 내부의 subscribeOn()은 ForkJoinPool이 동작하는 것과 유사  

<br>

### 이벤트 생성과 동시성 선택의 잘못된 선언, 클라이언트 코드가 결정해야할 문제
````java
Observable<String> obs = Observable.create(subscriber -> {
    Runnable runnable = () -> {
        subscriber.onNext("data1");
        subscriber.onNext("data2");
        subscriber.onNext("data3");
        subscriber.onCompledted();
    }
    new Thread(runnable, "Async").start();
});
````

<br>

### 스케줄러 생성
````java
ExecutorService poolA = newFixedThreadPool(10, threadFactory("Sched-A-%d"));
Scheduler schedulerA = Schedulers.from(poolA);
...
private ThreadFactory threadFactory(String pattern) {
    return new ThreadFactoryBuilder()
        .setNameFormat(pattern)
        .build();
}
````

<br>

### 잘못된 하나의 이벤트 병렬처리
````java
Observable<BigDecimal> totalPrice = Observable
    .just("bread", "butter", "milk", "tomato", "cheese")
    .subscribeOn(schedulerA)
    .flatMap(prod -> rxGroceries.purchase(prod, 1))
    .reduce(BigDecimal::add)
    .single();
````

<br>

### 올바른 하나의 이벤트 병렬처리
````java
Observable<BigDecimal> totalPrice = Observable
    .just("bread", "butter", "milk", "tomato", "cheese")
    .flatMap(prod -> rxGroceries
        .purchase(prod, 1)
        .subscribeOn(schedulerA))
    .reduce(BigDecimal::add)
    .single();
  ````

<br>

## 선언적 동시성 처리
observeOn() 메서드 이후에 발생하는 다운스트림 Subscriber를 호출할 때 어떤 Scheduler를 사용할지 제어  
subscribeOn() 메서드로 구독 시작할 스케줄러 선택, 이후 observeOn() 메서드로 스케줄러 변경  
두 메서드 모두 생산자와 소비자를 물리적으로 분리하고자 할 때 잘 작동  

````java
log.info("start");
Observable<String> obs = Observable.create(subscriber -> {
    log.info("subscribe");
    subscriber.onNext("A");
    subscriber.onNext("B");
    subscriber.onNext("C");
    subscriber.onNext("D");
    subscriber.onCompleted();
});
log.info("create");
obs.subscribeOn(schedulerA)
    .flatMap(record -> store(record).subscribeOn(schedulerB))
    .observeOn(schedulerC)
    .subscribe(
        x -> log.info("get: " + x),
        Throwable::printStackTrace,
        () -> log.info("complete")
    );
log.info("exit");

Observable<UUID> store(String s) {
    return Observable.create(subscriber -> {
        log.info("storing " + s);
        ...
        subscriber.onNext(UUID.randomUUID());
        subscriber.onCompleted();
    });
}
````
````
26   | main | start
93   | main | create
121  | main | exit

122  | Sched-A-0 | subscribed
124  | Sched-B-0 | storing A
124  | Sched-B-1 | storing B
124  | Sched-B-2 | storing C
124  | Sched-B-3 | storing D

1136 | Sched-C-1 | get: 44b8b999-e687-485f-b17a-a11f6a4bb9ce
1136 | Sched-C-1 | get: 532ed720-eb35-4764-844e-690327ac4fe8
1136 | Sched-C-1 | get: 13ddf253-c720-48fa-b248-4737579a2c2a
1136 | Sched-C-1 | get: 0eced01d-3fa7-45ec-96fb-572ff1e33587
1137 | Sched-C-1 | complete
````

<br>


