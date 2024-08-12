## 프록시 패턴, 데코레이터 패턴
어떠한 클라이언트 요청에 대해 서버를 대신하는 대리자  
클라이언트는 서버에게 요청한 것인지 포록시에게 요청한 것인지 모름  
서버와 프록시가 같은 인터페이스를 사용하므로 대체가능  
의도(intent)에 따라 프록시 패턴(접근 제어)과 데코레이터 패턴(부가 기능 추가)으로 분류  
  
1. 프록시 패턴(접근 제어)  

    권한에 따른 접근 차단, 캐싱, 지연로딩
    
2. 데코레이터 패턴(부가 기능 추가)  

    기존 서버가 제공하는 기능보다 추가 기능을 수행

<br>

## 접근 제어
프록시 객체는 실제 객체(target)를 참조  
값을 저장한 후 재호출시 캐시된 값을 반환  

````java
@Slf4j
public class CacheProxy implements Subject {

    private Subject target;
    private String cacheValue;

    public CacheProxy(Subject target) {
        this.target = target;
    }

    @Override
    public String operation() {
        log.info("call proxy");
        if (cacheValue == null) {
            cacheValue = target.operation();
        }
        return cacheValue;
    }
}
````

<br>

## 부가 기능 추가
프록시 객체에서 부가 기능을 추가해가면서 실체 객체 호출  
체이닝 방식으로 부가 기능 추가 가능  

### 메시지 데코레이터
````java
@Slf4j
public class MessageDecorator implements Component {

    private Component component;

    public MessageDecorator(Component component) {
        this.component = component;
    }

    @Override
    public String operation() {
        log.info("call MessageDecorator");
        String result = component.operation();
        return "*****" + result + "*****";
    }
}
````

<br>

### 타임 데코레이터
````java
@Slf4j
public class TimeDecorator implements Component {

    private Component component;

    public TimeDecorator(Component component) {
        this.component = component;
    }

    @Override
    public String operation() {
        log.info("call TimeDecorator");
        long startTime = System.currentTimeMillis();
        String result = component.operation();
        long endTime = System.currentTimeMillis();
        log.info("total time={}ms", endTime - startTime);
        return result;
    }
}
````

<br>
