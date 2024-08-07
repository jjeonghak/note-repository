## 동기화
가변 데이터를 여러 스레드에서 공유하는 경우   
synchronized 키워드는 해당 메서드나 블록을 한번에 한 스레드씩 수행하도록 보장  
자바 명세는 스레드가 필드를 읽을 때 항상 수정 완료된 값을 얻는다고 보장  
하지만 한 스레드가 저장한 값이 다른 스레드에게 보이는가는 보장하지 않음  
동기화는 배타적 실행뿐 아니라 스레드 사이의 안정적인 통신에 필수  
한 스레드가 만든 변화를 다른 스레드에게 언제 어떻게 보이는지를 규정한 자바 메모리 모델 때문  

<br>

### 무한히 실행되는 스레드
````java
public class StopThread [
    //volatile으로 선언한 경우 해결가능, 배타적 수행과는 상관없이 가장 최근 수정값 보장
    private static boolean stopRequested;
    
    public static void main(String[] args) throws InterruptedException {
        Thread backgroundThread = new Thread(() -> {
            int i = 0;
            while (!stopRequested)
                i++;
        });
        backgroundThread.start();
        
        TimeUnit.SECONDS.sleep(1);
        //동기화하지 않은 경우 수정된 값을 언제쯤 보게 될지 보증 불가
        stopRequested = true;
    }
}
````

<br>

### 적절한 동기화
````java
public class StopThread {
    private static boolean stopRequested;
    
    //쓰기 메서드 동기화
    private static synchronized void requestStop() {
        stopRequested = true;
    }
    
    //읽기 메서드 동기화
    private static synchronized boolean stopRequested() {
        return stopRequested;
    }
    
    public static void main(String[] args) throws InterruptedException {
        Thread backgroundThread = new Thread(() -> {
            int i = 0;
            while (!stopRequested())
                i++;
        });
        backgroundThread.start();
        
        TimeUnit.SECONDS.sleep();
        requestStop();
    }
}
````

<br>

## AtomicLong
java.util.concurrent.atomic 패키지  
이 패키지는 락 없이도(lock-free) 스레드 안전한 프로그래밍 지원  
volatiile은 동기화의 두 효과 중 통신쪽만 지원하지만 이 패키지는 원자성(배타적 실행)도 지원  

<br>

### 동기화 없는 코드
````java
private static volatile int nextSerialNumber = 0;

public static int generateSerialNumber() {
    return nextSerialNumber++;
}
````

<br>
    
### 락-프리 동기화
````java
private static final AtomicLong nextSerialNum = new AtomicLong();

public static long generateSerialnumber() {
    return nextSerialNum.getAndIncrement();
}
````

<br>

## 동기화 제한사항
응답 불가와 안전 실패를 피하려면 동기화 메서드나 동기화 블록 안에서는 제어를 클라이언트에 양도 금지  
동기화된 영역에선 재정의 가능한 함수나 클라이언트가 넘겨준 함수 객체 호출 금지(외계인 메서드)  
  
<br>
