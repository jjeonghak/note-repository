# 스레드 풀
자바의 이그젝큐터 프레임워크가 바로 스레드 풀의 구현체  
스레드 풀은 애플리케이션이 시작될 때 미리 생성되어 계속 실행 중인 스레드들의 집합  
스레드 풀에는 태스크를 담아둘 큐가 존재하고 태스크가 큐에 들어오면 사용 가능한 스레드가 생기는 즉시 큐에서 태스크를 꺼내 실행  

<br>

스레드를 반복해서 생성하는 방식은 결국 운영체제가 허용하는 최대 스레드 수에 도달할 가능성 존재  
따라서 실행 중인 애플리케이션은 생성할 수 있는 스레드 개수에 대한 통제가 필수  
스레드 풀을 이용해서 매번 스레드를 생성하지 않고 이미 생성된 스레드를 재사용해서 응답속도가 빠름  

<br>

### 단순한 스레드 풀 구현

```java
public class SimpleThreadPool implements AutoCloseable {
  private final BlockingQueue<Runnable> queue;
  private final ThreadGroup threadGroup;
  private volatile boolean running = true;

  public SimpleThreadPool(int poolSize, int queueSize) {
    Worker[] threads = new Worker[poolSize];
    this.queue = new LinkedBlockingQueue<>(queueSize); // 스레드 안전성이 보장되는 방식
    this.threadGroup = new ThreadGroup("SimpleThreadPool");

    for (int i = 0; i < poolSize; i++) {
      threads[i] = new Worker(threadGroup, "Worker-" + i);
      threads[i].start(); // 생성과 동시에 태스크 대기/수행
    }
  }

  public void submit(Runnable task) {
    try {
      queue.put(task); // 큐가 가득 차면 블로킹, 자연스럽게 배압 역할 수행
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }

  public void shutdown() {
    this.running = false;
    threadGroup.interrupt(); // 그룹 내의 모든 스레드에 인터럽트 신호 전달
  }

  @Override
  public void close() {
    while (!queue.isEmpty()) {
      try {
        Thread.sleep(100);
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        return;
      }
    }
    shutdown();
  }

  class Worker extends Thread {
    public Worker(ThreadGroup threadGroup, String name) {
      super(threadGroup, name);
    }
  
    @Override
    public void run() {
      while (running) {
        try {
          Runnable task = queue.take();
          task.run();
        } catch (InterruptedException e) {
          // 풀은 인터럽트를 사용해서 셧다운하지 않음
          // 인터럽트 발생 시 현재 스레드만 인터럽트
          Thread.currentThread().interrupt();
        }
      }
    }
  } 
}
```

```java
public class SimpleThreadPoolDemo {
  public static void main(String[] args) throws InterruptedException {
    try (var threadPool = new SimpleThreadPool(4, 100) {
      for (int i = 0; i < 100; i++) {
        int finalI = i;
        threadPool.submit(() -> runTask(finalI));
      }
    }

    Thread.sleep(10_000);
    System.out.println("Main thread finished");
  }

  private static void runTask(int id) {
    System.out.printf("Task %d on %s\n", id, Thread.currentThread().getName());
    try {
      Thread.sleep(100);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }
}
```

```
Task 1 on Worker-2
Task 0 on Worker-0
Task 2 on Worker-3
Task 3 on Worker-1
```

<br>

### 이그제큐터 프레임워크
공통 인터페이스인 `ExecutorService`를 구현하는 다양한 구현체와 팩토리 클래스 `Executors` 존재  
`Executors` 클래스의 여러 팩토리 메서드는 각자의 목적에 맞게 설정된 인자를 `ThreadPoolExecutor` 생성자에게 전달하고 생성  

```java
public ThreadPoolExecutor(int corePoolSize,
                          int maximumPoolSize,
                          long keepAliveTime,
                          TimeUnit unit,
                          BlockingQueue<Runnable> workQueue,
                          ThreadFactory threadFactory,
                          RejectedExecutionHandler handler){}
```

- corePoolSize: `allowCoreThreadTimeout` 설정이 없는 한, 대기 중일 때도 유지되는 스레드 최소 개수  
- maximumPoolSize: 풀에 허용되는 스레드 최대 개수  
- keepAliveTime: 스레드 수가 `corePoolSize`보다 많을 때 초과된 유휴 스레드가 대기 가능한 최대 시간  
- unit: `keepAlivetime` 시간 단위  
- workQueue: 태스크가 보관되는 큐  
- threadFactory: 새로운 스레드를 생성할 때 사용하는 팩토리  
- handler: 스레드 수와 큐 용량 한계에 도달한 상황을 처리하는 핸들러  

<br>

스레드 풀 설정에서 코어 풀 크기와 최대 풀 크기 고려가 필수  
코어 풀 크기는 스레드가 아무 일도 하지 않고 대기 중이라도 항상 풀 안에 유지되는 최소한의 스레드 수  
최대 풀 크기는 스레드 풀이 가질 수 있는 활성 스레드의 상한선  
CPU 집중적인 작업이 많다면 스레드 수는 가능한 CPU 코어 수와 맞추는 것 권장  
반면 I/O 집중적인 작업이 많다면 CPU 코어 수보다 많은 스레드 권장  

<br>

### 이그제큐터 스레드 풀 

1. FixedThreadPool  
스레드의 개수가 고정되어 있는 풀  
활성 스레드 개수를 일정하게 유지하므로 작업 부하의 규모를 예측 가능할 때 유용  
동시에 일정한 수의 스레드가 작업을 수행해야 하는 애플리케이션에 적합  

2. CachedThreadPool  
이전에 생성된 스레드가 유휴 상태이면 재사용하고 아니면 새 스레드를 동적으로 생성  
태스크 양에 따라 자동으로 확장 또는 축소 가능  
짧은 시간 동안 수행되는 태스크를 굉장히 많이 처리하거나 태스크가 불규칙하게 몰리는 상황에 적합  

3. ScheduledThreadPoolExecutor  
지연된 시간 후 실행되거나 일정한 간격으로 반복 실행되도록 태스크를 스케줄링  
주기적인 유지보수 작업과 같이 정기적으로 반복실행해야 하는 태스크에 적합  
수동적인 개입 없이도 태스크가 지정된 빈도로 실행되도록 보장  

4. WorkStrealingPool  
`Work-Strealing` 알고리즘을 사용해서 스레드 사이의 작업 부하를 동적으로 분산  
작고 독립적인 태스크가 굉장히 많은 상황에서 CPU 코어 사용률을 극도로 높여할 때 적합  

<br>

## ForkJoinPool
`ExecutorService` 인터페이스를 구현했지만 전통적인 `ThreadPoolExecutor`와는 핵심 설계와 원리 차이  
`Wrok-Stealing` 매커니즘을 사용하며 각 스레드는 자신의 태스크 큐를 보유  

<br>

기존 스레드 풀은 공유 큐에 태스크를 넣고 대기 중인 유후 스레드가 공유 큐에 있는 태스크를 경쟁  
기존 스레드 풀은 락이나 조건 변수 같은 명시적 동기화 기법에 의존  
기존 스레드 풀은 태스크 사이의 의존성을 인식하지 못함  

<br>

### 가상 스레드와 ForkJoinPool

<img width="550" height="450" alt="fork_join_pool" src="https://github.com/user-attachments/assets/612c3bbf-7fb7-4c1c-9ba2-8866eaf821f7" />

각 워커 스레드는 데크(`deque`)로 만들어진 자신만의 작업 큐를 보유  
태스크를 `LIFO` 방식으로 관리, 하지만 다른 스레드에서는 태스크를 `FIFO` 방식으로 훔처옴  
워커 스레드에 속하지 않은 외부 스레드는 태스크를 제출 큐를 통해 제출  
동기화를 위해 명시적으로 락을 사용하는 대신 비교 후 교체(`CAS`) 같은 원자적 연산을 이용해서 관리  
CPU는 최근에 접근한 데이터를 저장하는 캐시 보유  

<br>

한 가지 주의할 점은 작업을 작은 단위로 나누는 일은 직접 개발자가 수행  
하나의 태스크가 여러 개의 서브태스크로 분할되며 서브태스크 실행이 완료되면 부모 태스크는 조인 과정을 통해 하나의 결과 생성  
이때 부모 태스크가 서브태스크 실행을 기다리는 동안 해당 워커 스레드는 자신의 큐에 남은 다른 태스크 처리  

<br>

사용 범위가 확장되면서 이벤트 스타일의 태스크처럼 서로 독집적으로 실행되며 결과를 합치지 않는 태스크에도 사용  
비동기 모드로 `ForkJoinPool`을 생성 가능하며 이때 `FIFO` 방식으로 전환  
`Executors.newWorkStealingPool()`을 사용해도 비동기 모드의 `ForkJoinPool` 생성  

```java
public class AsyncModeExample {
  public static void main(String[] args) {
    try (ForkJoinPool forkJoinPool = new ForkJoinPool(
      4, ForkJoinPool.defaultForkJoinWorkerThreadFactory, null, true
    )) {
      for (int i = 0; i < 10; i++) {
        forkJoinPool.submit(new EventTask("Event-" + i));
      }
    }
  }

  record EventTask(String eventName) implements Runnable {
    public void run() {
      System.out.println("Processing" + eventName + " in thread:" _ Thread.currentThread().getName());
      try {
        Thread.sleep(1000);
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
      }
      System.out.println("Completed " + eventName + " in thread:" + Thread.currentThread().getName());
    }
  }
}
```

<br>

## 컨티뉴에이션
프로그램의 현재 실행 상태를 저장하고 중단된 이후 중단 지점에서 다시 이어서 실행할 수 있는 기능  
직접 사용하는 것은 권장되지 않음  
또한 `Continuation`과 `ContinuationScope` 클래스는 공개된 자바 API가 아니기 때문에 실행시 JVM 옵션 필요  

```
--add-exports java.base/jdk.internal.vm=ALL-UNNAMED
```

```java
public class ContinuationExample {
  public static void main(String[] args) {
    ContinueationScope scope = new ContinuationScope("main");
    Continuation continuation = new Continuation(scope, () -> {
      System.out.println("Start from continuation");
      Continuation.yield(scope);
      System.out.println("Again from continuation");
      Continuation.yield(scope);
      System.out.println("Done from continuation");
    });

    System.out.println("Before starting continuation");
    continuation.run();
    System.out.println("After starting continuation");
    continuation.run();
    System.out.println("After starting continuation again");
    continuation.run();
  }
}
```

```
Before starting continuation
Start from continuation
After starting continuation
Again from continuation
After starting continuation again
Done from continuation
```

<br>

<img width="500" height="250" alt="continuation1" src="https://github.com/user-attachments/assets/7e9b429e-cda7-47aa-9cf7-538a8ed26c7b" />

<img width="500" height="200" alt="continuation2" src="https://github.com/user-attachments/assets/08a3f16a-c6d1-429d-a908-801b22693448" />

<img width="500" height="200" alt="continuation3" src="https://github.com/user-attachments/assets/00f209f1-b835-456e-8aa5-6e41e4e7e031" />

컨티뉴에이션은 가상 스레드에서 실행되어 블로킹 I/O 연산을 만나면 `Continuation.yield(scope)` 메서드를 호출  
가상 스레드를 일시 정지시켜 캐리어 스레드로부터 언마운트되도록 유도  
가상 스레드가 언마운트될 때 스레드의 스택 프레임이 다른 곳으로 복사  
가상 스레드가 다시 마운트되면 다른 곳에 복사된 스택 프레임이 다시 스레드의 스택으로 복사  

<br>

<img width="500" height="200" alt="continuation4" src="https://github.com/user-attachments/assets/4b3223eb-adb9-494d-a4ca-46a71e44dae5" />

복사 작업에 대한 비용을 줄이기 위해 JVM은 지연 복사 메커니즘 구현  
컨티뉴에이션이 처음으로 일시 중단될 때는 전체 스택 프레임을 컨티뉴에이션 객체로 복사  
다시 재개될 때는 컨티뉴에이션에 있던 스택 프레임 전체가 아닌 일부만 프레임에 복사  
반환 배리어 메커니즘을 통해 함수가 반활될 때 필요한 프레임을 컨티뉴에이션 스택으로부터 복사해야 하는지 확인  

<br>

## 단순한 가상 스레드 구현
`Continuation API`를 이용해서 가상 스레드 동작 시뮬레이션 가능  

```java
public class NanoThread {
  public static final NanoThreadScheduler NANO_THREAD_SCHEDULER = new NanoThreadScheduler();
  private static final AtomicInteger COUNTER = new AtomicInteger(1);
  public static final ContinuationScope SCOPE = new ContinuationScope("nanoThreadScope");
  private final Contination continuation;
  private final int nid;

  private NaonThread(Runnable runnable) {
    this.nid = COUNTER.getAndIncrement();
    this.continuation = new Continuation(SCOPE, runnable);
  }

  public static void start(Runnable runnable) {
    var nanoThread = new NanoThread(runnable);
    NANO_THREAD_SCHEDULER.schedule(nanoThread);
  }

  public void run() {
    continuation.run();
  }

  public static NanoThread currentVThread() {
    return NanoThreadScheduler.CURRENT_NANO_THREAD.get();
  }

  @Override
  public String toString() {
    return "NanoThread-" + nid + "-" + Thread.currentThread().getName();
  }
}
```

```java
public class NanoThreadScheduler {
  public static final ThreadLocal<NanoThread> CURRENT_NANO_THREAD = new ThreadLocal<>();
  public static final ScheduledExecutorService IO_EVENT_SCHEDULER = Executors.newSingleThreadScheduledExecutor();
  private final ExecutorService workStealingPool = Executors.newWorkStealingPool(2);

  public void schedule(NanoThread nanoThread) {
    workStealingPool.submit(() ->{
      CURRENT_NANO_THREAD.set(nanoThread);
      nanoThread.run();
      CURRENT_NANO_THREAD.remove();
    });
  }
}
```

















