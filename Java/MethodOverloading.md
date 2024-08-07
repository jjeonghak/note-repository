## 다중정의와 재정의 차이
다중정의 메서드는 정적으로 컴파일 타임에 메서드 선택  
다중정의로 인한 혼동을 일으키는 상황은 피하는 것 권장  
안전하고 보수적으로, 매개변수 갯수가 같은 다중정의는 피하는 것 권장  
재정의한 메서드는 동적으로 런타임에 메서드 선택  
재정의한 메서드는 컴파일 타임의 타입과 무관하게 가장 하위에서 재정의한 메서드 실행  

````java
//잘못된 다중정의 컬렉션 분류기
public class CollectionClassifier {
    //매개변수의 갯수가 같고 실체화되지 않는 제네릭 타입 다중정의
    public static String classify(Set<?> s)         { return "집합"; }
    public static String classify(List<?> lst)      { return "리스트"; }
    public static String classify(Collection<?> c)  { return "그 외"; }
    
    public static void main(String[] args) {
        Collecton<?>[] collections = {
            new HashSet<String>(),
            new ArrayList<BigInteger>(),
            new HashMAp<String, String>().values()
        };
        for (Collection<?> c : collections)
            System.out.println(classify(c));        //예상과는 다르게 "그 외"만 세번 출력
    }
}
````

<br>

## 올바른 함수 구현
````java
public static String classify(Collection<?> c) {
    return c instanceof Set ? "집합" :
           c instanceof List ? "리스트" : "그 외";
}
````

<br>

## 재정의된 메서드 호출 메커니즘
````java
class Wine {
    String name() { return "포도주"; }
}

class SparklingWine extends Wine {
    @Override String name() { return "발포성 포도주"; }
}

class Champagne extends Wine {
    @Override String name() { return "샴페인"; }
}

public class Overriding {
    public static void main(String[] args) {
        List<Wine> wineList = List.of(
            new Wine(), new SparklingWine(), new Champagne());
        for (Wine wine : wineList)
            System.out.println(wine.name());        //"포도주", "발포성 포도주", "샴페인" 순으로 출력
    }
}
````

<br>

## 다중정의가 아닌 다른 메서드명 사용
ObjectOutputStream 클래스는 write 메서드의 모든 기본 타입과 일부 참조 타입용 변형을 가짐  
다중정의가 아닌 writeBoolean(boolean), writeInt(int), writeLong(long) 식으로 다른 메서드명 사용  
  
<br>


