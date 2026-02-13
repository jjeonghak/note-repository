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

<br>







































