# 스코프드 밸류
JDK 25부터 도입된 `ScopedValue`를 사용하면 값을 특정 스코프에 구조적 방식으로 바인딩하면서 컨텍스트와 일관성 유지 가능  
기존의 `ThreadLocal` 변수보다 간결하며 효율적  

<br>

## 컨텍스트 전달 부담
각 메서드 호출마다 파라미터를 계속 달고 다니는 파라미터 전달 문제 발생  
메서드 시그니처가 애플리케이션 로직과 무관한 프레임워크 세부 사항으로 오염되는 파라미터 오염 현상 발생  
새로운 데이터 추가시 컨텍스트를 전달하는 사용자 코드의 모든 메서드 시그니처 수정 강제  
사용자 코드와 프레임워크의 구현 세부 사항이 강하게 결합  

<br>

## ThreadLocal
위의 문제를 해결하기 위해 프레임워크 코드를 `ThreadLocal`을 사용해서 설계 가능  
사용자 코드는 특정 프레임워크에서만 사용하는 파라미터를 더 이상 신경 쓸 필요 없음  

```java
public class JobScheduler {
  private static final ThreadLocal<JobContext> jobContextHolder = new ThreadLocal<>();

  public void schedule(Job job, String JobName, Priority priority) {
    JobContext context = new JobContext(jobName, priority);
    try {
      jobContextHolder.set(context);
      runJob(job);
    } finally {
      jobContextHoler.remove();
    }
  }

  private void runJob(Job job) {
    job.execute();
  }

  public Object getJobMetadata(String key) {
    JobContext context = jobContextHoler.get();
    return (context != null) ? context.getMetadataValue(key) : null;
  }
}
```

<br>

### ThreadLocal 변수 한계
변경에 제약이 없기 때문에 `set()` 메서드를 호출해서 데이터를 변경 가능  
데이터가 언제 어디에서 변경되었는지 추적하기 어려움  
생애주기에도 제한이 없기 때문에 명시적으로 제거되지 않는 한 해당 스레드가 살아있는 동안 계속 유지  
일반적인 스레드에서는 문제 없어보이지만 스레드 풀을 사용할 때는 메모리 누수 문제 발생 가능  
`remove()` 메서드를 명시적으로 호출해서 제거 강제  

<br>

`InheritableThreadLocal`을 사용할 경우 자식 스레드는 부모 스레드의 값을 자동으로 상속  
편리해 보이지만 많은 자식 스레드가 생성되는 경우 메모리 오버헤드 발생  

```java
public class InheritanceOverheadExample {
  private static final InheritableThreadLocal<byte[]> LARGE_DATA = new InheritableThreadLocal<>();

  public static void main(String[] args) {
    LARGE_DATA.set(new byte[10_000_000]);
    for (int i = 0; i < 100; i++) {
      new Thread(() -> {
        // 자식 스레드마다 부모 스레드의 데이터에 대한 참조 복사
        byte[] inherited = LARGE_DATA.get();
        System.out.println("Child has access to " + inherited.length + " bytes");
      })
      .start();
    }
  }
}
```

<br>

## ScopedValue 핵심 구성요소
암시적 메서드 파라미터처럼 동작, 각 메서드 시그니처에 명시적으로 파라미터를 넣지 않고도 데이터 전달 가능  
- 불변성: 한번 값에 바인딩되면 생애주기 동안 값 변경 불가
- 스레드 제한적 바인딩: 현재 스레드에 한정되므로 스레드 사이에 의도치 않은 데이터 공유 방지
- 유한한 수명: 특정 코드 블록 실행 기간 동안만 유지, 블록 종료시 바인딩 해제

<br>

`static final` 필드로 선언해서 사용  
생성자가 의도적으로 `private` 선언, 외부 호출 불가능하기 때문에 반드시 팩토리 메서드를 사용해서 생성  

```java
private static final ScopedValue<String> NAME = ScopedValue.newInstance();
```

<br>

생성 후에는 `where()` 메서드를 사용해서 값을 바인딩  
`run()` 메서드를 사용해서 해당 스코프 안에서 코드 실행  

```java
ScopedValue.where(NAME, "duke").run(() -> doSomething());
```

<br>

이전의 `ThreadLocal` 사용 예제를 아래와 같이 변경 가능  

```java
public class JobScheduler {
  private static final ScopedValue<JobContext> CONTEXT = ScopedValue.newInstance();

  public void schedule(Job job, String jobName, Priority priority) {
    JobContext context = new JobContext(jobName, priority);
    ScopeValue.where(CONTEXT, context)  // 컨텍스트 값 바인딩
      .run(() -> runJob(job));  // 스코프 내에서 작업 실행
  }

  private void runJob(Job job) {
    job.execute();
  }

  public static JobContext getContext() {
    return CONTEXT.get();  // 정적 접근 제공
  }

  public static Object getJobMetadata(String key) {
    JobContext context = CONTEXT.get();
    if (context != null) {
      return context.getMetadataValue(key);
    }
    return null;
  }
}
```

<br>

### ScopedValue 실행
유한한 수명을 가지고 있으며 먼저 값을 설정하고 사용 가능  

```java
public static void main(String[] args) {
  ScopeValue<String> NAME = ScopedValue.newInstance();
  Runnable task = () -> {
    if (NAME.isBound()) {
      System.out.println("Name is bound: " + NAME.get());
    } else {
      System.out.println("Name is not bound");
    }
  };

  // Name is not bound
  task.run();  
}
```

<br>

값을 바인딩하고 실행하기 위해서는 `where()` 메서드와 `run()` 메서드 사용  

```java
public static void main(String[] args) {
  ScopedValue<String> NAME = ScopedValue.newInstance();
  Runnable task = () -> {
    if (NAME.isBound()) {
      System.out.println("Name is bound: " + NAME.get());
    } else {
      System.out.println("Name is not bound");
    }
  }

  // Name is bound: Bazlur
  ScopedValue.where(NAME, "Bazlur")
    .run(task);  
}
```

<br>

만약 스코프 내에서 바인딩 후 태스크를 실행하고 다시 독립적으로 태스크를 실행한 경우 바인딩 무시  
동적 스코프 내에서만 바인딩된 상태를 유지하기 때문에 `run()` 메서드 실행이 완료되면 자동 바인딩 해제  

```java
public static void main(String[] args) {
  ScopedValue<String> NAME = ScopedValue.newInstance();
  Runnable task = () -> {
    if (NAME.isBound()) {
      System.out.println("Name is bound: " + NAME.get());
    } else {
      System.out.println("Name is not bound");
    }
  }

  // Name is bound: Bazlur
  ScopedValue.where(NAME, "Bazlur")
    .run(task);  

  // Name is not bound
  task.run();
}
```

<br>

메인 스레드가 아닌 다른 스레드에서 태스크를 실행한 경우도 바인딩 무시  
`ScopeValue`는 새로 생성되는 스레드에 자동으로 상속되지 않음  

```java
public static void main(String[] args) throws InterruptedException {
  ScopedValue<String> NAME = ScopedValue.newInstance();
  Runnable task = () -> {
    if (NAME.isBound()) {
      System.out.println("Name is bound: " + NAME.get());
    } else {
      System.out.println("Name is not bound");
    }
  }

  Thread thread = Thread.ofPlatform().unstarted(task);
  ScopedValue.where(NAME, "Bazlur")
    .run(thread::start);

  // Name is not bound
  thread.join();
}
```

<br>

만약 메인 스레드가 아닌 새로 생성되는 스레드 내에서 바인딩하면 상속  

```java
public static void main(String[] args) throws InterruptedException {
  ScopedValue<String> NAME = ScopedValue.newInstance();
  Runnable task = () -> {
    if (NAME.isBound()) {
      System.out.println("Name is bound: " + NAME.get());
    } else {
      System.out.println("Name is not bound");
    }
  }

  Thread thread = Thread.ofVirtual().start(() -> {
    ScopedValue.where(NAME, "Bazlur")
      .run(task)
  });

  // Name is bound: Bazlur
  thread.join();
}
```

<br>

평문형 API를 제공하기 때문에 여러 개의 `ScopedValue`를 하나의 체인에 함께 바인딩 가능  

```java
public class MultiScopedExample {
  private static final ScopedValue<String> USER_ID = ScopedValue.newInstance();
  private static final ScopedValue<String> SESSION_ID = ScopedValue.newInstance();

  public static void main(String[] args) {
    ScopedValue.where(USER_ID, "user123")
      .where(SESSION_ID, "session456")
      .run(() -> performTask());
  }

  public static void performTask() {
    String userId = USER_ID.get();
    String sessionId = SESSION_ID.get();
    System.out.println("Performing task for user: " + userId + " in session: " + sessionId);
    logAction();
  }

  public static void logAction() {
    String userId = USER_ID.get();
    String sessionId = SESSION_ID.get();
    System.out.println("Logging action for user: " + userId + " in session: " + sessionId);
  }
}
```

<br>

만약 `ScopedValue`에 바인딩된 값이 없는 경우 `orElse`, `orElseThrow` 메서드로 기본값 또는 예외 처리 가능  

```java
public class ScopedValueDefaultsExample {
  private static final ScopedValue<String> USER_NAME = ScopedValue.newInstance();

  public static void main(String[] args) {
    String userNameUnbound = USER_NAME.orElse("Guest");
    System.out.println("No bouding -> user name defaults to: " + userNameUnbound);

    try {
      USER_NAME.orElseThrow(() -> new IllegalStateException("No user name bound yet!"));
    } catch (IllegalStateException e) {
      System.out.println("Caught exception: " + e.getMessage());
    }

    ScopedValue.where(USER_NAME, "Bazlur").run(() -> {
      String boundUserName = USERNAME.orElse("Guest");
      System.out.println("Within binding -> user name is: " + boundUserName);
      String validatedName = USEr_NAME.orElseThrow(() -> IllegalStateException("No user name bound yet!"));
      System.out.println("Validated name: " + validateName);
    });
  }
}
```

<br>

### 중첩 스코프 SocpedValue 리바인딩
리바인딩은 중첩된 스코프 안에서 동일한 이름으로 새롭게 값을 지정  
하지만 중첩된 스코프 안에서만 유효하도록 제한, 중첩된 스코프 종료시 원래 값으로 자동 복원  
넓은 컨텍스트에 영향을 미치지 않고 지엽적으로 실행 흐름 내에서만 설정을 조정하는 등에 유용  

```java
public class ScopedValueRebindingExample {
  private static final ScopedValue<String> USER_ROLE = ScopedValue.newInstance();

  public static void main(String[] args) {
    // 초기 스코프 바인딩
    ScopedValue.where(USER_ROLE, "Admin").run(() -> {
      System.out.println("Outer scope: User role is " + USER_ROLE.get());

      // 중첩 스코프 리바인딩
      ScopedValue.where(USER_ROLE, "Guest").run(() -> {
        System.out.println("Inner scope: User role is " + USER_ROLE.get());
      });

      System.out.println("Back to outer scope: User role is " + USER_ROLE.get());
    });
  }
}
```

```
Outer scope: User role is Admin
Inner scope: User role is Guest
Back to outer scope: User role is Admin
```

<br>

### ScopedValue 구조적 동시성
상속 메커니즘을 통해 데이터를 부모 자식 간 명시적으로 넘기지 않아도 효율적으로 공유 가능  
이는 구조적 동시성이 명확하게 정의된 경계를 가지기 때문에 자연스럽게 통합되어 동작  

```java
public class ScopedValueStructuredConcurrencyExample {
  private static final ScopedValue<String> USERNAME = ScopedValue.newInstance();

  public static void main(String[] args) {
    ScopedValue.where(USERNAME, "Bazlur").run(() -> doSomething());
  }

  public static void doSomething() {
    try (var scope = StructuredTaskScope.open()) {
      StructuredTaskScope.Subtask<String> task1 = scope.fork(() -> USERNAME.get() + " from task 1");
      StructuredTaskScope.Subtask<String> task2 = scope.fork(() -> USERNAME.get() + " from task 2");
      scope.join();
      String result1 = task1.get();
      String result2 = task2.get();
      System.out.println(result1);
      System.out.println(result2);
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
  }
}
```

<br>

### 성능 고려사항
가상 스레드를 사용할 때 `ThreadLocal`보다 `ScopedValue`가 전반적으로 더 나은 성능  
가상 스레드가 자신만의 복사본을 가져야 하므로 메모리 사용량이 급증하고 오버레드 유발 가능  
반면 `ScopedValue`는 특정 스코프 내에서만 스레드 사이에 데이터를 공유하기 때문에 메모리 사용 최소화  
가상 스레드의 가벼운 특성을 활용해서 기존 `ThreadLocal`에서 흔히 발생하는 병목 문제 해결  

<br>
