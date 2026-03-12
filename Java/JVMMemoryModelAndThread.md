# 자바 메모리 모델과 스레드

## 하드웨어에서의 효율과 일관성
단순히 프로세서의 컴퓨팅(연산)만으로 이루어지지 않고 적어도 메모리는 반드시 필요  
메모리 I/O 작업을 없애기는 매우 어렵고 중간에 캐시 계층을 하나 이상 설정  
하지만 캐시 일관성(`cache coherence`)이라는 새로운 문제 발생  

<br>

<img width="500" height="200" alt="cache_and_processor" src="https://github.com/user-attachments/assets/7ca8e19b-b7d2-48d7-b2e2-4e0f28f689da" />

일관성 문제를 해결하려면 프로세서가 캐시를 이용할 때 정해진 프로토콜 준수 필수  
메모리 모델은 특정 프로토콜을 이용하여 특정 메모리나 캐시를 읽고 쓰는 절차  
또한 비순차 실행 최적화로도 프로세서의 컴퓨팅 능력 향상 가능  

<br>

## 자바 메모리 모델
하드웨어와 운영 체제의 메모리 모델을 직접 사용하는 C/C++ 언어와 다르게 자바는 자체 메모리 모델을 정의  
여러 스레드가 메모리에 동시에 접근해도 모든 작업이 명확하게 이루어지도록 엄격하게 정의  

<br>

### 메인 메모리와 작업 메모리
자바 메모리 모델의 주된 목적은 프로그램에서 다양한 변수에 접근하는 규칙을 정하는 것  
자바 메모리 모델은 모든 변수가 메인 메모리에 저장된다고 규정  
각 스레드는 자체 작업 메모리를 보유, 작업 메모리는 프로세서의 캐시와 비슷한 역할  

<br>

<img width="500" height="200" alt="thread_work_memory" src="https://github.com/user-attachments/assets/e9068bda-ecf8-46ee-8902-847c11837e3a" />

메인 메모리와 작업 메모리 개념은 자바 힙, 스택, 메서드 영역과 아무런 관련 없는 구분 방식  
굳이 비교하자면 메인 메모리는 자바 힙 중 객체 인스턴스 데이터 부분, 작업 메모리는 가상 머신 스택 영역의 일부  
더 기본적인 수준에서는 메인 메모리는 하드웨어 메모리, 작업 메모리는 레지스터와 캐시에 대응  

<br>

### 메모리 간 상호 작용
메인 메모리에서 작업 메모리로 변수를 복사하고 작업 메모리 내용을 메인 메모리로 다시 동기화하는 과정  
- 잠금(`lock`): 메인 메모리에 존재하는 변수를 특정 스레드만 사용 가능한 상태로 변경
- 잠금 해제(`unlock`): 잠겨 있는 변수를 잠금 해제
- 읽기(`read`): 뒤이어 수행되는 적재 연산을 위해 메인 메모리 변수값을 특정 스레드의 작업 메모리로 전송
- 적재(`load`): 읽기 연산으로 메인 메모리에서 얻어온 값을 작업 메모리의 변수에 복사
- 사용(`use`): 작업 메모리의 변수값을 실행 엔진으로 전달
- 할당(`assign`): 실행 엔진에서 받은 값을 작업 메모리의 변수에 할당
- 저장(`store`): 뒤이어 수행되는 쓰기 연산을 위해 작업 메모리 변수값을 메인 메모리로 전송
- 쓰기(`write`): 저장 연산으로 작업 메모리에서 얻어온 값을 메인 메모리 변수에 기록

<br>

메인 메모리에서 작업 메모리로 변수를 복사하려면 읽기와 적재 순으로 수행  
반대로 작업 메모리의 변수를 다시 메인 메모리로 동기화하려면 저장과 쓰기 순으로 수행  
하지만 꼭 바로 이어서 수행될 필요없음  
- 읽기와 적재, 저장과 쓰기는 단독으로 수행 불가
- 스레드는 최근 할당 연산 버리기 불가, 즉 작업 메모리에서 변수값이 변경되면 메인 메모리로 동기화 필수
- 스레드는 작업 메모리의 데이터를 아무 이유 없이 메인 메모리로 동기화 불가
- 변수는 메인 메모리에서만 새로 발생 가능
- 작업 메모리에 있는 초기화되지 않은 변수를 바로 사용 불가, 즉 변수를 사용 또는 저장 전에 할당과 적재 필수
- 변수를 잠그면 작업 메모리의 변수값은 지워짐, 실행 엔진이 변수를 사용하려면 적재 또는 할당을 다시해서 변수값 초기화 필수
- 잠근 변수에 대해서 다른 스레드가 해제 연산 불가
- 잠금을 해제하려면 변수를 메인 메로리로 동기화 필수(저장과 쓰기)

<br>

### volatile 변수용 특별 규칙
자바 가상 머신이 제공하는 가장 가벼운 동기화 메커니즘  

<br>

모든 스레드에서 이 변수를 투명하게 조회 가능  
가시성을 보장, 즉 한 스레드가 값을 수정하면 다른 스레드들도 새로운 값을 즉시 조회 가능  
하지만 자바의 산술 연산자가 원자적이 아니라 완벽하게 안전하지 못함


```java
public class VolatileTest {
  public static volatile int race = 0;

  public static void increase() {
    // 명령어 한 개가 반드시 원자적으로 수행된다는 보장 없음
    race++;
  }

  public static final int THREADS_COUNT = 20;

  public static void main(String[] args) {
    Thread[] threads = new Thread[THREADS_COUNT];
    for (int i = 0; i < THREADS_COUNT; i++) {
      threads[i] = new Thread(new Runnable() {
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
    while (Thread.activceCount() > 1)
      Thread.yield();

    // 결과는 200,000보다 작은 값 출력
    System.out.println(race);
  }
}
```

<br>

해당 시나리오는 락을 활용하여 원자성 보장 필수  
- 연산 결과가 변수의 현재 값과는 무관하거나 변수의 값을 수정하는 스레드가 하나뿐임을 보장
- 다른 상태 변수와 관련한 불변성 제약 조건에 관여하지 않음

<br>

아래와 같은 시나리오에 매우 적합  

```java
volatile boolean shutdownRequested;

public void shutdown() {
  shutdownRequested = true;
}

public void doWork() {
  // shutdown 메서드가 실행되면 바로 종료됨을 보장
  while(!shutdownRequested) {
    // 비즈니스 로직
  }
}
```

<br>

명령어 재정렬 최적화를 방지  
일반 변수는 메서드 실행 중 할당 결과를 이용해야 하는 모든 위치에서 올바른 결과를 얻는다는 점만 보장  
변수 할당 작업의 실행 순서가 프로그램 코드 순서와 같다는 보장 없음  

```java
Map configOPtions;
char[] configText;

volatile boolean initialized = false;

// 스레도 A 실행
configOptions = new HashMap();
configText = readConfigFile(fileName);
processConfigOptions(configText, configOPtions);
initialized = true;

// 스레드 B 실행
while (!initialized) { // 스레드 A가 설정 초기화를 마칠 때까지 대기
  sleep();
}
doSomethingWithConfig();
```

<br>

### long과 double 변수용 특별 규칙




































