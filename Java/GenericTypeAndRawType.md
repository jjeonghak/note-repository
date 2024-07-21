## 제네릭 타입
클래스와 인터페이스 선언에 타입 매개변수가 쓰이면 제네릭클래스 혹은 제네릭인터페이스  
제네릭 클래스와 제네릭 인터페이스를 통틀어 제네릭 타입  
일련의 매개변수화 타입 정의  
제네릭 타입 하나 정의시 로 타입(raw type)도 함께 정의  
  
<br>

## 제네릭 용어 및 표기예
````
매개변수화 타입(praameterized type) : List<String>
실제 타입 매개변수(actual type parameter) : String
제네릭 타입(generic type) : List<E>
정규 타입 매개변수(formal type parameter) : E
비한정적 와일드카드 타입(unbounded type wildcard type) : List<?>
로 타입(raw type) : List
한정적 타입 매개변수(bounded type parameter) : <E extends Number>
재귀적 타입 한정(recursive type bound) : <T extends Comparable<T>>
한정적 와일드카드 타입(bounded wildcard type) : List<? extends Number>, List<? super Number>
제네릭 메서드(generic method) : static <E> List<E> asList(E[] a)
타입 토큰(type token) : String.class
````

<br>

## 로 타입
제네릭 타입에서 타입 매개변수를 전혀 사용하지 않는 경우(List&lt;E&gt;의 로 타입은 List)  
제네릭 타입이 전부 지워진 것처럼 동작, 제네릭이 도래하기 전 코드와 호환되도록 하기위한 방식  
의도했던 타입이 아닌 다른 타입의 인스턴스를 넣어도 컴파일 실행(사용하는 과정에서 예기치 못한 런타임 오류발생)  
로 타입 사용시 제네릭의 안전성과 표현력을 모두 상실  
자바 9에서 동작하지만 로 타입 특정 상황 외에는 사용 금지  

<br>

### 로 타입을 사용하는 특정상황  
class 리터럴 사용하는 경우(List.class, String[].class, int.class 등)  
instanceof 연산자 사용하는 경우(로 타입이든 비한정적 와일드카드 타입이든 똑같이 동작)  

<br>

### 컬렉션의 로 타입 선언의 문제점  
````java
private final Collection stamps = ...;    //Stamp 객체만 취급
stamps.add(new Coin(...));                //unchecked call 경고 발생
Stamp stamp = (Stamp) stamps.get(...);    //ClassCastException 예외 발생
````

<br>

1. List&lt;Object&gt; 사용  
    로 타입보다 타입 안전성 높음  
    List 매개변수를 받는 메서드에 List&lt;String&gt; 객체를 넘길수 있지만 List&lt;Object&gt; 매개변수를 받는 메서드에는 불가능  
    제네릭 하위 타입 규칙에 의해(List&lt;String&gt;은 List의 하위 타입이지만 List&lt;Object&gt;의 하위 타입은 아님)  
    
2. 비한정적 와일드카드 타입(unbounded wildcard type) 사용  
    Set&lt;E&gt;의 비한정적 와일드카드 타입은 Set&lt;?&gt;  
    Collection&lt;?&gt;에는 어떤 타입이 오든 상관없는 null 외의 어떠한 원소도 추가 불가능  
    로 타입보다 안전  



