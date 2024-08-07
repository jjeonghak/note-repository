## 동작 파라미터
함수를 일급시민(값)으로 여기고 파라미터 값으로 활용  
전략 패턴과 함께 사용해서 유지보수성 높임  
컬렉션 탐색 로직과 각 항목에 적용할 동작을 분리 가능  
  
<br>

## 프레디케이트
참 또는 거짓을 반환하는 함수  

````java
//프레디케이트 인터페이스
public interface ApplePredicate {
    boolean test(Apple apple);
}

//전략 패턴을 위한 구현체
public class AppleHeavyWeightPredicate implements ApplePredicate {
    public boolean test(Apple apple) {
        return apple.getWeight() > 150;
    }
}

public class AppleGreenColorPredicate implements ApplePredicate {
    public boolean test(Apple apple) {
        return GREEN.equals(apple.getColor);
    }
}
````

<br>

## 추상적 프레디케이트 필터링
프레디케이트와 전략 패턴을 이용한 유연한 필터링  
프레디케이트를 구현한 구현체가 아닌 람다식 또는 익명클래스로도 가능  

````java
//유연하지만 Apple에만 적용가능
public static List<Apple> filterApples(List<Apple> inventory, ApplePredicate p) {
    List<Apple> result = new ArrayList<>();
    for (Apple apple : inventory) {
        if (p.test(apple)) {
            result.add(apple);
        }
    }
    return result;
}

//유연한 필터 클래스
public static <T> List<T> filter(List<T> list, Predicate<T> p) {
    List<T> result = new ArrayList<>();
    for (T e : list) {
        if (p.test()) {
            result.add(e);
        }
    }
    return result;
}
````

<br>

