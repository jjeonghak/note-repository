# 가상 스레드
가상 스레드는 자바 가상머신 그자체에 의해 관리  
가상 스레드를 사용하면 수백만 개의 스레드를 생성해서 사용 가능  
캐리어 스레드(`carrier thread`) 위에서 실행되며 본질적으로 포크/조인 풀의 스레드 사용  
`Work-Strealing` 방식의 `ForkJoinPool` 기반이지만 선입선출 모드로 동작  

<br>

## 자바 스레드 유형
1. 플랫폼 스레드  
자바 등장 때부터 존재하던 네이티브 스레드  
운영체제에 의해 실행되는 무거운 스레드, 스케줄링과 관리를 운영체제에 의존  
자바 스레드와 커널 스레드 사이에 일대일 관계를 유지  

2. 가상 스레드  
사용자 모드 스레드 또는 경량 스레드라고 표현  
JDK 21부터 등장한 동시성 모델  
JVM에 의해 관리되며 직접적으로 커널 스레드와 매핑되지 않고 캐리어 스레드 풀을 공유  

<img width="450" height="400" alt="carrier_thread" src="https://github.com/user-attachments/assets/e34bbf1b-073f-4a5d-ad4c-0d555d25c611" />

<br>
<br>

가상 스레드는 플랫폼 스레드에 비해 적은 양의 시스템 자원을 소모  
CPU 사이클 낭비 없이 스케줄링 오버헤드 방지  
블로킹 연산을 수행할 때 불필요하게 시스템 자원을 점유하지 않고 캐리어 스레드에게 넘겨 다른 가상 스레드를 실행  
기존 코드베이스를 크게 변경하지 않고 사용 가능  

<br>

### 가상 스레드 생성
가상 스레드는 기본적으로 데몬 스레드  
가상 스레드를 생성한 메인 스레드 실행이 종료되면 JVM은 남아 있는 데몬 스레드도 함께 종료  

```java
public static void main(String[] args) throws InterruptedException {
  Thread vThread = Thread.startVirtualThread(() -> {
    System.out.println("Unleash massive parallelism with virtual threads");
  });
  vThread.join();
}
```

<br>

```java
// 빌더 패턴
var startedThread = Thread.ofVirtual()
  .start(() -> System.out.println("start virtual thread"));
startedThread.join();

// 생성과 실행 분리
var unstartedThread = Thread.ofVirtual()
  .unstarted(() -> System.out.println("unstarted virtual thread"));
unstartedThread.start();

// Executor 서비스 전환
try (var virtualExecutor = Excutors.newVirtualThreadPerTaskExecutor()) {
  Future<String> future = virtualExecutor.submit(this::callService);
  // future 처리
}
```

<br>

가상 스레드는 본질적으로 Thread 클래스 인스턴스이며 취소 역시 `interrupt()` 메서드로 가능  

```java
public class VirtualThreadInterruption {
  public static void main(String[] args) {
    Thread virtualThread = Thread.ofVirtual().start(() -> {
      try {
        System.out.println("Virtual thread started...");
        for (int i = 0; i < 5; i++) {
          System.out.println("Virtual thread working:" + i);
          Thread.sleep(1000);
        }
      } catch (InterruptedException e) {
        System.out.println("Virtual thread interrupted");
      }
    });

    try {
      Thread.sleep(2500);
    } catch (InterruptedException e) {}

    virtualThread.interrupt();
  }
}
```

<br>

모든 가상 스레드는 단 하나의 스레드 그룹에 속함  
다른 스레드 그룹을 가진 가상 스레드를 생성하는 API는 지원하지 않음  

```java
public class VirtualThreadGroupExample {
  public static void main(String[] args) throws InterruptedException {
    Set<ThreadGroup> threadGroups = new HashSet<>();

    for (int i = 0; i < 100; i++) {
      Thread vThread = Thread.ofVirtual().start(() -> {
        try {
          Thread.sleep(10);
        } catch (InterruptedException e) {
          thread.currentThread().interrupt();
        }
      });
      threadGroups.add(vThread.getThreadGroup());
    }

    Thread.sleep(1000);
    System.out.println("Unique thread groups: " + threadGroups.size());
    System.out.println("Thread group: " + threadGroups.iterator().next());
  }
}
```

```
Unique thread groups: 1
Thread group: java.lang.ThreadGroup[name=VirtualThreads,maxpri=10]
```

<br>

가상 스레드 우선순위는 `NORM_PRIORITY`로 정해짐  
기본적으로 데몬 스레드이기 때문에 `setDaemon` 메서드를 호출해도 아무런 효과 없음  
`setPriority` 메서드를 호출해도 가상 스레드 우선순위는 변화 없음  

<br>

### 처리량과 확장성
가상 스레드는 충분한 워밍업을 거치면 약 만개의 태스크 처리 가능  
리틀의 법칙(`Little's Law`)을 따르며 작업 속도가 빠른 것이 아닌 높은 동시성 처리 능력을 활용해서 처리량 증가  
- 높은 동시 작업수
- CPU 집중적이지 않은 작업 부하

<br>

<img width="450" height="50" alt="little_law" src="https://github.com/user-attachments/assets/9dc4474e-31c5-43fa-914f-28cbb0f9d9ca" />

리틀의 법칙은 지연 시간, 동시성, 처리량 사이에 수학적 관계를 설정  
동시성을 늘릴 수 없다면, 조작할 수 있는 변수는 지연 시간 단 하나  
하지만 가상 스레드를 통해 동시성을 확보해서 전통적인 스레딩 모젤의 제약을 벗어남  

```java
public class LittleLawExample {
  public static void main(String[] args) {
    int numTasks = 10000;
    int avgResponsetimeMillis = 500; // 평균 응답 시간
    Runnable ioBoundTask = () -> {
      try {
        Thread.sleep(Duration.ofMillis(avgResponseTimeMillis));
      } catch (InterruptedException e) {
        Thrad.currentThread().interrupt();
      }
    };

    System.out.println("=== Little's Law Throughput Comparison ===");
    System.out.println("Testing " + numTasks + " tasks with " + avgResponsetimeMillis + "ms latency each\n");

    benchmark("Virtual Threads", Executors.nexVirtualThreadPerTaskExecutor(), ioBoundTask, numTasks);
    benchmark("Fixed ThreadPool (100)", Executors.newFixedThreadPool(100), ioBoundTask, numTasks);
    benchmark("Fixed ThreadPool (500)", Executors.newFixedThreadPool(500), ioBoundTask, numTasks);
    benchmark("Fixed ThreadPool (1000)", Executors.newFixedThreadPool(1000), ioBoundTask, numTasks);
  }

  static void benchmark(String type, ExecutorService executor, Runnable task, int numTasks) {
    Instant start = Instant.now();
    AtomicLong completedTasks = new AtomicLong();

    try (executor) {
      IntStream.range(0, numTasks)
        .forEach(i -> executor.submit(() -> {
          task.run();
          completedTasks.incrementAndGet();
        }));
    }

    Instant end = Instant.now();
    long duration = Duration.between(start, end).toMillis();
    double throughput = (double) completedTasks.get() / duration * 1000;
    System.out.printf("%-25s - Time: %5dms, Throughput: %8.2f tasks/s%n", type, duration, throughput);
  } 
}
```













