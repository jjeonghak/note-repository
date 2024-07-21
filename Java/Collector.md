## Collector
리듀싱 연산(컬렉터)을 어떻게 구현할지 제공하는 메서드 집합으로 구성  
T는 수집될 스트림 항목의 제네릭 형식  
A는 누적자, 수집 과정에서 중간 결과를 누적하는 객체의 형식  
R은 수집 연산 결과 객체의 형식(보통 컬렉션 형식)  

````java
public interface Collector<T, A, R> {
    Supplier<A> supplier();
    BiConsumer<A, T> accumulator();
    Function<A, R> finisher();
    BinaryOperator<A> combiner();
    Set<Characteristics> characteristics();
    ...
}

//컬렉터 인터페이스 구현
pulbic class ToListCollector<T> implements Collector<T, List<T>, List<T>>

List<Dish> dishes = menuStream.collect(new ToListCollector<Dish>());
````

<br>

## Collector 메서드
1. supplier  
빈 결과로 이루어진 Supplier 반환  
수집 과정에서 빈 누적자 인스턴스를 생성하는 파라미터 없는 메서드  

````java
public Supplier<List<T>> supplier() {
    return () -> new ArrayList<T>();
    //return ArrayList::new;  생성자 참조 전달 방식
}
````

<br>

2. accumulator  
리듀싱 연산을 수행하는 메서드 반환  
스트림의 n번째 요소 탐색시 두 인수, 즉 누적자와 n번째 요소를 메서드에 적용  

````java
public BiConsumer<List<T>, T> accumulator() {
    return (list, item) -> list.add(item);
    //return List::add; 메서드 참조 전달 방식
}
````

<br>

3. finisher  
스트림 탐색을 끝내고 누적자 객체를 최종 결과로 변환  
누적자 객체가 이미 최종 결과인 경우 항등 함수 반환  

````java    
public Function<List<T>, List<T>> finisher() {
    return Function.identity();
}
````

<br>

4. combiner  
리듀싱 연산에서 사용할 함수를 반환  
스트림의 서로 다른 서브파트 병렬 처리시 누적자 결과를 어떻게 처리할지 정의  
스트림 분할 정의 조건이 거짓이 될 때까지 스트림을 재귀적으로 분할  
서브스트림의 각 요소에 리듀싱 연산을 순차적으로 적용  
combiner 메서드의 분할 결과를 종합해서 finisher 메서드에 전달  
병렬 처리하지 않아 combiner 메서드가 호출되지 않는다면 UnsupportedOperationException 발생하도록 구현  

````java  
pulbic BinaryOperator<List<T>> combiner() {
    return (list1, list2) -> {
        list1.addAll(list2);
        return list1;
    }
}
````

<br>

5. characteristics  
컬렉터의 연산을 정의하는 Characteristics 형식의 불변 집합 반환(열거형)  
스트림 리듀스 방식의 병렬 여부 및 최적화에 대한 힌트 제공



| 구분 | 설명 |
| ----- | ----- |
| UNORDERED | 리듀싱 결과는 스트림 요소의 방문 순서나 누적 순서에 영향 받지 않음 |
| CONCURRENT | 다중 스레드에서 accumulator 메서드를 동시 호출 및 병렬 리듀싱 가능 <br> 컬렉터 플래그에 UNORDERED 설정이 없다면 요소의 순서가 무의미한 상황에서만 병렬 리듀싱 수행 |
| IDENTITY_FINISH | 리듀싱 결과는 스트림 요소의 방문 순서나 누적 순서에 영향 받지 않음 <br> finisher 메서드 생략 가능 및 누적자 A를 결과 R로 안전한 형변환 가능 |


````java
public Set<Characteristics> characteristics() {
    return Collections.unmodifiableSet(
        EnumSet.of(IDENTITY_FINISH, CONCURRENT));
}
````

<br>

## 컬렉터 구현 없이 커스텀
IDENTITY_FINISH 수집 연산은 구현체 없이 같은 결과 가능

````java
List<Dish> dishes = menuStream.collect(
    ArrayList::new, //빌헹
    List::add       //누적
    List::addAll    //합침
);
````

<br>


