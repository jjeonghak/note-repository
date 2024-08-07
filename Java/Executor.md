## 실행자 계층구조
````
  Executor
   ㄴExecutorService
     ㄴScheduledExecutorService
````

<br>

## Executor
제공된 작업(Runnable 구현체)을 실행하는 객체가 구현해야할 인터페이스  
작업을 제공하는 코드와 작업을 실행하는 매커니즘 사이의 커플링 제거  

````java
package java.util.concurrent.Executor;

public interface Executor {
    void excute(Runnable command);
}
````

<br>

## ExcutorService
Executor 라이프 사이클을 관리할 수 있는 기능 정의  
Runnale 및 Callable 작업 사용 가능  

````java
public interface ExecutorService extends Executor {
    //Executor에 전달된 작업까지만 실행
    void shutdown();
    
    //현재 실행되고 있는 작업까지 모두 중지 및 대기중인 작업 리스트 반환
    List<Runnable> shutdownNow();
    
    //셧다운 여부 반환
    boolean isShutdown();
    
    //셧다운 후 모든 작업이 종료되었는지 여부 반환
    boolean isTerminated();
    
    //셧다운 실행후 지정된 시간까지만 대기, 대기후 종료되지 않은 작업 여부 반환
    boolean awaitTermination(long timeout, TimeUnit unit);
    
    //결과값 반환 작업 추가
    <T> Future<T> submit(Callable<T> task);
    
    //결과값 없는 작업 추가
    <T> Future<T> submit(Runnable task, T result);
    
    //주어진 작업 모두 실행후 각 실행 결과값 리스트 반환
    <T> List<Future<T>> invokeAll(Collections<? extends Callable<T>> tasks>);
    
    //작업 수행후 성공적으로 완료된 결과 반환
    <T> invokeAny(Collection<? extends Callable<T>> tasks);
}
````

<br>

## ScheduledExecutorService
전달 받은 작업을 큐에 삽입 후 사용가능한 스레드에 작업 실행  
  
<br>

