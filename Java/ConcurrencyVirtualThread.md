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

```
=== Little's Law Throughput Comparison ===
Testing 10000 tasks with 500ms latency each

Virtual Threads          - Time:   552ms, Throughput: 18115.94 tasks/s
Fixed ThreadPool (100)   - Time: 50381ms, Throughput:   198.49 tasks/s
Fixed ThreadPool (500)   - Time: 10106ms, Throughput:   989.51 tasks/s
Fixed ThreadPool (1000)  - Time:  5080ms, Throughput:  1968.50 tasks/s
```

<br>

## 가상 스레드 내부 동작 방식

### 스택 프레임과 메모리 관리
전통적인 스레드는 스택 프레임을 운영체제가 할당하는 일체형 메모리 블록에 저장  
반면 가상 스레드에 필요한 스택 크기는 가비지 컬렉션 대상이 되는 힙에 저장  
스레드에 필요한 스택 크기를 예측할 필요 없음  

<br>

운영체제는 가상 스레드의 존재를 알지 못하고 오직 플랫폼 스레드만을 인식  
가상 스레드에서 실행하기 위해 가상 스레드를 플랫폼 스레드에 마운트하고 이때 사용하는 플랫폼 스레드를 캐리어 스레드라고 표현  
캐리어 스레드는 특화된 `ForkJoinPool`의 일부  

<br>

일반적으로 스레드를 블로킹하는 연산을 만나면 캐리어 스레드로부터 언마운트 가능  
캐리어 스레드의 스택에 복사된 후 코드가 실행되면서 변경이 발생한 스택 프레임 내용이 다시 힙으로 복사  

<br>

### 투명성과 비가시성
가상 스레드를 마운트/언마운트하는 과정은 자바 코드에서 보이지 않음  
캐리어 스레드의 `ThreadLocal` 값조차 가상 스레드에게는 보이지 않음  
가상 스레드 개념은 가상 메모리 시스템과 유사하며 크기가 무제한인 주소 공간에 접근하는 듯한 환경 속에서 실행  

<br>

### 비동기 연산 단순화
결과가 나올 때까지 편안하게 블로킹하고 대기하더라도 과도한 자원을 소모하지 않음  

```java
public class ImageProcessingExample {
  public static void main(String[] args) throws InterruptedException, ExecutionException {
    try (var service = Executors.newVirtualThreadPerTaskExecutor()) {
      List<Callable<BufferedImage>> tasks = List.of(
        () -> resize("https://example.com/img1.jpg", 200, 200), // 이미지 다운로드 및 크기 변환
        () -> grayscale("https://example.com/img2.jpg"),        // 이미지 다운로드 및 흑백 처리
        () -> rotate("https://example.com/img3.jpg", 90)        // 이미지 다운로드 및 회전 변환
      );

      List<Future<BufferedImage>> results = service.invokeAll(tasks); // 모든 태스크를 동시에 제출

      int i = 1;
      for (Future<BufferedImage> future : results) {
        BufferedImage image = future.get(); // 블로킹, 결과를 받을 때까지 캐리어 스레드에게 제어권 넘김
        ImageIO.write(image, "jpg", new File("output_image" + i + ".jpg");
        i++;
      }
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }
}
```

<br>

### 구조적 동시성
구조적 동시성 API는 구조화된 영역 안에서 태스크를 실행하고, 태스크 실패시 모든 태스크 자동 취소  
`StructuredTaskScope` 사용시 실패 즉시 중단(`fail-fast`)되는 영역을 지정 가능  

```java
public static void main(String[] args) {
  try (StructuredTaskScope scope = StructuredTaskScope.open()) {
    StructuredTaskScope.Subtask<String> subtask1 = scope.fork(() -> fetchData("https://api1.example.com"));
    StructuredTaskScope.Subtask<String> subtask2 = scope.fork(() -> fetchData("https://api2.example.com"));
    scope.join();
    var result = subtask2.get() + subtask1.get();
    System.out.println(result);
  } catch (InterruptedException e) {
    throw new RuntimeException(e)l
  }
}
```

<br>

## 요청 제한을 통한 자원 제약 관리
애플리케이션은 백만 개의 요청을 수용가능하더라도 데이터베이스는 그렇지 않음  
자원에 특화된 요청 제한 메커니즘이 필요  

```java
public class ResourceAwareRateLimitExample {
  private static final HttpClient CLIENT = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(10))
    .build();
  private static final int MAX_PARALLEL = 10;
  private static final Semaphore gate = new Semaphore(MAX_PARALLEL); // 최대 동시 요청 개수를 지정한 세마포어
  private static final String API_URL = "https://api.chucknorris.io/jokes/random";

  public static void main(String[] args) throws Exception {
    Instant start = Instant.now();
    List<String> jokes = fetchJokes(50);
    long ms = Duration.between(start, Instant.now()).toMillis();
    System.out.printf("Fetched %d jokes in %d ms (avg %d ms)%n", jokes.size(), ms, ms / jokes.size());
    jokes.stream().limit(3).forEach(j -> System.out.println("• " + j));
  }

  private static List<String> fetchJokes(int n) throws Exception {
    try (ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor()) { // 제출된 요청 당 가상 스레드 생성
      List<Future<String>> futures = IntStream.range(0, n)
        .mapToObj(i -> pool.submit(ResourceAwareRateLimitExample::fetchJoke))
        .toList();
      return futures.stream()
        .map(ResourceAwareRateLimitExample::join)
        .toList();
    }
  }

  private static String fetchJoke() throws Exception {
    HttpRequest req = HttpRequest.newBuilder(URI.create(API_URL))
      .GET()
      .timeout(Duration.ofSeconds(30))
      .build();
    try {
      gate.acquire(); // 세마포어 락 획득
      HttpResponse<String> res = CLIENT.send(req, HttpResponse.BodyHandlers.ofString());
      if (res.statusCode() != 200) {
        throw new RuntimeException("API error: " + res.statusCode());
      }
      return parseJoke(res.body());
    } finally {
      gate.release(); // 세마포어 락 반납
    }
  }
}
```

<br>

### 자바의 세마포어
`java.util.concurrent` 패키지의 `Semaphore` 클래스를 사용해서 접근 제어 가능  
- `acquire()`: 출입증 요청, 이미 다 할당된 경우 대기
- `release()`: 출입증 반납
- `availablePermits()`: 현재 지급 가능한 출입증 개수 반환 

```java
public class ResourcePool {
  private final Semaphore semaphore;
  private final AtomicInteger activeConnections; // 현재 연결된 커넥션 개수 모니터링용
  private final AtomicInteger peakConnections;   // 실행 동안 관찰된 최대 동시 연결 개수

  public ResourcePool(int resourceCount) {
    this.semaphore = new Semaphore(resourceCount, true); // 세마포어 최대 한도 설정
    this.activeConnections = new AtomicInteger(0);
    this.peakConnections = new AtomicInteger(0);
  }

  public Optional<String> useResource(String query) {
    boolean acquired = false;
    try {
      acquired = sesmaphore.tryAcquire(5, TimeUnit.SECONDS); // 무기한 블로킹이 아닌 타임아웃 설정
      if (!acquired) {
        return Optional.empty();
      }
      int current  = activeConnections.incrementAndGet();
      peakConnections.updateAndGet(peak -> Math.max(peak, current));
      return queryDatabase(query); // 데이터베이스 연결
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      return Optional.empty();
    } finally {
      if (acquired) {
        activeConnections.decrementAndGet();
        semaphore.release();
      }
    }
  }
}
```

<br>

세마포어는 네트워크 소켓, 데이터베이스 연결 등 유한한 용량을 가진 모든 유형의 공유 자원에 대한 접근 제한에 이상적  
특정 코드 섹션을 동시에 실행하는 스레드 수를 정밀하게 관리 가능  
가상 스레드를 사용하면 블로킹 중에도 운영체제 자원을 소모하지 않아서 세마포어 기반 동기화 확장성이 좋음  
어떤 스레드가 출입증을 가지고 있는지 추적하지 않아서 어떤 스레드든지 해당 출입증 반납 가능  

<br>

### 가상 스레드 한계
가상 스레드는 고정(`pinning`)이라는 제약 사항 존재  
즉 가상 스레드가 자신의 캐리어 스레드에 묶여서 고정되는 상황  
고정된 상태에 빠진 가상 스레드는 블로킹 연산을 실행할 때 캐리어 스레드로부터 언마운트 불가(캐리어 스레드 독점)  
- `synchronized` 블록 사용: 가상 스레드가 해당 블록에 진입하면 캐리어 스레드에 고정  
- 네이티브 메서드: 가상 스레드가 네이티브 메서드나 외부 함수를 실행하는 경우 캐리어 스레드에 고정  

<br>

`synchronized` 블록이나 메서드 대신 `ReentrantLock`을 사용하면 고정되지 않음  
네이티브 메서드 사용은 개발자가 식별하고 최소화 필수  

<br>

```java
public class ThreadPinnedExample {
  private static final Object lock = new Object();

  public static void main(String[] args) {
    List<Thread> threadList = IntStream.range(0, 10)
      .mapToObj(i -> Thread.ofVirtual().unstarted(() -> {
        if (i ==0) {
          System.out.println(Thread.currentThread()); // 블록 진입 전 캐리어 스레드 정보
        }

        synchronized (lock) {
          try {
            Thread.sleep(25);
          } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
          }
        }

        if (i == 0) {
          System.out.println(Thread.currentThread()); // 블록 탈출 후 캐리어 스레드 정보
        }
      }))
      .toList();

      threadList.forEach(Thread::start);
      threadList.forEach(t -> {
        try {
          t.join();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
        }
      });
  }
}
```

```
VirtualThread[#21]/runnable@ForkJoinPool-1-worker-1
VirtualThread[#21]/runnable@ForkJoinPool-1-worker-1
```

<br>

### ReentrantLock 사용을 통한 고정 해결
해당 락을 사용하면 가상 스레드 블로킹시 캐리어 스레드로부터 언마운트 허용  

```java
public class ThreadPinnedExample {
  private static final ReentrantLock lock = new ReentrantLock();

  public static void main(String[] args) {
    List<Thread> threadList = IntStream.range(0, 10)
      .mapToObj(i -> Thread.ofVirtual().unstarted(() -> {
        if (i ==0) {
          System.out.println(Thread.currentThread()); // 락 획득 전 캐리어 스레드 정보
        }

        lock.lock();
        try {
          Thread.sleep(25);
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
        } finally {
          lock.unlock();
        }
        
        if (i == 0) {
          System.out.println(Thread.currentThread()); // 락 반납 후 캐리어 스레드 정보
        }
      }))
      .toList();

      threadList.forEach(Thread::start);
      threadList.forEach(t -> {
        try {
          t.join();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
        }
      });
  }
}
```

```
VirtualThread[#20]/runnable@ForkJoinPool-1-worker-1
VirtualThread[#20]/runnable@ForkJoinPool-1-worker-3
```

<br>

### 네이티브 메서드 호출과 고정
JVM이 네이티브 코드 실행 검사 또는 제어가 불가하기 때문에 고정  
네이티브 코드는 스레드 간에 마이그레이션 불가한 스레드 로컬 상태를 보유 가능  
자바 스택 프레임처럼 저장하고 복원할 수 없고 운영체제 수준의 스레드 기본 요소와 직접 상호작용  

```java
public class ThreadPinnedNativeMethodExample {
  public static void main(String[] args) {
    List<Thread> threadList = IntStream.range(0, 10)
      .mapToObj(i -> Thread.ofVirtual().unstarted(() -> {
        if (i == 0) {
          System.out.println(Thread.currentThread()); // 네이티브 호출 전 캐리어 스레드 정보
        }
        int sum = invokeNativceAddNumbers(56, 11);
        if (i == 0) {
          System.out.println(Thread.currentThread()); // 네이티브 호출 후 캐리어 스레드 정보
        }
      })
      .toList();

      threadList.forEach(Thread::start);
      threadList.forEach(t -> {
        try {
          t.join();
        } catch (InterruptedException e) {
          Thread.currentThread().interrupt();
        }
      });
  }

  public static int invokeNativeAddNumbers(int a, int b) {
    try (Arena arena = Arena.ofConfined()) { // FFM API 방식의 네이티브 호출
      SymbolLookup lookup = SymbolLookup.libraryLookup(Path.of("libaddNumbers.dylib"), arena);
      MemorySegment memorySegment = lookup.find("addNumbers")
        .orElseThrow(() -> new RuntimeException("addNumbers function not found"));
      Linker linker = Linker.nativeLinker();
      FunctionDescriptor addNumbersDescriptor = FunctionDescriptor.of(
        ValueLayout.JAVA_INT,
        ValueLayout.JAVA_INT,
        ValueLayout.JAVA_INT
      );
      MethodHandle addNumbersHandle = linker.downcallHandle(memorySegment, addNumbersDescriptor);
      try {
        return (int) addNumbersHandle.invokeExact(a, b); // 네이티브 호출 동안 언마운트 불가
      } catch (Throwable e) {
        throw new RuntimeException(e.getMessage());
      }
    }
  }
}
```

```
VirtualThread[#20]/runnable@ForkJoinPool-1-worker-1
VirtualThread[#20]/runnable@ForkJoinPool-1-worker-1
```

<br>

## 가상 스레드 ThreadLocal
잠재적으로 수백만 개가 실행 가능한 가상 스레드에서 ThreadLocal 변수를 과도하게 사용하면 문제 발생  
- 메모리 소비: 여러 스레드가 각각 ThreadLocal 변수 복사본을 갖는 경우 메모리 사용량이 급격히 증가  
- 오버헤드: ThreadLocal 변수를 초기화하고 정리하는 작업에 오버헤드 발생  
- 상속: 부모 스레드로부터 ThreadLocal 값을 상속 가능, 이는 추적과 디버깅이 어려움  

<br>

```java
public class ThreadLocalExample {
  public static void main(String[] args) {
    ThreadLocal<LargeObject> threadLocal = ThreadLocal.withInitial(LargeObject::new);
    var threadList = IntStream.range(0, 1000)
      .mapToObj(i -> Thread.ofVirtual().unstarted(() -> {
        LargeObject largeObject = threadLocal.get();
        useIt(largeObject);
        sleep();
      }))
      .toList();

    threadList.forEach(Thread::start);
    threadList.forEach(thread -> {
      try {
        thread.join();
      } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
      }
    });
  }

  private static void useIt(LargeObject largeObjet) {
    System.out.println(largeObject.data.length);
  }

  private static void sleep() {
    try {
      Thread.sleep(Duration.ofMinutes(5));
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
  }

  static class LargeObject {
    private byte[] data = new byte[1024 * 500];
  }
}
```

<br>
