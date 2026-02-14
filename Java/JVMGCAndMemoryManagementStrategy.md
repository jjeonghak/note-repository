# 가비지 컬렉터와 메모리 할당 전략
동적 메모리 할당과 가비지 컬렉션 기술을 가장 처음 사용한 언어는 리스프  

<br>

## 대상 판단
가비지 컬렉터가 힙을 청소하기 위해서는 어떤 객체가 살아 있고, 죽었는지 판단 필요  

<br>

### 참조 카운팅 알고리즘
자바에서는 사용하지 않는 방식, 순환 참조(`circular reference`) 문제를 풀기 어려움  
객체가 가리키는 참조 카운터를 추가, 참조하는 곳이 늘어날 때마다 1씩 증가  
반대로 참조하는 곳이 사라질 때마다 1씩 감소, 카운터 값이 0이면 더는 객체 사용 안함  


```java
/**
 * VM Args:-Xlong:gc*
 * testGC() 메서드 종료시에도 두 객체 모두 회수
 */
public class ReferenceCountingGC {
  public Object instance = null;
  private static final int _1MB = 1024 * 1024;
  private byte[] bigSize = new byte[2 * _1MB];

  public static void testGC() {
    ReferenceCountingGC objA = new referenceCountingGC();
    ReferenceCountingGC objB = new referenceCountingGC();

    objA.instance = objB;
    objB.instance = objA;
    objA = null;
    objB = null;

    system.gc();
  }

  public static void main(String[] arg) {
    testGC();
  }
}
```

<br>

### 도달 가능성 분석 알고리즘
자바, C# 등 오늘날의 대부분 언어들은 도달 가능성 분석(`reachability analysis`) 알고리즘 사용  

<br>

<img width="450" height="250" alt="gc_root" src="https://github.com/user-attachments/assets/ac9ded1e-a6e4-4c71-8e8d-e20ef36de43f" />

GC 루트라고 하는 루트 객체들을 시작 노드 집합으로 사용  
시작 노드들에서 출발하여 참조하는 다른 객체들로 탐색, 만들어지는 경로가 참조 체인(`reference chain`)  
GC 루트로 사용할 수 있는 객체는 정해져 있고, 임시로 추가 가능  
- 가상 머신 스택에서 참조하는 객체
- 메서드 영역에서 클래스가 정적 필드로 참조하는 객체
- 메서드 영역에서 상수로 참조되는 객체
- 네이티브 메서드 스택에서 네이티브 메서드가 참조하는 객체
- 자바 가상머신 내부에서 사용하는 참조
- 동기화 락으로 잠겨 있는 모든 객체
- 자바 가상머신 내부 상황을 반영하는 `JMXBean: JVMTI`에 등록된 콜백 등

<br>

### 참조 종류
- 강한 참조(`strong reference`): new 키워드로 선언한 참조, 해당 참조 관계가 남아있다면 절대 회수 안함
- 부드러운 참조(`soft reference`): 해당 참조만 남은 객체는 메모리 오버플로 전에 두번째 회수를 위한 회수 목록에 추가
- 약한 참조(`weak reference`): 해당 참조만 남은 객체는 다음번 가비지 컬렉션까지만 생존
- 유령 참조(`phantom reference`): 객체 수명에 아무런 영향을 주지 않고, 해당 참조를 통해 인스턴스를 가져오는 것마저 불가, 회수 알림용으로만 사용
- 파이널 참조(`final reference`): 약한 참조와 유령 참조 사이, `finalize()` 메서드를 구현한 객체의 경우 해당

<br>

```java
public class FinalizeEscapeGC {
  public static FinalizeEscapeGC SAVE_HOOK = null;

  public void isAlive() {
    System.out.println("alive");
  }

  @Override
  protected void finalize() throws Throwable {
    super.finalize();
    System.out.println("apply finalize method");
    // 자신의 참조를 할당
    FinalizeEscapeGC.SAVE_HOOK = this;
  }

  public static void main(String[] args) throws Throwable {
    SAVE_HOOK = new FinalizeEscapeGC();

    // 첫번째 시도
    SAVE_HOOK = null;
    System.gc();
    Thread.sleep(500);
    if (SAVE_HOOK != null) {
      SAVE_HOOK.isAlive();
    } else {
      System.out.println("not alive");
    }

    // 두번째 시도
    SAVE_HOOK = null;
    System.gc();
    Thread.sleep(500);
    if (SAVE_HOOK != null) {
      SAVE_HOOK.isAlive();
    } else {
      System.out.println("not alive");
    }
  }
}
```

도달 불가능으로 판단된 객체는 바로 회수되지 않고 유예 단계를 거침(두번의 표시 과정)  
첫번째 표시는 종료자(`finalizer`)에 따라 `finalize()` 실행 필요 여부에 따라 `F-Queue` 대기열에 추가  
가상머신은 해당 대기큐 객체들의 `finalize()` 메서드를 실행만 시키고 대기하지 않음  
만약 해당 메서드 내부에서 다른 객체와 참조 체인이 생긴다면 두번째 표시 과정의 회수 대상 목록에서 제외  
하지만 어떤 객체든 시스템이 해당 메서드를 호출해 주는 것은 오직 한번(두번째부터는 그냥 회수)  
기존 C 개발자들을 위한 타협안일 뿐, JDK 9부터 해당 메서드는 폐기 대상으로 지정  


<br>

### 메서드 영역 회수
가비지 컬렉션이 메서드 영역을 반드시 청소하는 것은 아님  
메서드 영역의 가비지 컬렉션은 더 이상 사용되지 않는 상수와 클래스를 회수, 회수 전에 다음 세 조건 만족 확인  
- 클래스 인스턴스가 모두 회수되었는지
- 클래스 로더가 회수되었는지
- 리플렉션 기능으로 이 클래스 메서드를 이용하는 곳이 있는지

<br>

## 가비지 컬렉션 알고리즘
객체 생사를 판별하는 방식을 기준으로 참조 카운팅 GC와 추적 GC로 분류  
이 둘은 직접 가비지 컬렉션과 간접 가비지 컬렉션으로 부름  

<br>

### 세대 단위 컬렉션 이론
대부분의 상용 가상머신들은 세대 단위 컬렉션 이론에 기초해 설계  
일직 죽을 객체들을 한 곳에 몰아넣고 그 중 살아남은 소수 객체를 유지하는 방법에 집중  
- 약한 세대 가설: 대다수 객체는 일직 죽음
- 강한 세대 가설: 가비지 컬렉션 과정에서 살아남은 횟수가 늘수록 오래 살 가능성 높음
- 세대 간 참조 가설: 세대 간 참조의 개수는 같은 세대 안에서의 참조보다 훨씬 적음

<br>

가비지 컬렉터는 한번에 하나 또는 몇개 영역만 선택해서 회수  
이를 기준으로 `마이너 GC`, `메이저 GC`, `전체 GC`로 분류  
각 영역에 담긴 객체들의 생존 특성에 따라 `mark-sweep`, `mark-copy`, `mark-compact`로 알고리즘 분류  

<br>

### 마크-스윕 알고리즘

<img width="450" height="250" alt="mark_sweep" src="https://github.com/user-attachments/assets/f429df8d-587f-42c9-9950-1a007f601e34" />

작업을 표시화 쓸기라는 두 단계로 나누어 진행, 먼저 회수할 객체에 모두 표시한 후 표시된 객체를 한번에 회수  
실행 효율이 일정하지 않고 메모리 파편화가 심해서 다른 알고리즘에서 개선  

<br>

### 마크-카피 알고리즘

<img width="450" height="250" alt="mark_copy" src="https://github.com/user-attachments/assets/5cc53c0a-66d0-4ddb-8cd5-e7a963e92c3b" />

자바 가상머신이 `신세대`에 사용하는 알고리즘, 회수할 객체가 많을수록 효율이 떨어지는 마크-스윕 알고리즘의 문제를 해결  
가용 메모리를 동일한 크기의 두 블록으로 나누어 한쪽 블록만 사용, 꽉 차는 경우 살아남은 객체들만 다른 블록으로 복사  
하지만 가용 메모리 낭비가 심함  

<br>

### 마크-컴팩트 알고리즘

<img width="450" height="250" alt="mark_compact" src="https://github.com/user-attachments/assets/b06608c1-2d03-4da6-94eb-5c96ac5be6e4" />

자바 가상머신이 `구세대`에 사용하는 알고리즘, 마크-카피의 경우 객체 생존율이 높을수록 복사할 객체가 많아서 효율이 떨어짐  
표시 단계는 마크-스윕과 동일, 컴팩트 단계에서 생존한 모든 객체를 메모리 영역의 한쪽 끝으로 모음  
메모리 이동이 발생하기 때문에 기존 참조들을 갱신하는 스탑 더 월드(`stop the world`) 발생  

<br>

## 핫스팟 알고리즘 상세 구현

### 루트 노드 열거
도달 가능성 분석 알고리즘에서 GC 루트 집합으로부터 참조 체인을 찾는 작업  
GC 루트로 고정 가능한 노드는 주로 전역 참조, 실행 컨텍스트에 존재  
루트 노드 열거만큼은 반드시 일관성이 보장되는 스냅샷 상태에서 수행, 이것이 스탑 더 월드가 필요한 이유  
핫스팟은 `OopMap` 데이터 구조를 통해 문제 해결  
먼저 클래스 로딩 완료후 객체에 포함된 데이터 타입을 확인, JIT 컴파일 과정에서 스택의 어느 위치와 어느 레지터스 데이터가 참조인지 기록  

<br>

### 안전 지점
참조 관계나 `OopMap` 내용 변경 명령어가 많으며, 메모리를 더 많이 사용  
핫스팟은 모든 명령어 각각에 `OopMap`을 생성하지 않음, 안전 지점이라고 하는 특정한 위치에만 기록  
가비지 컬렉터는 사용자 프로그램이 안전 지점에 도달할 때까지 절대 멈춰 세우지 않음  
핫스팟은 메모리 보호 트랩이라는 방법을 사용해서 폴링을 어셈블리 명령어 하나만으로 수행  
- 선제적 멈춤(`perrmptive suspension`): 스레드 코드가 가비지 컬렉터를 특별히 신경 쓸 필요 없음
- 자발적 멈춤(`voluntary suspension`): 플래그를 설정하고 각 스레드가 적극적으로 폴링

<br>

### 안전 지역
안전 지점 메커니즘은 실행중인 프로그램이 길지 않은 경우 가비지 컬렉션 프로세스가 제대로 임무를 다할 수 있도록 보장  
일반적으로 잠자기 상태이거나 블록된 상태의 사용자 스레드는 가상머신 인터럽트 요청에 응답 불가  
안전 지역은 일정 코드 영역에서는 참조 관계가 변하지 않음을 보장, 안전 지점을 확장한 개념  
즉, 안전 지역 안이라면 어디서든 가비지 컬렉션을 시작해도 무방  
사용자 스레드는 안전 지역의 코드를 실행하기 앞서 안전 지역에 진입했음을 표시  
안전 지역에서 벗어나려는 스레드는 안전 지역을 벗어나도 좋다는 신호를 받을 때까지 대기  

<br>

### 기억 집합과 카드 테이블
가비지 컬렉터는 신세대에 기억 집합이라는 데이터 구조를 두어 구세대와 GC 루트를 전부 스캔하지 않고 해결  
기억 집합은 비회수 영역에서 회수 영역을 가리키는 포인터들을 기록하는 추상 데이터 구조  
- 워드 정밀도: 레코드 하나가 메모리 워드 하나에 매핑, 특정 레코드가 마킹된 경우 해당 메모리 워드가 세대 간 포인터
- 객체 정밀도: 레코드 하나가 객체 하나에 매핑, 특정 레코드가 마킹된 경우 해당 객체에 다른 세대 객체 참조 필드 존재
- 카드 정밀도: 레코드 하나가 메모리 블록 하나에 매핑, 특정 레코드가 마킹된 경우 해당 블록에 세대 간 참조 객체 존재

<br>

```cpp
if (CARD_TABLE[this address >> 9] != 1)
  CARD_TABLE[this address >> 9] = 1;
```

카드 정밀도로 기억 집합을 구현한 것이 카드 테이블, 가장 널리 사용되는 방식  
핫스팟 가상머신도 카드 테이블을 바이트 배열로 구현  
카드 페이지 하나의 메모리에는 하나 이상의 객체가 들어있음  
이 객체들 중 하나에라도 세대 간 포인터를 갖는 필드 존재시 해당 원소를 1로 표시  
객체 회수시 페이지 값이 1인 블록만 GC 루트에 추가해서 함께 스캔  

<br>

### 쓰기 장벽

```cpp
void oop_field_store(oop* field, oop new_value) {
  // 참조 타입 필드에 대입
  *field = new_value;
  // 쓰기 완료 후 장벽이 카드 테이블 상태를 갱신
  post_write_barrier(field, new_value);
}
```

카드 테이블의 원소가 더렵혀지는 시점은 참조 타입 필드에 값이 대입되는 순간  
대입되는 순간 카드 테이블 갱신을 위해서는 순수한 기계어 명령이 필요  
핫스팟 가상머신은 쓰기 장벽 기술을 사용해서 카드 테이블 관리  
AOP 애스팩트에 비유 가능, 사후/사전 쓰기 장벽을 사용  
쓰기 장벽은 멀티스레드 환경에서 거짓 공유(`false sharing`) 문제 발생 가능  

<br>

### 동시 접근 가능성 분석
사용자 스레드의 일시 정지 문제를 해결하기 위해서 일관성 보장 필요  
동시 스캔 도중 객체 사라짐 문제를 해결하기 위해서는 아래 두 조건 중 하나만 방지하면 해결  

<img width="500" height="700" alt="gc_root_search" src="https://github.com/user-attachments/assets/c28bd4a6-2f35-451e-af02-d2ad5877756b" />

- 사용자 스레드가 이미 탐색 완료한 객체에 새로운 참조 객체 추가
- 사용자 스레드가 탐색 중인 객체에서의 참조 객체에 대한 직간접적인 참조 삭제

<br>

첫번째 조건은 `증분 업데이트`를 통해 이미 탐색 완료된 객체에 새로운 객체 참조가 추가되면 따로 기록  
동시 스캔이 끝난 후 기록해 둔 객체들을 루트로 다시 재스캔  

<br>

두번째 조건은 `시작 단계 스냅샷`을 이용  
참조 관계 삭제 여부와 상관없이 스캔을 막 시작한 순간의 객체 그래프 스냅샷을 기준으로 스캔  

<br>

## 클래식 가비지 컬렉터

<img width="400" height="200" alt="classic_gc" src="https://github.com/user-attachments/assets/974b55be-241c-4090-a2b9-81dbbe0b3e79" />

여러가지 컬렉터 별로 함께 사용 가능하거나 신세대, 구세대용 컬렉션으로 구분 가능  

<br>

### 시리얼 컬렉터

<img width="500" height="150" alt="serial_collector" src="https://github.com/user-attachments/assets/18f9d748-ac8e-45bb-bb33-0eeef4e01887" />

가장 기초적이고 오래된 컬렉터, JDK 1.3.1 전까지 핫스팟 가상머신의 유일한 구세대용 컬렉터  
단일 스레드로 동작, 회수가 완료될 때까지 다른 모든 작업 스레드가 대기  
시리얼 컬렉터를 사용하려면 `-XX:+UseSerialGC` 매개변수 사용  

<br>

### 파뉴 컬렉터

<img width="500" height="150" alt="parnew_collector" src="https://github.com/user-attachments/assets/72830373-d2d8-41c2-b88f-1372d426b200" />

여러 스레드를 활용하여 시리얼 컬렉터를 병렬화한 버전  
파뉴 컬렉터와 CMS 조합으로 사용했지만 JDK 9부터 공식 서버용 컬렉터 권장안에서 삭제  

<br>

### 패러렐 스캐빈지 컬렉터
신세대용 컬렉터로 마크-카피 알고리즘에 기초하여 여러 스레드를 사용해서 병렬로 회수  
CMS 컬렉터가 사용자 스레드 일시 정지 시간 최소화가 목표였다면 PS 컬렉터는 처리량을 제어하는 것이 목표  
컬렉션 정지 시간 최댓값 지정은 `-XX:MaxGCPauseMillis`, 처리량 지정은 `-XX:GCTimeRatio` 매개변수 사용  
목표만 설정해준다면 가상머신이 메모리 관리 최적화 진행(적응형 조율)  

<br>

### 시리얼 올드 컬렉터

<img width="500" height="150" alt="serial_old_collector" src="https://github.com/user-attachments/assets/a9bd144f-40ce-4ff1-9ab8-dea33a3283c5" />

시리얼 컬렉터의 구세대용 버전, 단일 스레드 컬렉터이며 마크-컴팩트 알고리즘 사용  
서버용으로 사용한다면 JDK 5 이전의 PS 컬렉터와의 호환 또는 CMS 컬렉터 실패 대비책  

<br>

### 패러렐 올드 컬렉터

<img width="500" height="150" alt="parallel_old_collector" src="https://github.com/user-attachments/assets/26e09b85-7595-40c6-83ce-8d70031e555f" />

PS 컬렉터의 구세대용 버전, 멀티스레드를 이용한 병렬 회수 및 마크-컴팩트 알고리즘 사용  
처리량을 중시하는 PS 컬렉터와 딱맞는 구세대 컬렉터  
패러렐 올드 컬렉터를 사용하려면 `-XX:+UseParallelGC` 매개변수 사용  

<br>

### CMS 컬렉터

<img width="600" height="150" alt="cms_collector" src="https://github.com/user-attachments/assets/772c1d6e-460e-4965-85ce-e4f360cd8a5a" />

표시와 쓸기 단계 모두를 사용자 스레드와 동시에 수행, 가비지 컬렉션에 따른 일시 정지 시간을 최소로 줄이는 것을 목표  
- 최초 표시: 스탑 더 월드 방식, GC 루트와 직접 연결된 객체들만 표시하기 때문에 빠르게 끝남
- 동시 표시: 그래프 전체 탐색, 시간이 오래 걸리지만 사용자 스레드가 대기하지 않음
- 재표시: 스탑 더 월드 방식: 사용자 스레드가 참조 관계를 변경한 객체들을 다시 탐색
- 동시 쓸기: 위의 단계에서 죽었다고 판단되는 객체들을 쓸어 담음

<br>

짧은 정지 시간을 추구하는 핫스팟 가상머신의 첫번째 성공작이지만 완벽하지 않음  
동시성을 위해 설계되었기 때문에 프로세서 자원에 아주 민감(코어의 1/4 사용, 4개 이하 코어인 경우 치명적)  
부유 쓰레기(`floating garbage`) 처리가 불가해서 동시 모드 실패 유발 가능, 완벽한 스탑 더 월드 방식의 전체 GC 발생  
마크-스윕 알고리즘의 문제점인 메모리 파편화 문제 발생  
JDK 9 버전에서 폐기 대상으로 지정, JDK 14에서 완전히 제거  

<br>

### G1 컬렉터(Garbage First)

<img width="600" height="300" alt="garbage_first_collector" src="https://github.com/user-attachments/assets/572654bc-a2e8-4129-814e-ace62ebe5244" />

부분 회수(`partial collection`) 설계 아이디어와 리전을 회수 단위로 하는 메모리 레이아웃 분야 개첵  
JDK 9 버전 이후 PS + 패러렐 올드 조합을 밀어내고 서버 모드용 기본 컬렉터로 지정  
광역적으로 마크-컴팩트 알고리즘, 지엽적으로 마크-카피(두 리전 사이) 사용  
정지 시간 예측 모델을 이용해서 가비지 컬렉터가 쓰는 시간을 통제하는 것을 목표  
힙 메모리 어느 곳이든(신세대, 구세대) 회수 대상에 포함가능, 이를 회수 집합(`CSet`)이라고 표현  
고정된 세대 단위 영역 구분에서 벗어나 연속된 자바 힙을 동일 크기의 여러 독립 리전으로 나눔  
리전 하나의 크기는 `-XX:G1HeapRegionSize` 매개변수로 설정  
사용자가 설정한 `-XX:MaxGCPauseMillis` 일시 정지 시간이 허용하는 한도에서 회수 효과가 가장 큰 리전부터 회수  

<br>

<img width="550" height="150" alt="garbage_first_collector_2" src="https://github.com/user-attachments/assets/37b5d392-ea3a-43eb-a998-1fa8230245df" />

- 최초 표시: GC 루트가 직접 참조하는 객체들을 표시하고 TAMS 포인터 값을 수정
- 동시 표시: 도달 가능성을 분석, 전체 힙의 객체 그래프를 재귀적으로 스캔하며 회수 객체 탐색
- 재표시: 시작 단계 스냅샷 이후 변경된 소수 객체만 처리
- 복사 및 청소: 통계 데이터를 기초로 리전들을 회수 가치와 비용에 따라 정렬, 목표한 일시 정지 시간에 부합하도록 계획 수립

<br>

### 모던 가비지 컬렉터

<img width="400" height="300" alt="modern_garbage_collector" src="https://github.com/user-attachments/assets/64309e19-52c7-4236-8d9c-046f7db39724" />

일부 클래식 가비지 컬렉터는 이미 사라지거나 통폐합, 가장 큰 특징은 신세대용과 구세대용 구분이 사라짐  
시리얼 컬렉터가 시리얼 올드 컬렉터를 흡수, PS와 패러렐 올드가 통합  

<br>

## 저지연 가비지 컬렉터

<img width="300" height="200" alt="impossible_trinity" src="https://github.com/user-attachments/assets/d1b21e6a-3fd5-4591-b1a5-502b9db1500a" />

가비지 컬렉터를 측정하는 지표는 `처리량`, `지연시간`, `메모리 사용량`  
이 세가지 중 지연시간의 중요성이 점점 커지는 추세  

<br>

<img width="500" height="300" alt="garbage_collector_concurrent" src="https://github.com/user-attachments/assets/d1123618-7e04-4cad-8cc8-bea58f22f8fe" />

셰넌도어와 ZGC는 거의 모든 과정이 동시에 수행, 이 두 컬렉터를 저지연 가비지 컬렉터라고 표현  

<br>

### 셰넌도어
오라클의 견제를 받아서 유료 상용 버전에는 제외, 무료 오픈 소스 OpenJDK에만 존재하는 컬렉터  
레드햇이 독립적으로 시작한 프로젝트였지만 OpenJDK에 기증  
G1과 힙 레이아웃이 비슷하며, 최초 표시와 동시 표시 등 여러 단계의 처리 방식에도 공통점이 많음  

<br>

<img width="400" height="250" alt="connection_matrix" src="https://github.com/user-attachments/assets/bda6a005-ee8a-4f05-bce7-1966588800ef" />

- 동시 모으기 지원
- JDK 21 이전까지 세대 단위 컬렉션을 사용하지 않음
- 메모리와 컴퓨팅 자원을 많이 사용하는 기억 집합 대신 연결 행렬(`connection matrix`)로 리전 간 참조 관계 기록










