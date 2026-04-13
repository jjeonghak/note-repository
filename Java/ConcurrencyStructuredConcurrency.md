# 구조적 동시성
여러 스레드에 나누어 분산된 태스크들 사이의 관계와 의존성 관리가 필요  
기존의 동시성 모델인 `ExecutorService`와 `Future`는 태스크의 위계 구조를 지원하지 않음  
구조적 동시성은 관련된 여러 태스크를 하나의 단일 작업 단위로 취급해서 이러한 문제를 해결하는 패러다임  
서브태스크의 생애주기를 부모 태스크에 종속시켜 동시 실행 구조를 명확하게 관리  

<br>

### 비구조적 동시성 문제
전통적인 자바 동시성은 태스크를 동시에 실행 가능하지만 태스크 간의 조율이 필요한 경우 사용하기 어려움  
비구조적 동시성은 태스크들을 서로 독립적인 존재로 취급, 그 사이의 관계나 의존성 무시  
스레드 덤프 같은 관측 도구를 사용하더라도 각 메서드 호출이 서로 관련 없는 스레드들의 스택으로만 표시되어 관계 파악 어려움  

<br>

### 구조적 동시성 API
어떤 태스크가 여러 개의 동시 실행 서브태스크를 생성한다면 그 서브태스크들은 모두 부모 태스크 코드의 동일한 지점으로 돌아옴  
부모 태스크는 서브태스크를 모니터링하고 완료될 때까지 대기하며 문제 발생시 개입  
태스크 집합 전체의 걸쳐 통합적으로 오류 처리와 취소를 핸들링 가능  
부모-자식 생애주기를 엄격하게 보장함으로써 스레드 누수 방지  

<br>

`java.util.concurrent` 패키지의 `StructuredTaskScope`를 이용해서 구조적 동시성 사용 가능  

```java
public sealed interface StructuredTaskScope<T, R> extends AutoCloseable {
  static <T> StructuredTaskScope<T, Void> open();
  <U extends T> StructuredTaskScope.Subtask<U> fork(Callable<? extends U> task);
  <U extends T> StructuredTaskScope.Subtask<U> fork(Runnable task);
}
```

<br>

<img width="550" height="200" alt="non_structured_concurrency_flow" src="https://github.com/user-attachments/assets/b9d9d6e7-614a-40b6-a8eb-199ad4a187be" />

기존의 비구조적 동시성을 사용한다면 기아 스레드 발생하는 구조  

<br>

```java
public ProductInfo fetchProductInfo(Long productId) {
  log("Fetching product & reviews for id: " + productId);

  try (var scope = StructuredTaskScope.open()) {
    StructuredTaskScope.Subtask<Product> productTask = scope.fork(() -> fetchProduct(productId));
    StructuredTaskScope.Subtask<List<Review>> reviewsTask = scope.fork(() -> fetchReviews(productId));
    scope.join();
    return new ProductInfo(productTask.get(), reviewsTask.get());
  } catch (InterruptedException | StructuredTaskScope.FailException e) {
    Thread.currentThread().interrupt();
    throw new ProductServiceException("Fetch failed for id: " + productId);
  }
}
```

```
08:04:55.492 main          : Attempting to fetch product info for ID: 1
08:04:55.497 main          : Fetching product & reviews for id: 1
08:04:55.506 VThread[#28]  : Fetching product id: 1
08:04:55.506 VThread[#30]  : Fetching reviews for id: 1
Exception in thread "main" java.util.concurrent.StructuredTaskScope$FailedException:
ca.bazlur.modern.concurrency.c04.exception.ProductServiceException: Product not found
at java.base/java.util.concurrent.StructuredTaskScopeImpl.
join(StructuredTaskScopeImpl.java:258
```

<br>

<img width="550" height="250" alt="structured_concurrency_flow" src="https://github.com/user-attachments/assets/ec4a560d-d8a5-4ce6-bad0-badd4e972b03" />

어느 한쪽이 실패하면 나머지 서브태스크는 자동으로 취소  
부모 태스크가 취소되면 스코프는 닫히고 2개의 서브태스크도 자동으로 종료  

<br>

### 관계와 생애주기
구조적 동시성은 `StructuredTaskScope`를 부모 컨테이너로 사용해서 그 안의 자식 서브태스크를 관리  
스코프 소유자는 `fork()` 메서드를 사용해서 동시 작업을 시작, 즉시 `SubTask` 핸들을 반환  
이후 스코프 소유자는 `join()` 메서드를 통해 합쳐진 결과는 `Subtask.get()`, `Subtask.exception()`으로 관리  

<br>

서브태스크가 작업을 종료하면 그 태스크를 실행하던 스레드는 `Joiner`의 `onComplete()` 메서드 호출  
최종 상태를 담고 있는 `Subtask` 핸들을 함께 전달  
스코프 소유자는 `join()` 메서드를 사용해서 서브태스크 정책이 만족될 때까지 대기  
기본 스코프에서는 모든 서브태스크가 성공적으로 완료되거나 하나라도 실패하면 `join()`이 반환되는 정책을 사용  
스코프가 닫힐 때 모든 서브태스크 스레드가 종료될 때까지 대기한 후 부모 스레드가 진행되도록 보장  

<br>

### Joiner를 통한 조인 정책
`Joiner`는 `join()` 메서드가 어떤 조건을 만족할 때 완료되는지, 어떤 결과를 반환할지 정의  

```java
public interface Joiner<T, R> {
  R result();
  Throwable exception();
  default boolean onFork(Subtask<? extends T> subtask) { ... }
  default boolean onCompleted(Subtask<? extends T> subtask) { ... }
}
```

<br>

### 공통적인 조인 정책
기본적으로 여러 정책이 적용된 정적 팩토리 메서드 제공  
- `Joiner.awaitAllSuccessfulOrThrow()`: 기본 정책, 하나라도 실패하면 스코프 취소
- `Joiner.anySuccessfulResultOrThrow()`: 하나가 성공한 경우 즉시 스코프 취소 후 결과 반환
- `Joiner.allSuccessfulOrThrow()`: 모든 서브태스크 종료를 대기한 후 수집된 결과를 `Stream` 형태로 제공
- `Joiner.awaitAll()`: 모든 서브태스크 대기, 성공 여부와 관계없이 모든 결과 반환
- `Joiner.allUntill(Predicate<Subtask> isDone)`: 사용자 정의 취소 조건 사용

<br>

### awaitAllSuccessfulOrThrow
`StructuredTaskScope.open` 메서드로 스코프를 생성하면 기본 정책으로 사용  
전부 성공 아니면 무효 관리 방식  
모든 작업이 성공했을 때만 이후 과정이 진행되도록 강제, 불완전하거나 일부만 처리된 상태로 잘못 진행되는 것을 방지  

```java
public ProductInfo fetchProductInfo(long productId, boolean shouldFail) throws InterruptedException {
  Instant start = Instant.now();
  try (var scope = StructuredTaskScope.open()) {
    StructuredTaskScope.Subtask<Product> productTask = shouldFail
      ? scope.fork(() -> fetchProductThatFails(productId))
      : scope.fork(() -> fetchProduct(productId));
    StructuredTaskScope.Subtask<List<Review>> reviewsTask = scope.fork(() -> fetchReviews(productId));
    log("... Scope joining. Waiting for subtasks...");
    scope.join();
    log("... Scope joined successfully.");

    return new ProductInfo(productTask.get(), reviewsTask.get());
  } catch (StructuredTaskScope.FailException ex) {
    log("... Scope join failed. A subtask throw an exception.");
    throw new RuntimeException("Failed to fetch product info", ex.getCause());
  } finally {
    Instant end = Instant.now();
    log("Total time taken: " + Duration.between(start, end).toMillis() + "ms");
  }
}
```

```
22:20:11.405 main          : --- Running Failure Scenario ---
22:20:11.406 main          : ... Expecting to fail almost instantly...
22:20:11.411 main          : ... Scope joining. Waiting for subtasks...
22:20:11.412 VThread[#34]  :  -> Fetching product details... (will fail)
22:20:11.412 VThread[#36]  :  -> Fetching product reviews... (will take 2s)
22:20:11.413 main          : ... Scope join failed. A subtask throw an exception.
22:20:11.414 main          : Total time taken: 7ms
22:20:11.414 main          :
Caught expected exception in failure scenario: Failed to fetch product info
22:20:11.414 main          : Cause: ca.bazlur.modern.concurrency.c04.exception.
ProductServiceException: Product ID 456 not found
```

<br>

### anySuccessfulResultOrThrow
여러 동시 실행 서브태스크 사이에서 경주(`race`) 상태로 경쟁  
가장 먼저 성공적으로 완료된 태스크를 승자로 선택하는 선착순 방식  
승자가 정해진 순간 조이너는 실행 중인 나머지 모든 서브태스크를 즉시 취소  

```java
public Product fetchProduct(long productId) {
  Instant start = Instant.now();
  try (var scope = StructuredTaskScope.open(StructuredTaskScope.Joiner.<Product>anySuccessfulResultOrThrow())) {
    scope.fork(() -> fetchProductFromDatabase(productId));
    scope.fork(() -> fetchProductFromCache(productId));
    scope.fork(() -> fetchProductFromAPI(productId));
    return scope.join();
  } catch (InterruptedException | StructuredTaskScope.FailedException e) {
    throw new RuntimeException(e);
  } finally {
    Instant end = Instant.now();
    log("Total time taken: %dms%n".formatted(Duration.between(start, end).toMillis()))l
  }
}
```

```
23:03:23.917 main          : --- Running Race Scenario ---
23:03:23.917 main          : ... Three tasks will race. Expecting to finish in
~500ms (the fastest task)...
23:03:23.923 VThread[#36]  :  -> Checking cache... (will take 500ms)
23:03:23.923 VThread[#38]  :  -> Calling external API... (will take 3s)
23:03:23.923 VThread[#34]  :  -> Querying database... (will take 2s)
23:03:24.429 VThread[#36]  :  <- Cache has the result
23:03:24.431 VThread[#34]  :  <- Database query was canceled.
23:03:24.431 VThread[#38]  :  <- API call was canceled.
23:03:24.439 main          : Total time taken: 513ms
23:03:24.442 main          : Race finished. result: Product[productId=123, source=Cache]
```

<br>

### allSuccessfulOrThrow
기본 정책과 동일하게 동작하지만 성공 결과를 더 편리하게 받아서 사용 가능  
전부 성공 아니면 무효 전략을 따르지만 반환값이 `java.util.Stream<Subtask<T>>`  
핸들이 포크된 순서대로 결과가 포함  

```java
public List<ValidatedUser> validateAllUsers(List<Long> userIds) throws InterruptedException {
  log("Validating a batch of " + userIds.size() + " users...");
  try (var scope = open(Joiner.<validatedUser>allSuccessfulOrThrow())) {
    var subtasks = userIds.stream()
      .map(id -> scope.for(() -> validateUserWithFailure(id)))
      .toList();
    var resultStream = scope.join();
    log("...All users validated successfully. Processing stream...");
    return resultStream
      .map(Subtask::get)
      .toList();
  } catch (FailedException ex) {
    log("...Validation failed for one of the users.");
    throw new RuntimeException("Batch validation failed.", ex.getCause());
  }
}
```

```
00:29:49.275 main          : --- Running Success Scenario ---
00:29:49.276 main          : Validating a batch of 4 users...
00:29:49.286 VThread[#39]  :  -> Validating user 4...
00:29:49.286 VThread[#36]  :  -> Validating user 2...
00:29:49.286 VThread[#34]  :  -> Validating user 1...
00:29:49.452 VThread[#39]  :  <- User 4 is valid.
00:29:49.614 VThread[#34]  :  <- User 1 is valid.
00:29:49.696 VThread[#36]  :  <- User 2 is valid.
00:29:49.697 main          : All users validated successfully. Processing stream
00:29:49.698 main          : Batch validation complete. Results:
00:29:49.701 main          : ValidatedUser[userId=1, status=VALID]
00:29:49.702 main          : ValidatedUser[userId=2, status=VALID]
00:29:49.702 main          : ValidatedUser[userId=4, status=VALID]
```

<br>

### awaitAll
모든 서브태스크의 성공 여부와 관계없이 완료될 때까지 대기  
해당 정책은 부수 효과가 중요하거나 일부 성공한 결과만이라도 처리해야 하는 경우 적합  
`join()` 메서드는 항상 null을 반환, 결과 수집보다 태스크 완료 여부에 더 초점  
가장 큰 특징은 장애 격리(`fault isolation`), 연결 처리 핸들러 오류로 인해 다른 연결로 장애 전파되지 않음  

```java
public void snedCritialAlert(String message) throws InterruptedException {
  log("Sending critical alert: " + message);

  try (var scope = open(Joiner.<Void>awaitAll())) {
    scope.fork(() -> {
      sendEmailNotification(message);
      return null;
    });
    scope.fork(() -> {
      sendSmsNotification(message);
      return null;
    });
    scope.fork(() -> {
      sendPushNotification(message);
      return null;
    });

    log("Waiting for all notification attempts to complete");
    Void result = scope.join();
    log("...All notification attempts completed.");
    logNotificationSummary();
  } catch (InterruptedException e) {
    log("...Notification sending was interrupted");
    Thread.currentThread().interrupt();
    throw e;
  }
}
```

```
04:59:39.852 main          : --- Running Notification Scenario ---
04:59:39.852 main          : Sending critical alert to all notification channels...
04:59:39.853 main          : Alert message: Database connection pool exhausted
04:59:39.857 main          : Waiting for all notification attempts to complete
04:59:39.857 VThread[#38]  :  -> Sending push notification...
04:59:39.857 VThread[#36]  :  -> Sending SMS notification...
04:59:39.857 VThread[#34]  :  -> Sending email notification...
04:59:39.970 VThread[#38]  :  <- Push notification sent successfully
04:59:40.088 VThread[#36]  :  <- SMS failed: Carrier gateway timeout
04:59:40.234 VThread[#34]  :  <- Email sent successfully
04:59:40.235 main          : ...All notification attempts completed.
```

<br>

### allUntil
사용자 지정 중단 조건을 정의 가능  

```java
public void performBackup(String data) throws InterruptedException {
  log("Starting backup to multiple locations...");

  try (var scope = open(Joiner.<BackupResult>allUntil(subtask -> {
    boolean shouldStop = hasSuccess.get();
    if (shouldStop) {
      log("Backup successful. Canceling other attempts...");
    }
    return shouldStop;
  }))) {
    scope.fork(() -> backupToCloud(data));
    scope.fork(() -> backupToUSB(data));
    scope.fork(() -> backupToNetwork(data));
    scope.join();

    if (hasSuccess.get()) {
      log("Backup completed successfully");
    } else {
      log("All backup attempts failed");
    }
  }
}
```

```
00:34:05.871 main          : Starting backup to multiple locations...
00:34:05.881 VThread[#28]  :  -> Backing up to cloud...
00:34:05.881 VThread[#32]  :  -> Backing up to network drive...
00:34:05.881 VThread[#30]  :  -> Backing up to USB...
00:34:06.184 VThread[#30]  :  <- USB backup failed
00:34:06.284 VThread[#32]  :  <- Network backup successful
00:34:06.286 VThread[#32]  : Backup successful. Canceling other attemps...
00:34:06.288 main          : Backup completed successfully
```

<br>

## 예외 처리
구조적 동시성의 예외 처리는 사용중인 `Joiner` 정책에 따라 명확한 패턴을 따름  
`joiner` 객체의 `result()` 메서드는 `join()` 메서드에 의해 호출되며 서브태스크 완료 결과 또는 예외를 반환  
예외인 경우 `StructuredTaskScope.FailedException`으로 감싸서 가장 먼저 실패한 서브태스크의 예외를 던짐  

<br>

### 기본적인 예외 처리
가장 흔한 패턴은 `try-catch`로 감싸서 `FailedException` 예외를 잡아서 처리  

```java
public String fetchUserData(String userId) {
  try (var scope = open(Joiner.<String>allSuccessfulOrThrow())) {
    var profileTask = scope.fork(() -> fetchUserProfile(userId))l
    var preferencesTask = scope.fork(() -> fetchUserPreferences(userId));
    var results = scope.join();
    return results.map(Subtask::get)
      .collect(Collectors.joining(", ");
  } catch (FailedException e) {
    log("Task failed: " + e.getCause().getMessage());
    return "Error: Unable to fetch user data";
  } catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    throw new RuntimeException("Operation interrupted", e);
  }
}
```

<br>

### 패턴 매칭을 활용한 예외 처리
여러 종류의 예외에 대해 각각 다른 복구 전략을 적용해야 하는 경우 사용  

```java
public OrderResult processOrder(String customerId, String productId, double amount) {
  try (var scope = open(Joiner.<String>allSuccessfulOrThrow())) {
    var paymentTask = scope.fork(() -> processPayment(customerId, amount));
    var inventoryTask = scope.fork(() -> checkAndReserveInventory(productId));
    var shippingTask = scope.fork(() -> calculateShipping(customerId, productId));
    var results = scope.join()
      .map(Subtask::get)
      .toList();
    String orderId = generateOrderId();
    return new OrderResult(orderId, "CONFIRMED", "Order confirmed successfully", true);
  } catch (FailedException e) {
    Throwable cause = e.getCause();
    return handleOrderProcessingError(cause); // 패턴 매칭 기반 예외 처리 핸들러
  } catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    throw new RuntimeException("Operation interrupted", e);
  }
}
```

```java
private static OrderResult handleOrderProcessingError(Throwable cause) {
  return switch (cause) {
    case PaymentDeclinedException pde -> new OrderResult(null, "PAYMENT_FAILED",
        """
        Your payment was declined, Please check your card details or try a different paymnet method.
        """,
        false
      );
    case InsufficientInventoryException iie -> new OrderResult(null, "OUT_OF_STOCK",
        """
        Sorry, this item is currently out of stock. We'll notify you when it becomes available.
        """,
        false
      );
    case ShipppingNotAvailableException snae -> new OrderREsult(null, "SHIPPING_UNAVAILABLE",
        """
        We can't ship to your address right now. Please contact customer service for alternatives.
        """,
        false
      );
    default -> new OrderResult(null, "SYSTEM_ERROR",
        """
        Something went wrong on our end. Please try again or contact support.
        """,
        false
      );
  };
}
```

<br>

### 전략적 예외 전파
예외를 상위 수준으로 전파하고 더 넓은 컨텍스트에서 에러를 처리하는 방식  
다양한 수준에서 서로 다른 책임이 연관되는 계층형 애플리케이션을 만들 때 적합  

```java
public List<String> fetchCriticalData(List<String> sources)
    thorws StructuredTaskScope.FailedException, InterrtuptedException {
  try (var scope = open(StructuredTaskScope.Joiner.<String>allSuccessfulOrThrow())) {
    var tasks = sources.stream()
      .map(source -> scope.fork(() -> fetchFromSource(source)))
      .toList();
    var result = scope.join();
    return results.map(StructuredTaskScope.Subtask::get)
      .toList();
  }
  // catch 블록 생략, 예외를 상위로 전파
}
```

```java
public void processDataWithCentralizedHandling() {
  try {
    var sources = List.of("source1", "source2");
    var data = fetchCriticalData(sources);
    log("Successfully fetched data: " + data);
  } catch (StructuredTaskScope.FailedException e) {
    log("Critical data fetch failed: " + e.getCause().getMessage());
    handleCriticalSystemFailure(e);
  } catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    log("Operation was interrupted");
  }
}
```

<br>

### 서브태스크 내부 예외 처리
특정 예외가 전체 작업 실패가 아닌 정의된 결과를 반환해야 하는 경우 사용  

```java
public List<ServiceResponse> gatherOptionalData(List<String> services) throws InterruptedException {
  try (var scope = open(Joiner.<ServiceResponse>allSuccessfulOrThrow())) {
    var tasks = service.stream()
      .map(service -> scope.fork(() -> fetchWithDefaults(service)))
      .toList();
    var results = scope.join();
    return results.map(Subtask::get)
      .toList();
  } catch (FailedException e) {
    // 서브태스크가 처리하지 못하고 예상치 못한 예외
    log("Unexpected failure: " + e.getCause().getMessage());
    throw new RuntimeException("System error", e);
  }
}
```

```java
private ServiceResponse fetchWithDefaults(String service) {
  try {
    String data = fetchServiceData(service);
    return new ServiceResponse(service, data, true);
  } catch (IOException e) {
    log("Network error for " + service + ": " + e.getMessage());
    return new ServiceResponse(service, "Default data", false);
  } catch (TimeoutException e) {
    log("Timeout for " + service + ": " + e.getMessage());
    return new ServiceResponse(service, "Cached data", false);
  } catch (Exception e) {
    log("Unexcepted error for " + service + ": " + e.getMessage());
    return new ServiceResponse(service, "Error", false);
  }
}
```

<br>

## 스코프 구성
기본적인 `open()` 또는 `open(Joiner)` 메서드로 생성하는 경우 아래 구성이 적용  
- 스레드 팩토리: 이름 없는 가상 스레드 생성
- 모니터링용 이름: 없음(익명 스코프)
- 타임아웃: 없음(작업 완료 또는 취소까지 무기한 동작)

<br>

더 정교한 제어가 필요한 경우 `Configuration API`를 이용해서 오버로딩 가능  

```java
static <T, R> StructuredTaskScope<T, R> open(Joiner<? super T, ? extends R> joiner,
    Function<Configuration, Configuration> configFunction) {
  return StructuredTaskScopeImpl.open(joiner, configFunction);
}
```

```java
sealed interface Configuration {
  Configuration withThreadFactory(ThreadFactory threadFactory);
  Configuration withName(String name);
  Configuration withTimeout(Duration timeout);
}
```

```java
try (var scope = open(Joiner.allSuccessfulOrThrow(),
    cf -> cf.withTimeout(Duration.ofSeconds(10)))) {
}
ThreadFactory factory = Thread.ofVirtual()
  .name("user-processor-", 0)
  .factory();
try (var scope = open(Joiner.allSuccessfulOrThrow(), cf -> cf
    .withThreadFactory(factory)
    .withTimeout(Duration.ofSeconds(30))
    .withName("my-scope"))) {
  ...
}
```

<br>

### 이름 있는 스레드
가장 보편적인 커스터마이징 방식으로 디버깅이나 모니터링을 위한 이름 부여 스레드 생성  

```java
public void processUserRequests(List<String> userIds) {
  ThreadFactory factory = Thread.ofVirtual()
    .name("user-processor-", 0)
    .factory();
  try (var scope = open(Joiner.<String>allSuccessfulOrThrow(),
      cf -> cf.withThreadFactory(factory))) {
    var tasks = userIds.stream()
      .map(userId -> scope.fork(() -> processUser(userId)))
      .toList();
    var results = scope.join()
      .map(Subtask::get)
      .toList();
    System.out.println("Processed users: " + results);
  } catch (FailedException | InterruptedException e) {
    System.out.println("Processing failed: " + e.getMessage());
  }
}
```

<br>

### 타임아웃 설정
무기한 대기 상황과 외부 서비스 응답 불가 상황을 빠르게 실패 처리 가능  

```java
public List<String> fetchDataWithTimeout(List<String> sources)
    throws TimeoutException, FailedException, InterruptedException {
  Duration timeout = Duration.ofSeconds(5);
  try (var scope = open(Joiner.<String>allSuccessfulOrThrow(), cf -> cf.withTimeout(timeout))) {
    var tasks = sources.stream()
      .map(source -> scope.fork(() -> fetchFromSource(source)))
      .toList();

    // join() 완료되기 전에 타임아웃 발생시 TimeoutException 던짐
    return scope.join()
      .map(Subtask::get)
      .toList();
  }
}
```

<br>

## 커스텀 조이너
커스텀 조이너는 `StructuredTaskScope.Joiner<T, R>` 인터페이스를 구현해서 생성 가능  

<br>

### 성공과 예외 모두 수집

```java
public class CollectingJoiner<T> implements StructuredTaskScope.Joiner<T, CollectingJoiner.Result<T>> {
  private final Queue<T> results = new ConcurrentLinkedQueue<>();
  private final Queue<Throwable> exceptions = new ConcurrentLinkedQueue<>();

  @Override
  public Result<T> result() {
    return new Result<>(
      results.stream().toList(),
      exceptions.stream().toList()
    );
  }

  @Override
  public boolean onComplete(StructuredTaskScope.Subtask<? extends T> subtask) {
    switch (subtask.state()) {
      case SUCCESS -> results.add(subtask.get());
      case FAILED -> exceptions.add(subtask.exception());
      case UNAVAILABLE -> exceptions.add(new RuntimeException("Task was cnaceled"));
    }
    return false;
  }

  public record Result<T>(List<T> successes, List<Throwable> failures) {
    public boolean hasFailures() {
      return !failures.isEmpty();
    }

    public int totalTasks() {
      return successes.size() + failures.size();
    }
  }
}
```

<br>

### 정족수 기반 완료

```java
public class QuorumJoiner<T> implements StructuredTaskScope.Joiner<T, Boolean> {
  private final int requiredSuccesses;
  private final AtomicInteger successCount = new AtomicInteger(0);
  private final AtomicInteger totalCount = new AtomicInteger(0);
  private volatile boolean quorumReached = false;

  public QuorumJoiner(int requiredSuccesses) {
    this.requiredSuccesses = requiredSuccesses;
  }

  @Override
  public Boolean result() {
    return quorumReached;
  }

  @Override
  public boolean onFork(StructuredTaskScope.Subtask<? extends T> subtask) {
    totalCount.incrementAndGet();
    return false;
  }

  @Override
  public boolean onComplete(StructuredTaskScope.Subtask<? extends T> subtask) {
    if (subtask.state() == StructuredTaskScope.Subtask.State.SUCCESS) {
      int currentSuccess = successCount.incrementAndGet();
      if (currentSuccess >= requiredSuccesses) {
        quorumReached = true;
        return true;
      }
    }
    return false;
  }

  public int getSuccessCount() {
    return successCount.get();
  }

  public int getTotalcount() {
    return totalCount.get();
  }
}
```

<br>

### 적응형 완료

```java
public class AdaptiveJoiner<T> implements StructuredTaskScope.Joiner<T, CollectingJoiner.Result<T>> {
  private final int minSampleSize;
  private final double maxFailureRate;
  private final Queue<T> successes = new ConcurrentLinkedQueue<>();
  private final Queue<Throwable> failures = new ConcurrentLinkedQueue<>();

  public AdaptiveJoiner(double maxFailureRate, int minSampleSize) {
    this.maxFailureRate = maxFailureRate;
    this.minSampleSize = minSampleSize;
  }

  @Override
  public CollectingJoiner.Result<T> result() {
    return new CollectingJoiner.Result<>(
      success.stream().toList(),
      failures.stream().toList()
    );
  }

  @Override
  public boolean onComplete(StructuredTaskScope.Subtask<? extends T> subtaks) {
    switch (subtask.state()) {
      case SUCCESS -> successes.add(subtask.get());
      case FAILED -> failures.add(subtask.exception());
      case UNAVAILABLE -> failures.add(new RuntimeException("Task canceled"));
    }
    int total = successes.size() + failures.size();
    if (total >= minSampleSize) {
      double failureRate = (double) failures.size() / total;
      return failureRate > maxFailureRate;
    }
    return false;
  }
}
```

<br>

### 요청 제한

```java
public class RateLimitedJoiner<T> implements StructuredTaskScope.Joiner<T, List<T>> {
  private final Semaphore semaphore;
  private final Queue<T> results = new ConcurrentLinkedQueue<>();
  private final Queue<Throwable> failures = new ConcurrentLinkedQueue<>();

  public RateLimitedJoiner(int maxConcurrentTasks) {
    this.semaphore = new Semaphore(maxConcurrentTasks);
  }

  @Override
  public boolean onFork(StructuredTaskScope.Subtask<? extends T> subtask) {
    try {
      semaphore.acquire();
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
    return false;
  }

  @Override
  public boolean onComplete(StructuredTaskScope.Subtask<? extends T> subtask) {
    switch (subtask.state()) {
      case SUCCESS -> results.add(subtask.get());
      case FAILED -> failures.add(subtask.exception());
      case UNAVAILABLE -> failures.add(new RuntimeException("Task canceled"));
    }
    semaphore.release();
    return false;
  }

  @Override
  public List<T> result() {
    return results.stream().toList();
  }
}
```

<br>

### 조건부

```java
public class ConditionalJoiner<T> implements StructuredTaskScope.Joiner<T, List<T>> {
  private final Supplier<Boolean> shouldContinue;
  private final Queue<T> results = new ConcurrentLinkedQueue<>();
  private final Queue<Throwable> failures = new ConcurrentLinkedQueue<>();

  public ConditionalJoiner(Supplier<Boolean> shouldContinue) {
    this.shouldcontinue = shouldContinue;
  }

  @Override
  public boolean onFork(StructuredTaskScope.Subtask<? extends T> subtask) {
    if (!shouldContinue.get()) {
      System.out.println("Condition failed, stopping new tasks");
      return true;  // 새로운 태스크가 실행되지 않도록 스코프 취소
    }
    return false;
  }

  @Override
  public boolean onComplete(StructuredTaskScope.Subtask<? extends T> subtask) {
    switch (subtask.state()) {
      case SUCCESS -> results.add(subtask.get());
      case FAILED -> failures.add(subtask.exception());
      case UNAVAILABLE -> failures.add(new RuntimeException("Task canceled"));
    }
    return false;
  }

  @Override
  public List<T> result() {
    return results.stream().toList();
  }

  public List<Throwable> getFailures() {
    return failures.stream().toList();
  }
}
```

<br>

## 메모리 일관성 효과
`StructuredTaskScope` 소유한 스레드에서 서브태스크를 포크하기 전에 실행된 동작은 항상 먼저 실행  
또한 서브태스크가 수행하는 동작은 그 서브태스크의 결과를 가져오는 동작보다 먼저 실행  
스코프 소유 스레드가 `fork()` 호출 전에 수행한 데이터 변경은 포크된 서브태스크에서 조회 가능 보장  
서브태스크에서 수행한 데이터 변경을 서브태스크 결과를 조회하는 시기에 조회 가능 보장  

<br>

## 중첩 스코프
`StructuredTaskScope` 역시 중첩해 사용함으로써 다층적인 서브태스크 위계 구조 생성 가능  
중첩 스코프(`nested scope`)는 태스크가 자연스럽게 여러 단계의 서브태스크로 나뉘는 복잡한 작업 흐름 관리에 유용  

<br>

<img width="550" height="350" alt="nested_scope" src="https://github.com/user-attachments/assets/6a99c493-d502-4c98-978f-3e3420adbe19" />

```java
public DocumentReport processDocument(String documentId) throws InterruptedException {
  try (var gatheringScope = open(StructuredTaskScope.Joiner.<String>allSuccessfulOrThrow())) {
    var headerTask = gatheringScope.fork(() -> fetchHeader(documentId));
    var bodyTask = gatheringScope.fork(() -> fetchBody(documentId));
    var metadataTask = gatheringScope.fork(() -> fetchMetadata(documentId));

    gatheringScope.join();
    return analyzeContent(haederTask.get(), bodyTask.get(), metadataTask.get());
  } catch (StructuredTaskScope.FailedException e) {
    throw new RuntimeException("Failed to gather document content", e);
  }
}

private DocumentReport analyzeContent(String header, String body, String metadata) throws InterruptedException {
  try (var analysisScope = open(StructuredScope.Joiner.allSuccessfulOrThrow())) {
    var wordCountTask = analysisScope.fork(() -> countWords(body));
    var sentimentTask = analysisScope.fork(() -> analyzeSentiment(body));
    var summaryTask = analysisScope.fork(() -> generateSummary(header, body, metadata));
    analysisScope.join();
    return new DocumentReport(
      wordCountTask.get(),
      sentimentTask.get(),
      summaryTask.get()
    );
  } catch (StructuredTaskScope.FailedException e) {
    throw new RuntimeException("Failed to analyze document content", e);
  }
}
```

<br>
