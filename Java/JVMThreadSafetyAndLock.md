# 스레드 안전성과 락 최적화

## 스레드 안전성
여러 스레드가 한 객체에 동시에 접근할 때 아래 두 조건을 모두 충족하면 스레드 안전  
- 특별한 스레드 스케줄링이나 대체 실행 수단을 고려할 필요 없음
- 추가적인 동기화 수단이나 호출자 측에서 조율 필요 없음

<br>

### 자바 언어의 스레드 안전성
자바 언어에서는 공유 데이터의 안전한 정도를 다섯 단계로 구분
- 불변
- 절대적 스레드 안전
- 조건부 스레드 안전
- 스레드 호환
- 스레드 적대적

<br>

불변이란 문자 그대로 변하지 않는다는 뜻, 아무런 장치 없이 스레드 안전  
자바 언어에서 기본 데이터 타입은 `final`로 정의되기만 하면 불변성이 보장  

<br>

절대적 스레드 안전은 스레드 안전성 정의를 완벽하게 충족  
자바 API에서 스레드 안전하다고 표시된 클래스 대부분이 절대적 스레드 안전을 의미하지 않음  
`java.util.Vector`는 모든 메서드가 `synchronized` 메서드이므로 스레드 안전  
하지만 호출자가 추가로 동기화할 필요가 절대로 없다는 뜻은 아님  

```java
public class VectorTest {
  private static Vector<Integer> vector = new Vector<Integer>();

  public static void main(String[] args) {
    while (true) {
      for (int i = 0; i < 10; i++) {
        vector.add(i);
      }

      Thread removeThread = new Thread(new Runnable() {
        @Override
        public void run() {
          synchronized (vector) { // 동기화 블록으로 감싸는 추가 조치 
            for (int i = 0; i < vector.size(); i++) {
              vector.remove(i);
            }
          }
        }
      });

      Thread printThread = new Thread(new Ruunable() {
        @Override
        public void run() {
          synchronized (vector) { // 동기화 블록으로 감싸는 추가 조치 
            for (int i = 0; i < vector.size(); i++) {
              System.out.println(vector.get(i));
            }
          }
        }
      });

      removeThread.start();
      printThread.start();

      while (Thread.activeCount() > 20);
    }
  }
}
```

<br>

조건부 스레드 안전은 일반적으로 스레드 안전하다라고 말할 때의 안전 수준  
단일한 작업을 별도 보호 조치 없이 스레드로부터 안전하게 수행  
하지만 특정 순서로 연달아 호출하는 상황에서도 정확성을 보장하려면 호출자에서 추가로 동기화 필수  
앞선 코드가 모두 조건부 스레드 안전한 예  

<br>

스레드 호환이란 객체 자체는 스레드로부터 안전하지 않지만 호출자가 적절히 조치하면 멀티스레드 환경에서도 안전하게 사용 가능  
이런 클래스는 일반적으로 스레드 안전하지 않다고 표현  
자바의 클래스 대다수가 이 분류에 속함  

<br>

스레드 적대적이란 호출자가 동기화 조치를 취하더라도 멀티스레드 환경에서 안전하게 사용 불가  
자바 언어는 초기부터 스레드를 지원한 덕분에 다행히 스레드 적대적 코드는 드물게 존재  
예시로 `Thread` 클래스의 `suspend()`와 `resume()` 메서드 존재  
메서드를 동기화해도 `suspend()`에 의해 블록된 스레드가 `resume()`을 실행하려는 스레드라면 반드시 교착 상태에 빠짐  

<br>

### 스레드 안전성 구현
상호 배제(`mutual exclusion`) 동기화는 가장 일반적이면서 중요한 동시성 보장 수단  
뮤텍스가 대표적인 동기화 수단이며, 임계 영역과 세마포어도 상호 배제 구현에 흔히 사용  
상호 배제 동기화라는 말에서 상호 배제가 원인 또는 수단이고, 동기화는 결과 또는 목적  

<br>

`synchronized`를 컴파일하면 `monitorenter`와 `monitorexit` 두 가지 바이트코드 명령어가 생성, 각각 동기화 블록 전후에 실행  
두 명령어 모두 락으로 사용할 객체를 참조 타입 매개 변수로 받음  
객체 참조를 명시하지 않는 경우 키워드가 위치한 메서드가 무엇이냐에 따라 적절한 객체 선택  
- 같은 스레드라면 synchronized로 동기화된 블록에 다시 진입 가능, 즉 락을 이미 소유한 스레드는 여러 번 진입 가능
- 락을 소유한 스레드가 작업을 마치고 락을 해제할 때까지 다른 스레드의 진입을 무조건 차단
- 락을 소유한 스레드가 락을 해제하도록 강제할 방법이 없고, 락을 기다리는 다른 스레드를 인터럽트해서 깨울 방법도 없음

<br>

락을 소유한다는 것은 실행 비용 측면에서 상당히 무거운 작업  
플랫폼 스레드를 운영 체제 커널 스레드와 매핑하기 때문에 플랫폼 스레드를 정지하거나 깨우려면 운영 체제의 도움 필요  
이처럼 `synchronized`는 무거운 작업이라서 꼭 필요한 경우에만 제한적으로 이용  
자바 가상머신은 나름대로 최적화를 이용해 바쁜 대기(`busy waiting`, `spinning`)로 모드 전환이 자주 일어나지 않게끔 방지  

<br>

이외에도 개발자는 `java.util.concurrent.Lock` 인터페이스를 사용해서 논블록 구조의 상호 배제 동기화 구현 가능  
`ReentrantLock`이 가장 대표적인 구현체, 재진입이 가능한 락  
`synchronized`와 매우 비슷하지만 대기 중 인터럽트, 페어 락, 둘 이상 조건 지정 등 진보된 기능 제공  
- 대기 중 인터럽트: 락을 소유한 스레드가 락을 해제하지 않을 때 같은 락을 얻기 위해 대기 중인 다른 스레드가 락 포기 가능
- 페어 락: 같은 락을 얻기 위해 대기하는 스레드가 획득을 시도한 시간 순서대로 락을 얻음, `synchronized`는 언페어 락
- 둘 이상 조건 지정: 동시에 여러 개의 `Condition` 객체와 연결 가능, `synchronized`의 경우 또 다른 락 추가 필수

<br>

<img width="500" height="450" alt="synchronized_and_lock" src="https://github.com/user-attachments/assets/ffc1b654-3894-4b38-a254-892c8fc75f86" />

`synchronized`는 멀티스레드 환경에서 성능이 급격히 떨어짐  
그에 반해 `ReentrantLcok`은 상대적으로 안정적으로 유지  
JDK 6 `synchronized` 최적화 이후로 두 방식의 성능이 거의 유사  

<br>

두 방식을 모두 사용 가능한 상황이라면 여전히 `synchronized`를 권장
- 자바 구문 수준의 동기화 수단이며 매우 명확하고 간결
- `Lock`은 `finally` 블록에서 해제 필수, 락 해제를 개발자가 직접 보장
- 자바 가상머신이 스레드 및 락과 관련된 다양한 내부 정보를 활용 가능

<br>

### 논블로킹 동기화
상호 배제 동기화는 비관적 동시성 전략에 속함  
락과 동기화 장치가 없다면 반드시 문제가 생길 것이라 가정하고 경합이 있든 없든 우선 락을 걸어 사용  
해당 방식은 사용자 모드에서 커널 모드로 전환되고 락 카운터를 계산한 뒤 블록된 스레드를 깨워야 하는지 확인하는 작업 추가 발생  

<br>

하드웨어 명령어 집합이 발전하면서 충돌 감지를 기반으로 작동하는 낙관적 동시성 전략 등장  
잠재적으로 위험할 수 있더라도 우선 작업을 진행하고 충동리 발생하면 보완 조치를 취함  
가장 흔한 보완 조치는 경합하는 공유 데이터가 없을 때까지 계속 재시도  

<br>

해당 전략이 하드웨어 명령어 집합에 의존적인 이유는 `작업 진행`과 `충돌 감지`라는 두 단계를 원자적으로 수행해야 했기 때문  
- `TAS(Test-and-Set)`: 검사와 지정
- `FAA(Fetch-and-Add)`: 폐치와 증가
- `Swap`: 교환
- `CAS(Compare-and-Swap)`: 비교와 교환
- `LL/SC(Load-Linked/Store-Conditional)`: 적재와 저장

<br>

JDK 5부터 자바 클래스 라이브러리도 CAS 연산을 사용  
`sun.misc.Unsafe` 클래스의 `compareAndSwapInt()`와 `compareAndSwapLong()`  
하지만 Unsafe 클래스는 사용자 프로그램이 아닌 부스트트랩 클래스 로더가 로드한 클래스만이 접근 가능  
`java.util.concurrent.AtomicInteger` 클래스의 `compareAndSet()`과 `getAndIncrement()`가 Unsafe의 CAS 연산  
사용자 프로그램에서는 리플렉션을 이요해서 Unsafe 접근 제한을 우회하거나 자바 클래스 라이브러리를 거쳐 간접적으로 사용  
JDK 9 이후부터 `VarHandle` 클래스를 통해 사용자 프로그램도 CAS 연산을 사용 가능  

```java
public class AtomicTest {
  public static AtomicInteger race = new AtomicInteger(0);

  public static void increase() {
    race.incrementAndGet(); // 원자적 증가
  }

  private static final int THREADS_COUND = 20;

  public static void main(String[] args) throws Exception {
    Thread[] threads = new Thread[THREADS_COUNT];
    for (int i = 0; i < THREADS_COUNT; i++) {
      threads[i] = new Thread[new Runnable() {
        @Override
        public void run() {
          for (int i = 0; i < 10000; i++) {
            increase();
          }
        }
      });
      threads[i].start();
    }

    // 다른 모든 스레드가 종료할 때까지 대기
    while (Thread.activeCount() > 1)
      Thread.yield();

    // 결과는 200,000
    System.out.println(race);
  }
}
```

<br>

```java
// AtomicInteger::incrementAndGet()
public final int incrementAndGet() {
  return U.getAndAddInt(this, VALUE, 1) + 1; // U는 Unsafe 타입 객체
}

// jdk.internal.misc.Unsafe::getAndAddInt()
public final int getAndAddInt(Object o, long offset, int delta) {
  int v;
  do {
    v = getIntVolatile(o, offset);
  } while (!weakCompareAndSetInt(o, offset, v, v + delta)); // CAS 연산 이용
  return v;
}
```

보다시피 CAS 연산을 이용하여 현재보다 하나 큰 값을 할당하려 끊임없이 시도  
논리적 허점은 처음 읽은 값이 A이지만 할당 준비 후에도 A라면 그 사이에 무슨 작업이 발생했는지 모른다는 것  
이러한 취약점을 CAS 연산의 `ABA` 문제라고 표현  
이러한 문제를 해결하기 위해 `AtomicStampedReference`를 통해 변수값을 버전 관리하여 정확성 보장  
만약 ABA 문제를 해결해야 한다면 원자적 클래스보다 기존 상호 배제 동기화 방식이 효율적  

<br>

### 동기화가 필요 없는 메커니즘
공유 데이터를 전혀 사용하지 않는 메서드라면 태생부터 스레드 안전  
- 재진입 코드: 순수 코드, 실행 중간에 아무 때나 끼어들어 다른 코드를 수행하고 와도 상관없는 코드
- 스레드 로컬 저장소: 데이터를 공유하는 다른 코드도 같은 스레드에서 수행됨을 보장한다면 동기화 불필요

<br>

조건에 해당하는 애플리케이션은 드물지 않음  
생산자-소비자 패턴처럼 큐를 사용하는 아키텍처 대부분은 큐를 소비하는 스레드 수를 하나로 제한  
Thread 객체는 `ThreadLocalMap` 객체를 하나씩 보유  

<br>

## 락 최적화
분석 결과 수많은 애플리케이션이 공유 데이터를 아주 잠깜만 잠갔다가 곧바로 해제  
이 찰나의 시간에 스레드를 블로킹하고 다시 재개하는 건 실질적인 의미 없음  
스레드를 멈추지 않고 루프를 돌게(`spin`)하는 것이 스핀 락  
스레드 전환 부하는 없애지만 프로세서 시간을 소비하는 부작용 존재  
잠시 잠긴 락에서는 효율적이지만 장시간 잠겨 있다면 큰 낭비 발생  
그래서 스핀 락이 대기하는 시간에 제한을 두고(기본 10 회) 제한된 횟수 이상 락을 얻지 못하면 블로킹  

<br>

JDK 6에서는 스핀 락을 최적화한 적응형 스핀(`adaptive spin`)을 도입  
스핀 시간이 고정되지 않고 같은 락의 이전 스핀 시간과 락 소유자의 상태에 따라 결정  
하나의 락 객체에서 스핀 락이 성공했다면 다음번 스핀도 성공할 가능성이 높다고 판단  

<br>

### 락 제거
코드 조각에서 런타입에 데이터 경합이 일어나지 않는다고 판단되면 가상머신의 JIT 컴파일러가 해당 락을 제거하는 최적화 기법  
코드 조각에서 힙 안의 모든 데이터가 탈출하지 않고 다른 스레드에서 접근하지 않는다고 판단된다면 스택에 있는 데이터처럼 취급  
변수의 탈출 여부를 판단하기 위해 복잡한 프로시저 간 분석 수행을 꼭 하는 이유는 간접 추가된 동기화 장치가 많기 때문  

```java
// 동기화 하지 않는 듯 보이는 코드 조각
public String concatString(String s1, String s2, String s3) {
  return s1 + s2 + s3;
}

// javac에 의해 변환된 코드 조각
public String concatString(String s1, String s2, String s3) {
  StringBuffer sb = new StringBuffer();
  sb.append(s1); // 내부에 synchronized 블록 존재
  sb.append(s2); // sb 객체가 락으로 사용되지만 바깥으로 탈출하지 않음을 확인 후 락 제거
  sb.append(s3);
  return sb.toString();
}
```

<br>

### 경량 락
경량 락은 JDK 6 때 추가된 동기화 메커니즘으로 운영체제의 뮤텍스를 이용한 기존 락보다 가벼움  
뮤텍스를 이용한 기존 락은 상대적으로 중량 락으로 표현  

<br>

<img width="500" height="250" alt="mark_word_and_rock" src="https://github.com/user-attachments/assets/3dd3ed70-2f12-4656-b669-181b3712fd01" />

핫스팟 헤더는 해시코드와 GC세대 등 런타임 데이터 저장 부분과 메서드 영역의 데이터 타입을 가리키는 포인터 저장 부분으로 구분  
효율적으로 사용하기 위해 마크 워드는 최소한의 공간만 사용하도록 고정되지 않은 길이  

<br>

<img width="500" height="200" alt="lock_record" src="https://github.com/user-attachments/assets/742b92f9-742a-4bc3-b082-a21dbeeb2bad" />

락 객체가 잠겨 있지 않다면 락 플래그(마크 워드 마지막 두 비트)는 `01`, 가장 먼저 스택 프레임에 락 레코드를 생성  
락 레코드는 사실상 현재 마크 워드의 복사본으로 소유한 락 객체를 저장하는 용도  
마크 워드의 락 플래그는 `00`으로 변경되어 객체의 경량 락 상태 표시  

<br>

<img width="500" height="200" alt="lock_record_2" src="https://github.com/user-attachments/assets/a2f71221-53d4-4fdc-b35b-9b83c5847e2e" />

이후 CAS 연산으로 락 객체의 마크 워드를 락 레코드를 가리키는 포인터로 변경  
현재 스레드가 락을 얻었음을 의미, 변경 실패는 같은 락 객체를 놓고 경합하는 스레드가 최소 하나 이상 존재한다는 의미  
둘 이상의 스레드가 경랍하는 상황이라면 경량 락은 더 이상 유효하지 않기 때문에 `10`으로 수정해 중량 락으로 확장  

<br>

### 편향 락
JDK 6 때 도입된 편향 락은 경합이 없을 때 데이터의 동기화 장치들을 제거하는 최적화 기법  
경량 락은 경합이 없을 경우 CAS 연산을 써서 뮤텍스 사용을 우회, 편향 락은 CAS 연산 조차 사용하지 않음  
편한 락에서 편향은 락을 마지막으로 썼던 스레드가 락을 찜해 둔다는 의미  
다음 번 실행 시까지 다른 스레드가 락을 가져가지 않으면 직전에 사용한 스레드는 다시 동기화할 필요 없음  

<br>

<img width="500" height="250" alt="lock_record_3" src="https://github.com/user-attachments/assets/9095ee70-642c-4b7e-9f79-e703294f555b" />

처음은 경략 락과 유사, 편향 모드를 `1`로 설정  
편향 락을 소유한 스레드는 이후 아무런 동기화 작업 없이 해당 동기화 블록에 진입 가능  
다른 스레드가 락을 얻으려 시도하면 즉시 편향 모드가 종료  

<br>
