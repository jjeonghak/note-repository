## Comparable
compareTo 메서드는 Object의 메서드가 아닌 Comparable 메서드  
단순 동치성뿐만 아니라 순서까지 비교  
모든 객체에 대해 전역 동치관계를 부여하는 equals 메서드와는 달리 다른 타입의 객체는 신경쓰지않음  
비교를 활용하는 클래스인 TreeSet, TreeMap, Collections, Arrays 자료구조 사용시 구현  

````java
public interface Comparable<T> {
    int compareTo(T t);
}
````

<br>

## compareTo 규약
이 객체와 주어진 객체의 순서를 비교  
이 객체가 주어진 객체보다 작으면 음수, 같으면 0, 크면 양의 정수 반환  
비교 불가한 타입의 객체가 주어진 경우 ClassCastException 예외 발생  
sgn(표현식) 표기는 수학에서 말하는 부호 함수(signum function  

````java
sgn(x.compareTo(y)) == -sgn(y.compareTo(x))
x.compareTo(y) > 0 && y.compareTo(z) > 0 && x.compareTo(z) > 0
x.compareTo(y) == 0 && sgn(x.compareTo(z)) == sgn(y.compareTo(z))
(x.compareTo(y) == 0) == x.equals(y)
````

<br>

## compareTo 구현
제네릭이므로 인수 타입은 컴파일타임에 정해짐  
Comparable 구현하지 않은 필드나 표준이 아닌 순서로 비교한다면 비교자(Comparator) 사용  
compareTo 메서드에서 관계연산자(&lt;, &gt;)를 사용하는 이전 방식은 권장하지 않음   

<br>

## 객체참조 필드가 하나뿐인 비교자
````java
public final class CaseInsensitiveString implements Comparable<CaseInsensitiveString> {
    public int compareTo(CaseInsensitiveString cis) {
        return String.CASE_INSENSITIVE_ORDER.compare(s, cis);
    }
    ...
}
````

<br>

## 기본타입 필드가 여러개인 비교자
````java
public int compareTo(PhoneNumber pn) {
    int result = Short.compare(areaCode, pn.areaCode);
    if (result == 0) {
        result = Short.compare(prefix, pn.prefix);
        if (result == 0) {
            result = Short.compare(lineNum, pn.lineNum);
        }
    }
    return result;
}
````

<br>

## Comparator
비교자 생성 메서드(comparator construction method) 연쇄 방식으로 비교자 생성 가능  
약간의 성능 저하 발생  

<br>

## 비교자 생성 메서드를 활용한 비교자
````java
private static final Comparator<PhoneNumber> COMPARATOR = 
        comparingInt((PhoneNumber pn) -> pn.areaCode)
              .thenComparingInt(pn -> pn.prefix)
              .thenComparingInt(pn -> pn.lineNum);

public int compareTo(PhoneNumber pn) {
    return COMPARATOR.compare(this, pn);
}
````

<br>

## Comparator 구현
1. 값의 차를 이용한 구현(오버플로 발생 가능성, 권장하지 않음)  
    ````java
    static Comparator<Object> hashCodeOrder = new Comparator<>() {
        public int compare(Object 01, Object o2) {
            return o1.hashCode() - o2.hashCode();
        }
    }
    ````
    
2. 정적 compare 메서드를 활용한 구현  
    ````java
    static Comparator<Object> hashCodeOrder = new Comparator<>() {
        public int compare(Object o1, Object o2) {
            return Integer.compare(o1.hashCode(), o2.hashCode());
        }
    }
    ````
    
3. 비교자 생성 메서드를 활용한 구현  
    ````java
    static Comparator<Object> hashCodeOrder = Comparator.comparingInt(o -> o.hashCode());
    ````

<br>

