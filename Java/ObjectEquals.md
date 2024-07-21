## equals
재정의하지 않는 경우 그 클래스의 인스턴스는 오직 자기 자신과만 같음  
객체 식별성(object identity)가 아닌 논리적 동치성(logical equality)을 검사하는 경우 재정의  
Integer와 String 클래스와 같이 객체가 아닌 값이 같은지 검사하는 경우 재정의  
값 클래스라도 같은 값의 인스턴스가 만들어지지 않음을 보장하는 통제 클래스(Enum)인 경우 재정의 불필요  

<br>

## equals 재정의 불필요한 경우
1. 각 인스턴스가 본질적으로 고유  
    값을 표현하는 것이 아닌 동작하는 개체를 표현하는 클래스(Thread)  

2. 인스턴스의 논리적 동치성을 검사하지 않는 경우  
    java.util.regex.Pattern은 equals를 재정의해서 정규표현식을 검사  

3. 상위 클래스에서 재정의한 equals가 하위 클래스에도 적합  
    AbstractSet -&gt; Set 구현체, AbstractList -&gt; List 구현체, AbstractMap -&gt; Map 구현체  

4. private 또는 package-private인 클래스에서 equals 메서드를 호출하지 않는 경우  
    ````java
    @Override p[ublic boolean equals(Object o) {
        throw new AssertionError();
    }
    ````

<br>

## equals 동치관계(equivalence relation)
동치관계 구현 필수, 많은 클래스는 전달받은 객체가 equals 규약을 만족한다고 가정한 후 동작  
  
1. 반사성(reflexivity) : null이 아닌 모든 참조값 x에 대해 x.equals(x) == true  
      객체는 자기 자신과는 같음, 이 규약을 만족하지 않는 경우 컬렉션의 contains 메서드에서 방금 넣은 인스턴스를 없다고 판정  
    
2. 대칭성(symmetry) : null이 아닌 모든 참조값 x, y에 대해 x.equals(y) == y.equals(x)  
      두 객체는 서로에 대한 동치 여부에 대해 똑같은 답을 반환  
    
3. 추이성(transitivity) : null이 아닌 모든 참조값 x, y, z에 대해 x.equals(y) == true && y.equals(z) == true인 경우 x.equals(z) == true  
      첫번째 객체와 두번째 객체가 같고, 구번째 객체와 세번째 객체가 같다면, 첫번째 객체와 세번째 객체도 같음을 보장  
      구체 클래스를 확장해 새로운 값을 추가하면서 equals 규약을 만족시킬 방법은 존재하지 않음  
      상속 대신 컴포지션(필드값)으로 사용해서 문제 해결가능  
     
4. 일관성(consistency) : null이 아닌 모든 참조값 x, y에 대해 x.equals(y)의 값은 반복해서 호출해도 변하지 않음  
      두 객체가 같다면 수정되기 전까지는 영원히 같음을 보장  
      클래스가 불변이든 가변이든 equals 판단에 신뢰할 수 없는 자원이 사용되는 것을 금지  
    
5. not-null : null이 아닌 모든 참조값 x에 대해 x.equals(null) == false  
      모든 객체는 null과 같지 않음을 보장(instanceof 사용시 첫번째 피연산자가 null이면 false 반환)  
      NullPointerException 예외 발생하는 것을 금지  

<br>

## 올바른 equals 구현
대칭적인가? 추이성이 있는가? 일관적인가?  

1. == 연산자를 사용해서 입력이 자기 자신의 참조인지 확인  
2. instanceof 연산자로 입력이 올바른 타입인지 확인  
3. 입력을 올바른 타입으로 형변환  
4. 입력 객체와 자기 자신의 대응되는 핵심필드들이 모두 일치하는지 검사  
5. equals 재정의시 hashCode도 반드시 재정의  
6. equals 입력 타입은 반드시 Object  

<br>
