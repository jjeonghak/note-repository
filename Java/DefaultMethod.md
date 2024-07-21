## 인터페이스 기본 구현
인터페이스를 구현한 기존 코드의 변경 없이 새로운 메서드 추가  
1. 정적 메서드  
2. 디폴트 메서드  
  
<br>

## 정적 메서드
자바에서는 인터페이스와 인터페이스 인스턴스를 활용할 수 있는 정적 메서드가 정의된 유틸리티 클래스 존재  
Collections 유틸리티 클래스를 이용해서 Collection 객체를 활용하는 것  
자바 8 이후부터 인터페이스 내부에 정적 메서드 구현 가능  
과거 버전과의 호환성 유지를 위해 유틸리티 클래스 보존  

<br>

## 디폴트 메서드 
인터페이스에서 기본으로 제공하는 메서드  
다중 상속 동작이라는 유연성 제공  

````java
//List 정렬 메서드
default void sort(Comparator<? super E> c) {
    Collections.sort(this, c);
}

//Collection 스트림 생성 메서드
default Stream<E> stream() {
    return StreamSupport.stream(spliterator(), false);
}
````

<br>

## 선택형 메서드(optional method)
잘 사용되지 않아 인터페이스를 구현할때 빈 구현으로 제공하던 수고를 감소  

````java
interface Iterator<T> {
    boolean hasNext();
    T next();
    default void remove() {
        throw new UnsupportedOperationException();
    }
}
````

<br>

## 동작 다중 상속(multiple inheritance of behavior)
기존에 불가능했던 동작 다중 상속 기능 구현 가능  

````java
//한개의 클래스와 여러 인터페이스 상속 가능
public class ArrayList<E> extends AbstractList<E>
    implements List<E>, RandomAccess, Cloneable, Serializable {
    ...    
}
````

<br>

## 동작 다중 상속 해석 규칙
같은 시그니처를 갖는 디폴트 메서드를 상속받는 상황이 발생하는 경우  
C++ 다이아몬드 문제와 유사  

````java
public interface A {
    default void method() {
        ...
    }
}

public interface B extends A {
    default void method() {
        ...                             //A보다 하위 디폴트 메서드 구현
    }
}

public interface D extends A {
    ...                                 //디폴트 메서드를 구현하지 않으므로 A의 디폴트 메서드
}

public class C implements D, B, A {
    public static void main(String[] args) {
        new C().method();               //B의 디폴트 메서드 실행
    }
}
````

<br>

1. 클래스가 항상 우선순위가 높음  
  클래스 또는 슈퍼클래스의 메서드가 디폴트 메서드보다 우위  
  
2. 클래스가 없는 경우 서브 인터페이스가 우선순위가 높음  
  상속관계를 갖는 인터페이스에서는 상속받은 인터페이스(하위 인터페이스)가 우위  
  
3. 여전히 우선순위가 불확실한 경우 직접 오버라이드  
  명시적으로 오버라이드 이후 호출 필수  

<br>

## 충돌
위의 규칙을 만족하지 않는 경우 오류 발생  
"Error: class C inherits unrelated defaults for method() from types B and A."  

````java
//명시적인 오버라이드 필수
B.super.method();
````

<br>

## 다이아몬드 문제(diamond problem)
다이어그램의 모양이 다이아몬드와 유사  
C++(다중 클래스 상속 지원)와는 다르게 자바에서는 위의 규칙에 의해 해결 가능  

````java
public interface A {
    default void method() {
        ...
    }
}
public interface B extends A { }
public interface C extends A { }
public class D implement B, C {
    public static void main(String[] args) {
        new D().method();                 //A의 디폴틑 메서드 
    }
}
````

<br>

