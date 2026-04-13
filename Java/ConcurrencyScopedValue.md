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











