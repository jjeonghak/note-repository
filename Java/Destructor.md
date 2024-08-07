## 소멸자
자바는 두가지 객체 소멸자 제공  
c++ 파괴자(destrucor)와는 다른 개념  
자바는 접근할 수 없는 객체를 가비지 컬렉터가 메모리 회수  
상태를 영구적으로 수정하는 작업에서는 절대 의존금지  
 
1. finalizer  
    예측 불가, 일반적으로 불필요  
      
2. cleaner  
    finalizer보단 덜 위험하지만 예측 불가, 일반적으로 불필요  

<br>

## 소멸자 문제
finalizer와 cleaner 모두 제때 실행된다는 보장불가  
얼마나 신속히 수행할지는 가비지 컬렉터 알고리즘에 따라 결정  
인스턴스 자원 회수 지연 문제 발생(OutOfMemoryError 발생 우려)  
finalizer 스레드의 우선순위가 낮아서 실행될 기회를 제대로 얻지못함  
cleaner는 자신을 수행할 스레드 제어가능하지만 가비지 컬렉터의 통제하에서 진행  
  
<br>

## 메모리 관리
AutoCloseable() 구현  
클라이언트는 인스턴스를 사용한 후 close() 호출  
close()에서 각 인스턴스의 사용종료를 필드에 기록  
사용종료 후에 인스턴스 호출시 IllegalStateException 예외반환  
  
<br>

## 소멸자 사용방식
1. 안전망  
    클라이언트가 close() 호출하지 않은 경우에만 사용  
    자원회수를 안하는 것보단 늦게라도 하는 것이 좀 더 효율적  

2. 네이티브 피어(native peer)  
    네이티브 피어란 일반 자바 객체가 네이티브 메서드를 통해 기능을 위임한 네이티브 객체  
    자바 객체가 아니므로 가비지 컬렉터가 메모리 회수 불가  

<br>
  
## cleaner 사용방식  

````java
public class Room implements AutoCloseable {
    private static final Cleaner cleaner = Cleaner.create();
    
    //청소가 필요한 자원, Room 참조금지
    private static class State implements Runnable {
        int numJunkPiles;
        
        State(int numJunkPiles) { this.numJunkPiles = numJunkPiles; }
        
        @Override public void run() {
            System.out.println("clean");
            numJunkPiles = 0;
        }
    }
    
    private final State state;
    private final Cleaner.Cleanable cleanable;
    
    public Room(int numJunkPiles) {
        state = new State(numJunkPiles);
        cleanable = cleaner.register(this, state);
    }
    
    @Override public void close() { cleanable.clean(); }
}
````

<br>

