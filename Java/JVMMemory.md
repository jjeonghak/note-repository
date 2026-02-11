# 자바 메모리 영역과 오버플로
c 언어와는 다르게 자동 메모리 관리 메커니즘을 사용  
통제권을 위임했기 때문에 생기는 단점도 존재  

<br>

## 런타임 데이터 영역
자바 가상머신은 실행되는 동안 필요한 메모리를 몇 개의 데이터 영역으로 나누어 관리  

<img width="400" height="300" alt="jvm_runtime_data_section" src="https://github.com/user-attachments/assets/660017fe-48a1-4bef-984c-927b230382ff" />

<br>
<br>

### 프로그램 카운터
현재 실행중인 스레드의 바이트코드 줄 번호 표시기  
자바 가상머신의 멀티스레딩은 CPU 코어를 여러 스레드가 교대로 사용  
특정 시각에 각 코어는 한 스레드의 명령어만 실행  
스레드 전환 후 이전에 실행중이였던 지점을 복원하기 위해 스레드는 각각에 고유한 프로그램 카운터 필요  
각 스레드의 카운터는 서로 영향을 주지 않는 독립된 `스레드 프라이빗` 메모리에 저장  
스레드가 자바 메서드를 실행중인 경우 실행중인 바이트코드 명령어 주소가 기록되지만 네이티브 메서드를 실행중인 경우 `Undefined`  
프로그램 카운터 메모리 영역은 명세에서 `OutOfMemoryError` 조건이 명시되지 않은 유일한 영역  

<br>

### 자바 가상 머신 스택
`스레드 프라이빗`하며 연결된 스레드와 생명주기가 같음  
각 메서드가 호출될 때마다 스택 프레임을 만들어 지역 변수 테이블, 피연산자 스택, 동적 링크, 메서드 반환값 등 정보 저장  
이후 스택 프레임을 가상 머신 스택에 `푸시`하고 메서드 종료시 `팝`하는 과정 반복  
보통 전통적인 메모리 구조의 스택은 여기서 자바 가상 머신 스택을 가리킴  
지역 변수 테이블에서 기본 데이터타입, 객체 참조, 반환 주소타입을 저장하는 공간이 `지역 변수 슬롯`  
슬롯 하나의 크기는 32비트이며 `double` 타입처럼 길이가 긴 데이터는 슬롯 두개 차지  
자바 메서드는 스택 프레임에서 지역 변수용으로 할당받아야 할 공간의 크기(슬롯 개수)가 이미 결정(메서드 실행중에 변하지 않음)  
스택 크기 제한 가능(`-Xss` 매개변수 사용)  

- 스레드가 요청한 스택 깊이가 가상머신이 허용하는 깊이보다 크면 `StackOverflowError` 발생
- 스택 용량을 동적으로 확장할 수 있는 자바 가상머신에서는 확장에 필요한 여유공간 부족시 `OutOfMemoryError` 발생

<br>

### 네이티브 메서드 스택
가상머신 스택과 매우 비슷한 역할  
가상머신 스택은 자바 메서드(바이트코드) 실행시 사용, 네이티브 메서드 스택은 네이티브 메서드 실행시 사용  
하지만 명세에 어떤 구조로 어떻게 구현되어 있는지 명시되지 않음  

<br>

### 자바 힙
모든 스레드가 공유하며 가상머신이 구동될 때 생성  
객체 인스턴스를 저장하는 것을 목적으로 거의 모든 객체 인스턴스가 이 영역에 할당  
가비지 컬렉터가 관리하는 메모리 영역이기 때문에 `GC 힙`이라고 표현  
메모리 회수 관점에서 세대별 컬렉션 이론을 기초로 설계(`new`, `old`, `even`, `survivor`)  
모든 스레드가 공유하기 때문에 객체 할당 효율을 높이기 위해서 스레드 로컬 할당 버퍼 여러개로 나눔  
물리적으로 떨어진 메모리에 위치해도 상관없으나 논리적으로 연속되게 저장  
하지만 대부분의 가상머신이 큰 객체(주로 배열)는 물리적으로도 연속된 메모리 공간을 사용하도록 구현  
자바 힙은 크기를 고정 및 확장 가능하도록 구현 가능(`-Xmx`, `-Xms` 매개변수 사용)  

<br>

### 메서드 영역
자바 힙과 마찬가지로 모든 스레드가 공유  
가상머신이 읽어들인 타입정보, 상수, 정적변수, JIT 컴파일러가 컴파일한 코드 캐시 등을 저장  
명세에는 메서드 영역도 논리적으로 힙의 한 부분으로 기술, 구분을 위해서 논힙(`non-heap`)으로 표현  
`JDK 7`까지는 해당 영역이 `영구 세대`에 구현되어 따로 관리가 필요하지 않음(가비지 컬렉터가 관리)  
하지만 영구 세대때문에 가상 머신 성능이 달라지는 메서드가 발생(`String::intern()`)  
`JDK 8`부터 영구 세대라는 개념을 지우고 모든 클래스 메타데이터를 `메타스페이스`로 옮김  
해당 영역에서는 쓰레기를 회수할 일이 거의 없음(대부분 상수 풀과 타입이라 회수 효과가 적음)  
메서드 영역이 꽉 차서 메모리를 할당할 수 없는 경우도 `OutOfMemoryError` 발생  

<br>

### 런타임 상수 풀
메서드 영역의 일부  
클래스 버전, 필드, 메서드, 인터페이스 등 클래스 파일에 포함된 리터럴과 심벌 참조 저장  
자바 가상머신은 클래스 파일의 각 영역별로 엄격한 규칙을 정함  
다만 런타임 상수 풀에 대해서는 요구사항을 상세하게 정의하지 않음  
클래스 파일의 상수 풀과 다르게 런타임 상수 풀은 동적  

<br>

### 다이렉트 메모리
가상머신 런타임에 혹하지 않고 명세에 정의된 영역도 아님  
하지만 자주 쓰이는 메모리이며 `OutOfMemoryError` 원인이 될 가능성 존재  
`JDK 1.4`에서 `NIO` 도입, 채널과 버퍼 기반 I/O 메서드가 소개  
NIO는 힙이 아닌 메모리를 직접 할당할 수 있는 네이티브 함수 라이브러리를 사용, `DirectByBuffer` 객체를 통해 작업 수행  
자바 힙과 네이티브 힙 사이에서 데이터 복사 과정이 생략되어 일부 시나리오에서 성능이 크게 개선  
물리 메모리를 직접 할당하기 때문에 자바 힙 크기의 제약과 무관, 가비지 컬렉터 관리 대상 아님  
하지만 하드웨어 총 메모리 용량과 프로세서에 허용된 주소 공간을 넘어설 수 없음  
그렇기 때문에 `-Xmx` 등의 매개변수를 설정할때 가상머신의 메모리 크기만 고려한다면, 해당 메모리 확장시도시 `OutOfMemoryError` 발생 가능  

<br>

## 핫스팟 가상 머신의 객체

### 객체 생성
자바 가상머신이 `new` 명령을 만나면 매개변수가 상수 풀 안의 클래스를 가리키는 심벌 참조인지 확인   
해당 심벌 참조가 뜻하는 클래스가 로딩, 해석, 초기화되었는지 확인, 이후 새 객체를 담을 메모리 할당  
가비지 컬렉터의 컴팩트(`compact`) 가능 여부에 따라 여유 목록(`free list`)과 포인터 밀치기(`bump the pointer`) 사용   

<img width="400" height="100" alt="bump_the_pointer" src="https://github.com/user-attachments/assets/17f1786f-4f5a-4654-ba56-f70ad277bf0d" />

<br>
<br>

또한 멀티스레딩 환경에서 여유 메모리 시작 포인터를 스레드 안전하게 관리 필수  
첫번째 방식은 메모리 할당을 `동기화`해서 비교 및 교환과 실패시 재시도 방식  
두번째 방식은 스레드마다 다른 메모리 공간을 할당, 힙 내에 작은 크기의 전용 메모리(스레드 로컬 할당 버퍼, `TLAB`)를 미리 할당  

<img width="400" height="200" alt="tlab" src="https://github.com/user-attachments/assets/8aa1ec64-2d20-4571-899a-e10f2a4ff6ac" />

<br>
<br>

스레드 로컬 할당 버퍼 방식으로 인해 객체 생성시 따로 초기화하지 않아도 필드값이 0으로 초기화  
이후 생성자(`<init>`) 메서드를 이어서 실행  


<img width="500" height="200" alt="java_new_method" src="https://github.com/user-attachments/assets/79b81538-2932-43b3-9fa5-519f74a15482" />

<br>
<br>

- 핫스팟 가상머신 바이트코드 인터프리터 발췌 코드

```c++
CASE(_new): {
  u2 index = Bytes::get_Java_u2(pc+1);
  ConstantPool* constants = istate->method()->constants();

  // 클래스 해석 및 상수 풀 저장 여부 확인
  if (UseTLAB && !constants->tag_at(index).is_unresolved_klass()) {
    Klass* entry = constants->resolved_klass_at(index);
    InstanceKlass* ik = InstanceKlass::cast(entry);

    // 클래스 초기화 완료 및 빠른 경로 할당 가능 여부 확인
    if (ik->is_initialized() && ik->can_be_fastpath_allocated()) {
      // 객체 크기 계산
      size_t obj_size = ik->size_helper();
      // TLAB 할당 시도
      HeapWord* result = THREAD->tlab().allocate(obj_size);

      // 할당 성공 여부 확인
      if (result != NULL) {
        // 객체 필드 블록 초기화
        if (DEBUG_ONLY(true ||) !ZeroTLAB) {
          size_t hdr_size = oopDesc::header_size();
          Copy::fill_to_words(result + hdr_size, obj_size - hdr_size, 0);
        }
        // 일반 객체 포인터로 형 변환
        oop obj = cast_to_oop(result);

        // 객체 헤더 정보 설정
        assert(!UseBiasedLocking, "Not implemented");
        obj->set_mark(markWord::prototype());
        obj->set_klass_gap(0);
        obj->set_klass(ik);

        OrderAccess::storestore();
        // 객체 참조를 스택에 추가
        SET_STACK_OBJECT(obj, 0);
        // 다음 명령어 수행
        UPDATE_PC_AND_TOS_AND_CONTINUE(3, 1);
      }
    }
  }

  // 느린 경로 할당
  CALL_VM(InterpreterRuntime::_new(THREAD, METHOD->constants(), index), handle_exception);
  OrderAccess::storestore();
  SET_STACK_OBJECT(THREAD->vm_result(), 0);
  THREAD->set_vm_result(NULL);
  UPDATE_PC_AND_TOS_AND_CONTINUE(3, 1);
}
```

<br>
























