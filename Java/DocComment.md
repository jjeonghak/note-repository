## 자바독(javadoc)
전총적으로 API 문서는 사람이 직접 작성하므로 코드 변경시 매번 수정  
자바의 자바독 유틸리티가 이 작업을 도움  
소스코드에 문서화 주석이라는 특수한 형태로 기술된 설명을 추려 API 문서로 변환  
문서화 주석에 HTML로 변환, 문서화 주석 안에 HTML 태그 사용 가능  
메서드 주석 상속 가능, 문서화 주석이 없는 API 요소를 클래스보단 인터페이스 위주로 탐색  
  
<br>

## 업계 표준 API
문서화 주석 작성법(How to Write Doc Comments) 웹페이지에 기술  
자바 4 이후 갱신되지 않은 페이지이지만 여전히 사용  
자바 5 @literal, @code 태그 추가   
자바 8 @implSpec 태그 추가  
자바 9 @index 태그 추가  

<br>

## 문서화 주석 작성
API를 올바로 문서화하기 위해 공개된 모든 클래스, 인터페이스, 메서드, 필드 선언에 문서화 주석 필수  
메서드용 문서화 주석에는 해당 메서드와 클라이언트 사이의 규약을 명료하게 기술  
메서드 호출하기 위한 전제조건(precondition), 성공적으로 수행후 사후조건(postcondition) 모두 나열  
사후조건으로 명확히 정의되지 않지만 시스템 상태에 영향을 주는 부작용 또한 문서화  
백그라운드 스레드를 시작시키는 메서드라면 그 사실을 문서에 작성  
각 문서화 주석의 첫 번째 주석은 해당 요소의 요약 설명(summary description)으로 간주  
한 클래스 또는 인터페이스에 요약 설명이 같은 멤버가 둘 이상이면 안됨  
클래스 혹은 정적 메서드가 스레드 안전한지 스레드 안전 수준을 반드시 기술  
직렬화 가능 클래스라면 직렬화 형태 반드시 기술  

<br>

## 메서드 계약(contract)
매개변수에 @param 태그  
반환 타입이 void가 아니라면 @return 태그  
발생한 가능성이 있는(검사, 비검사 상관없이) 모든 예외는 @throws 태그  
관례상 @param, @return 태그의 설명은 해당 매개변수 및 반환값을 설명하는 명사구 사용  
예외적으로 명사구 대신 산술 표현식을 쓰는 경우도 존재(BigInteger @throws)  
관례상 @param, @return, @throws 태그의 설명에 마침표 사용안함  

````java
/**
 * Return the element at the specified position in this list.
 * 
 * <p>This method is <i>not</i> guaranteed to run in constant
 * time. In some implementations it may run in time proportional
 * to the element position.
 *
 * @param   index index of element  to return; must be
 *          non-negative and less than the size of this list
 * @return  the element at the specified position in this list
 * @throws  IndexOutOfBoundsException if the index is out of range
 *          ({@code index < 0 || index >= this.size()})
 */
E get(int index);
````

<br>

## @code 태그
1. 태그로 감싼 내용을 코드용 폰트로 렌더링  
2. 태그로 감싼 내용에 포함된 HTML 요소나 다른 자바독 태그를 무시  
3. 여러 줄의 코드 예시를 사용하는 경우 `<pre>{(@code ...)}</pre>` 형태로 사용  

<br>

## @implSpec 태그
클래스를 상속용으로 설계할 때는 자기사용 패턴(self-use pattern)에 대해서도 문서화 필수  
자바 8에 추가된 @implSpec 태그로 문서화  
다른 문서화 주석과는 다르게 메서드와 클라이언트 사이의 계약이 아닌 메서드와 하위 클래스 사이의 계약 기술  
@implSpec 태그 무시 방지를 위해 자바독 명령 줄에 `-tag "implSpec:a:Implementation Require ments:"`  

````java
  /**
   * Return true if this collection is empty.
   * 
   * @implSpec
   * This implementation returns {@code this.size(0 == 0}.
   *
   * @return true if this collection is empty
   */
  public boolean isEmpty() { ... }
````

<br>

## @literal 태그
API 설명에 &lt;, &gt;, & 등의 HTML 메타문자를 포함하기 위한 처리  
태그 내에 HTML 메타문자 및 자바독 태그 무시  
@code 태그와 다르게 코드 폰트 렌더링이 되지 않음  

````java
* A geometric series converges if {@literal |r| < 1}.
````

<br>

## @index 태그
클래스, 메서드, 필드 같은 API 요소의 색인화  

````java
* This method complies with the {@index IEEE 754} standard.
````

<br>

## 요약 설명
메서드와 생성자의 요약 설명은 해당 동작을 설명하는 동사구  
클래스, 인터페이스, 필드의 요약 설명은 대상을 설명하는 명사절  
어노테이션의 요약 설명은 이 어노테이션을 단다는 것이 어떤 의미인지   

````
ArrayList(int initialCapacity): Constructs an empty list with the specified initial capacity.
Collection.size(): Returns the number of elements in this collection.

Instant: An instantaneous point on the time-line.
Math.PI: The double value that is closer than any other to pi, 
         the ratio of the circumference of a circle to its diameter.
````

<br>

## 제네릭 
제네릭 타입이나 제네릭 메서드를 문서화하는 경우 모든 타입 매개변수에 주석 기술  

````java
/**
 * An object that maps keys to values. A map cannot contain
 * duplicate keys; each key can map to at most one value.
 *
 * (Remainder omitted)
 *
 * @param <K> the type of keys maintained by this map
 * @param <V> the type of mapped values
 */
public interface Map<K, V> { ... }
````

<br>

## 열거 타입
열거 타입을 문서화하는 경우 상수들에도 주석 기술  

````java
/**
 * An instrument section of a symphony orchestra.
 */
public enum OrchestraSection {
    /** Woodwinds, such as flute, clarinet, and oboe. */
    WOODWIND,
    /** Brass instruments, such as french horn and trumpet. */
    BRASS,
    /** Percussion instruments, such as timpani and cymbals. */
    PERCUSSION,
    /** Stringed instruments, such as violin and cello. */
    STRING;
}
````

<br>

## 어노테이션 타입
어노테이션 타입을 문서화하는 경우 멤버들에도 모두 주석  

````java
/**
 * Indicates that the annotated method is a test method that
 * must throw the designed exception to pass.
 */
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface ExceptionTest {
    /**
     * The exception that the annotated test method must throw
     * in order to pass. (The test is permitted to throw any
     * subtype of the type described by this class object.)
     */
     Class<? extends Throwable> value();
}
````

## 패키지 및 모듈
패키지를 설명하는 문서화 주석은 package-info.java 파일에 작성  
모듈을 설명하는 문서화 주석은 module-info.java 파일에   

<br>


