## 한정적 와일드카드 타입
매개변수화 타입의 불공변(invariant)한 특성을 유연하게 사용하기 위한 타입  
리스코프 치환원칙에 맞게 유연성 제공  
펙스(PECS) : producer-extends, consumer-super  
나프탈린(Naftalin)과 와들러(Wadler)는 이를 겟풋원칙(Get and Put Principle)으로 부름  
반환 타입에는 한정적 와일드카드 타입 사용불가  
  
1. upper bounded wildcard : E 타입이 아닌 E의 하위타입을 사용할 경우
      ````java
      //와일드 카드 타입을 사용하지 않은 스택 메서드
      public void pushAll(Iterable<E> src) {
          for (E e : src)
              push(e);
      }

      Stack<Number> numberStack = new Stack<>();          //Number 타입
      Iterable<Integer> integers = ...;                   //Integer 타입
      numberStack.pushAll(integers);                      //컴파일오류, incompatible types

      //생산자(producer) 매개변수에 와일드 카드 타입 적용
      public void pushAll(Iterable<? extends E> src) {    //E의 Iterable 타입이 아닌 E의 하위타입의 Iteralbe 타입
          for (E e : src)
              push(e);                                    //E 인스턴스를 생산
      }
      ````

<br>

2. lower bounded wildcard : E 타입이 아닌 E의 상위타입을 사용할 경우
      ````java
      //와일드 카드 타입을 사용하지 않은 스택 메서드
      public void popAll(Collection<E> dst) {
          while (!isEmpty())
              dst.add(pop());
      }

      Stack<Number> numberStack = new Stack<>();          //Number 타입
      Collection<Object> objects = ...;                   //Object 타입
      numberStack.popAll(objects);                        //컴파일오류, incompatible types

      //소비자(consumer) 매개변수에 와일드 카드 타입 적용
      public void popAll(Collection<? super E> dst) {    //E의 Collection 타입이 아닌 E의 상위타입의 Collection 타입
          while (!isEmpty())
              dst.add(pop());                            //E 인스턴스를 소비
      }
      ````

<br>

## 명시적 타입 인수(explicit type argument)
클래스 사용자가 와일드카드 타입을 신경 써야하는 경우는 그 API에 문제가 있을 가능성 있음  

````java
public static <E> Set<E> union(Set<E> s1, Set<E> s2)                        //와일드카드 타입 사용하지 않은 메서드
public static <E> Set<E> union(Set<? extends E> s1, Set<? extends E> s2)    //생산자 와일드카드 타입 메서드

Set<Integer> integers = Set.of(1, 2, 3);
Set<Double> doubles = Set.of(4.0, 5.0, 6.0);
Set<Number> numbers = union(integers, doubles);                 //자바 8 이전에는 컴파일오류, incompatible type
Set<Number> numbers = Union.<Number>union(integers, doubles);   //명시적 타입 인수사용으로 컴파일오류방지


public static <E extends Comparable<E>> E max(List<E> list)                     //와일드카드 타입 사용하지 않은 메서드
public static <E extends Comparable<? super E>> E max(List<? extends E> list)   //소비자 와일드카드 타입 메서드
//기본적으로 Comparable과 Comparator는 언제나 소비자, 자신의 상위타입을 사용해서 구현
````

<br>

## 생산 및 소비 규칙
생산 : 제네릭 파라미터 E에 대해 파라미터를 업캐스팅하는 경우 &lt;? extends E&gt;  
소비 : 제네릭 파라미터 E에 대해 E를 통해 파라미터로 업캐스팅하는 경우 &lt;? super E&gt;  

<br>

## 타입 매개변수와 비교
메서드 선언에 타입 매개변수가 한번만 나오면 와일드카드로 대체  

````java
public static <E> void swap(List<E> list, int i, int j);    //복잡함으로 인해 public API 부적합
public static void swap(List<?> list, int i, int j);        //public API 적합

public static void swap(List<?> list, int i, int j) {       //List<?>에는 null만 삽입가능
    list.set(i, list.set(j, list.get(i));                   //컴파일오류, incompatibal type
}

public static void swap(List<?> list, int i, int j) {
    swapHelper(list, i, j);                                 //도우미 메서드 호출로 컴파일오류 
}

//와일드카드 타입을 실제 타입으로 바꿔주는 private 도우미 메서드
private static <E> void swapHelper(List<E> list, int i, int j) {
    list.set(i, list.set(j, list.set(i));
}
````

<br>

