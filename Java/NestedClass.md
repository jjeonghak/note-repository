## 중첩 클래스
다른 클래스 안에 정의된 클래스  
자신을 감싼 바깥 클래스에서만 사용  
  
1. 정적 멤버 클래스  
2. 내부 클래스(inner class)  
    a) 비정적 멤버 클래스  
    b) 익명 클래스  
    c) 지역 클래스  

<br>

## 정적 멤버 클래스  
다른 클래스 안에 선언되고, 바깥 클래스의 private 멤버에도 접근 가능  
흔히 바깥 클래스와 함께 쓰일 때만 유용한 public 도우미 클래스로 사용  
바깥 인스턴스와 독립적으로 존재할 수 있다면 정적 멤버 클래스로 선언  

````java
//클라이언트는 Calculator.Operation.PLUS, Calculator.Operation.MINUS 형태로 사용
public class Calculator {
    public static enum Operation {
        PLUS, MINUS, ...
    }
    ...
}
````

<br>

## 비정적 멤버 클래스  
바깥 클래스 인스턴스와 암묵적으로 연결(this 용법 사용)  
멤버 클래스가 인스턴스화될 때 바깥 인스턴스와 관계 확립후 변경 불가  
바깥 클래스 인스턴스 메서드에서 비정적 멤버 클래스 생성자를 호출해서 사용  
어댑터 정의시 주로 사용  

````java
public class MySet<e> extends AbstractSet<E> {
    ...
    
    @Override public Iterator<E> iterator() {
        return new MyIterator();
    }
    
    private class MyIterator implements Iterator<E> {
        ...
    }
}
````

<br>

## 익명 클래스
이름이 존재하지 않음  
바깥 클래스의 멤버가 아닌 쓰이는 시점에 선언과 동시에 인스턴스 생성  
상수 표현을 위해 초기화된 final 기본 타입과 문자열 필드만 소유가능  
instanceof 검사나 클래스 이름이 필요한 작업 불가능  
여러 인터페이스를 구현 및 다른 클래스 상속 불가능  
자바의 람다 지원 전에 즉석에서 작은 함수 객체나 처리 객체를 만들때 사용  

<br>

## 지역 클래스
가장 사용 빈도가 낮음  
지역변수 선언 가능한 범위에서 선언 가능(유효범위도 지역변수와 동일)  

<br>

