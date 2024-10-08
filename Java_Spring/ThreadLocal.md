## 쓰레드 로컬
해당 쓰레드만 접근할 수 있는 특별한 저장소  
싱글톤 인스턴스 필드에 대한 동시성 이슈 해결을 위한 방식  
같은 인스턴스의 쓰레드 로컬 필드에 접근해도 문제 없음  
자바 언어차원에서 java.lang.ThreadLocal 클래스 제공  
쓰레드 로컬을 다 사용한 후 저장된 값 제거 필수(remove)  

````java
//기존 싱글톤 동시성 이슈 필드
private String nameStore;

//쓰레드 로컬
private ThreadLocal<String> nameStore = new ThreadLocal<>();
nameStore.set("string");
nameStore.get();
nameStore.remove();
````

<br>

## 쓰레드 로컬 주의사항
WAS와 같은 어플리케이션 서버는 사용이 끝난 쓰레드를 쓰레드 풀에 반닙  
쓰레드 로컬의 데이터를 remove 하지 않은 상태로 쓰레드 풀에 반납할 경우 데이터가 지속적으로 존재  
쓰레드 풀에서 해당 쓰레드를 다시 재사용할 경우 이전 데이터까지 노출  
쓰레드 종료시 꼭 remove 메서드를 통해서 쓰레드 로컬 데이터 제거 필수  

<br>
