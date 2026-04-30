## 프록시
대리라는 의미  
CGLIB 라이브러리로 내 클래스 상속받은 가짜 프록시 객체 생성  

    MyLogger -> MyLogger$$EnhanceBySpringCGLIB
    
의존관계 주입 시점에 생성되지 않은 클래스에 대해 가짜 프록시 클래스를 만들어 미리 주입  
가짜 프록시 객체는 요청이 오면 그때 내부에서 진짜 빈을 요청하는 위임 로직 보유  
진짜 객체 조회는 필요한 시점까지 지연처리  
Provider를 이용하지 않고 기존 싱글톤 스코프 코드와 동일하게 사용가능  

클래스 : @Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS)  
인터페이스 : @Scope(value = "request", proxyMode = ScopedProxyMode.INTERFACES)  
  
<br>
  
## 비교

### Provider
리퀘스트 스코프 빈
````java
@Scope("request") 
public class MyLogger {}
````

다른 빈에서 주입 및 사용
````java
//의존관계 주입 시점에 리퀘스트 스코프 빈이 존재하지 않으므로 provider 사용
private final ObjectProvider<MyLogger> myLoggerProvider;
//필요시점에 의존관계 탐색(DL)
MyLogger myLogger = myLoggerProvider.getObject();
myLogger.log();
````

<br>

### Proxy
리퀘스트 스코프 프록시 모드 빈
````java
@Scope(value = "request", proxyMode = ScopedProxyMode.TARGET_CLASS) 
public class MyLogger {}
````

다른 빈에서 주입 및 사용
````java
private final MyLogger myLogger; 
myLogger.log();
````

<br>
