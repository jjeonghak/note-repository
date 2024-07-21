## 함수형 인터페이스
추상 메서드가 단 하나인 인터페이스  
default, static 메서드의 갯수는 상관없음  
@FunctionalInterface 인터페이스 적용  
대부분 기본 타입만 지원, 박싱된 기본 타입을 넣어 사용하지 않도록 주의  
서로 다른 함수형 인터페이스를 같은 위치의 인수로 사용하는 다중정의   
java.util.function 패키지에는 총 43개의 인터페이스 존재  
6가지로 나머지 유추 가능  

````
//기본 표준 함수형 인터페이스
UnaryOperator<T> : T apply(T t)             //String::toLowerCase
BinaryOperator<T> : T apply(T t1, T t2)     //BigInteger::add
Predicate<T> : boolean test(T t)            //Collection::isEmpty
Function<T,R> : R apply(T t)                //Arrays::asList
Supplier<T> : T get()                       //Instant::now
Consumer<T> : void accept(T t)              //System.out::println
````

<br>
기본 인터페이스는 기본 타입인 int, long, double 용으로 각 3개씩 변형 존재  
    
    IntPredicate, LongBinaryOperator  
    
Supplier만 유일하게 boolean을 이름에 명시한 인터페이스 변형 존재  
  
    BooleanSupplier  

<br>

## Operator
입력과 결과의 타입이 항상 같음  
인수의 갯수에 따라 Unary, Binary 구분  

<br>

## Function
입력과 결과의 타입이 항상 다름  
Function의 변형만 매개변수화(반환 타입만)  
Function 인터페이스에는 기본 타입 반환하는 변형이 9개 존재  
입력과 결과가 모두 기본 타입인 경우 SrcToResult 접두어 사용  
입력이 객체 참조이고 결과가 기본타입인 경우 입력을 매개변수화하고 접두어로 ToReult 사용  

````
LongFunction<int[]>     //long 인수를 받아 int[] 타입 반환
LongToIntFunction       //long 인수를 받아 int 타입 반환
ToLongFunction<int[]>   //int[] 인수를 받아 long 타입 반환
````

<br>

## Bi 변형
기본 인터페이스 중 3개에는 인수를 2개씩 받는 변형 존재  

````
BiPredicate<T,U>

BiConsumer<T,U>
    ObjDoubleConsumer<T>
    ObjIntConsumer<T>
    ObjLongConsumer<T>

BiFunction<T,U,R>
    ToIntBiFuntion<T,U>
    ToLongBiFuntion<T,U>
    ToDoubleBiFuntion<T,U>
````

## Comparator
구조적으로 ToIntBiFunction<T,U>와 동일  
하지만 독자적인 인터페이스로 존재  

1. API에 자주 사용  
2. 구현하는 쪽에서 반드시 지켜야 할 규약 포함  
3. 비교자들을 변환하고 조합하는 유용한 디폴트 메서드 포함  

<br>

## @FunctionalInterface
어노테이션을 사용하는 이유는 @Override 어노테이션과 유사  
    
1. 인터페이스가 람다용으로 설계된 것임을 명시  
2. 인터페이스가 추상 메서드를 오직 하나만 가지고 있어야함 명시  
3. 유지보수 과정에서 메서드 추가 방지  

<br>

