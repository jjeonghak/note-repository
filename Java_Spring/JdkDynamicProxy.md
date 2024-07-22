## JDK 동적 프록시
JDK에서 제공하는 인터페이스 기반 프록시 생성 기술  
인터페이스가 필수적으로 존재  
자바 리플렉션을 이용한 프록시 생성 기술  

<br>

## JDK 동적 프록시 사용 방식
JDK 동적 프록시에 적용할 로직을 InvocationHandler 인터페이스로 구현  
proxy : 프록시 자신  
method : 호출할 메서드  
args : 메서드 호출에 필요한 인수  

````java
public interface InvocationHandler {
    public Object invoke(Object proxy, Method method, Object[] args)
        throws Throwable;
}
````

<br>
