## 옵셔널
자바 8 이전에는 메서드가 특정 조건에서 값을 반환할 수 없는 경우 예외 또는 null 반환  
자바 8 이후 옵셔널 추가, 옵셔널은 원소를 최대 1개 가질 수 있는 불변 컬렉션  
Optional&lt;T&gt;는 null이 아닌 T 타입 참조를 1개 또는 0개를 가짐  
아무것도 없는 상태는 비어있는 상태, 하나인 상태는 비어있지 않은 상태  
보통 T 타입 값을 반환하지만 특정 조건에는 아무것도 반환하지 않는 경우 사용   
옵셔널을 사용한 메서드는 절대 null 반환 금지  
옵셔널은 검사 예외와 취지가 비슷, 반환값이 없을 수 있음을 명시  
컬렉션, 스트림, 배열, 옵셔널 같은 컨테이너 타입은 옵셔널 랩핑 금지(빈 컨테이너 반환 권장)  
박싱된 기본 타입을 담는 옵셔널 반환 금지  
옵셔널을 컬렉션의 키, 값, 원소나 배열의 원소로 사용 금지  

````java
//옵셔널 사용
public static <E extends Comparable<E>>
        Optional<E> max(Collection<E> c) {
    if (c.isEmpty())
        return Optional.empty();
    ...
    return Optional.of(result);   //result 값이 null인 경우 예외 발생
}

//스트림의 옵셔널 사용
public static <E extends Comparable<E>>
        Optional<E> max(Collection<E> c) {
    return c.stream().max(Comparator.naturalOrder);
}
````

<br>

## 클라이언트 옵셔널 활용
filter, map, flatMap, ifPresent 등 고급 메서드 존재  

````java
//옵셔널 기본 메서드
boolean isNotEmpty = optionalData.isPresent();
String lastWordInLexicon = max(words).get();
String lastWordInLexicon = max(words).orElse("no word");
String lastWordInLexicon = max(words).orElseThrow(TemperTantrumException::new);

//옵셔널 스트림 -> 스트림 변환
streamOfOptionals
    .filter(Optional::isPresent)
    .map(Optional::get)

//옵셔널 스트림 어댑터(옵셔널 스트림 -> 스트림 변환)
streamOfOptionals
    .flatMap(Optional::stream)
````

<br>

## 기본 타입 옵셔널
박싱된 기본 타입을 담는 옵셔널은 기본 타입 자체보다 무거움  
두 겹으로 래핑된 상태이므로 전용 옵셔널 존재  
Optinoal<T> 객체가 제공하는 메서드 대부분 제공  

    OptionalInt, OptionalLong, OptionalDouble

<br>


