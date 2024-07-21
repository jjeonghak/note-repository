## 스레드 안전성 수준
메서드 선언에 synchroniazed 한정자를 선언할지는 구현 이슈일 뿐 API에 속하지 않음  
멀티스레드 환경에서도 클래스가 지원하는 스레드 안전성 수준을 정확히 명시  
    
1. 불변(immutable)  
      @Immutable 어노테이션에 속함  
      이 클래스의 인스턴스는 마치 상수와 같아서 외부 동기화 불필요(String, Long, BigInteger)  
      
2. 무조건적 스레드 안전(unconditionally thread-safe)  
      @ThreadSafe 어노테이션에 속함  
      이 클래스의 인스턴스는 수정 가능  
      내부 동기화 적용, 별도의 외부 동기화 불필요(AtomicLong, ConcurrentHashMap)  
    
3. 조건부 스레드 안전(conditionally thread-safe)  
      @ThreadSafe 어노테이션에 속함  
      무조건적 스레드 안전과 유사  
      일부 메서드는 외부 동기화 필요(Collections.synchronized 래퍼 메서드의 반환 컬렉션)  
    
4. 스레드 안전하지 않음(not thread-safe)  
      @NotThreadSafe 어노테이션에 속함  
      이 클래스의 인스턴스는 수정가능  
      메서드 호출을 클라이언트가 선택한 외부 동기화 메커니즘으로 감싸야 함(ArrayList, HashMap)  
    
5. 스레드 적대적(thread-hostile)  
      이 클래스의 모든 메서드 호출은 외부 동기화로 감싸더라도 멀티스레드 환경에서 안전하지 않음  
      이 클래스의 경우 일반적으로 정적 데이터를 아무 동기화 없이 수정  
      일반적으로 문제를 수정 후 배포하거나 사용 자제(deprecated) API로 지정  

<br>

## 스레드 안전성 수준 문서화
어떤 순서로 호출할 때 외부 동기화가 필요한지  
순서에 맞게 호출할 때 어떤 락 혹은 락들을 얻어야 하는지  
스레드 안전성은 보통 클래스의 문서화 주석에 기재하지만 독특한 특성의 메서드라면 해당 메서드의 주석에 기재  

<br>

### Collections.synchronizedMap
이대로 따르지 않으면 동작을 예측할 수 없다.  

````java
synchronizedMap이 반환한 맵의 걸렉션 뷰를 순회하려면 반드시 그 맵을 락으로 사용해 수동으로 동기화하라.
Map<K, V> m = Collections.synchronizedMap(new HashMap<>());
Set<K> s = m.keySet();  //동기화 블록 밖에 있어도 된다.
...
synchronized(m) {  //s가 아닌 m을 사용해 동기화해야 한다!
    for (K key : s)
        key.f();
}
````

<br>

## 서비스 거부 공격
클래스가 외부에서 사용할 수 있는 락을 제공하면 클라이언트에서 일련의 메서드 호출을 원자적으로 수행가능  
이 기능은 내부에서 처리하는 고성능 동시성 제어 메커니즘과 혼용불가(ConcurrentHashMap 같은 동시성 컬렉션과 사용불가)  
이점을 악용해서 클라이언트가 공개된 락을 오래 쥐고 놓지 않는 서비스 거부 공격(denial-of-service attack)  
비공개 락을 이용함으로 방어가능  

<br>

### 비공개 학 객체 관용구
````java
private final Object lock = new Object();  //락 필드는 항상 final로 선언

public void foo() {
    synchronized(lock) {
        ...
    }
}
````

<br>
