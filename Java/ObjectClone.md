## Cloneable
복제해도 되는 클래스임을 명시하는 용도의 믹스인 인터페이스(mixin interface)  
의도한 목적과는 다르게 clone 메서드가 선언되지 않음(Object에 protected로 선언)  
Cloneable 구현만으로 clone 메서드 호출 불가  
메서드 하나 없는 Cloneable 인터페이스는 Object clone 메서드의 동작 방식을 결정  
Cloneable을 구현한 클래스 인스턴스에서 clone 호출시 필드를 모두 복사한 객체를 반환  
Cloneable을 구현하지 않은 클래스 인스턴스에서 clone 호출시 CloneNotSupportedException 예외 발생  
Cloneable이 구현된 클래스는 clone 메서드를 public으로 제공하기를 기대  
Cloneable을 구현한 클래스는 반드시 clone 재정의  

<br>

## clone 규약  
이 객체의 본사본을 생성해서 반환  
super.clone()을 통해 얻은 객체에 공변 반환 타이핑을 이용하는 것을 권장  
사실상 생성자와 같은 효과(원본 객체에 아무런 해를 끼치지 않는 깊은 복사)  
일반적으로 어떤 객체 x에 대해 아래의 식은 참  

````java
x.clone() != x
x.clone().getClass() == x.getClass()
x.clone().equals(x)
````

<br>

## 가변객체를 참조하지 않는 클래스
````java
@Override public PhoneNumber clone() {
    try {
        return (PhoneNumber) super.clone();
    } catch (CloneNotSupportedException e) {
        throws new AssertionError(); //일어날 수 없는 일
    }
}
````

<br>
    
## 가변객체를 참조하는 클래스, 재귀적으로 clone 호출
````java
public class Stack implements Cloneable {
    private Object[] elements;  //가변객체
    private int size = 0;
    private static final int DEFAULT_INITIAL_CAPACITY = 16;
    
    @Override public Stack clone() {
        try {
            Stack result = (Stack) super.clone();   //elements 얕은 복사 발생
            result.elements = elements.clone();     //배열의 clone 메서드 호출
            return result;
        } catch (CloneNotSupportedException e) {
            throw new AssertionError();
        }
    }
    
    ...
}
````

<br>

## 복사 생성자(변환 생성자, conversion constructor)와 복사 팩토리(변환 팩토리, conversion factory)
생성자를 사용하지 않는 clone 메서드보다 나은 객체 복사 방식 제공  
정상적인 final 필드 용법과 충돌없음  
불필요한 검사 예외와 형변환 필요없음  
해당 클래스가 구현한 인터페이스 타입의 인스턴스를 인수로 사용가능  

````java
//복사 생성자(변환 생성자)
public Yum(Yum yum) { ... };

//복사 팩토리(변환 팩토리)
public static Yum newInstance(Yum yum) { ... };
````

<br>
