## 의존성 탐색
저장소에 저장되어있는 빈에 접근하기위해 특정 컨테이너가 제공하는 API 이용  
컨테이너 의존성이 높음  
 
<br>

## JSR303 Provider javax.inject
간단한 DL 기능만을 제공  
순환 참조 시에도 사용(A가 B 의존 && B가 A 의존)  
별도의 라이브러리 필요  

````java
implementation 'javax.inject:javax.inject:1'
````

get() 메서드만을 지원  

````java
    private Provider<PrototypeBean> prototypeBeanProvider;
    PrototypeBean prototypeBean = prototypeBeanProvider.get();
````

<br>

````java
public interface Provider<T> {
    /**
     * Provides a fully-constructed and injected instance of {@code T}.
     *
     * @throws RuntimeException if the injector encounters an error while
     *  providing an instance. For example, if an injectable member on
     *  {@code T} throws an exception, the injector may wrap the exception
     *  and throw it to the caller of {@code get()}. Callers should not try
     *  to handle such exceptions as the behavior may vary across injector
     *  implementations and even different configurations of the same injector.
     */
    T get();
}
````

<br>

## ObjectProvider과 JSR-303 Provider
ObjectProvider는 DL을 위한 편의 기능을 많이 제공해주고 별도의 의존관계 추가 필요없음  
하지만 스프링에 의존적이며 다른 컨테이너에서는 사용불가  
다른 컨테이너를 사용할 때에는 JSR-303 Provider 사용  

<br>
