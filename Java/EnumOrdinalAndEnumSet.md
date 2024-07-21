## ordinal
대부분의 열거 타입 상수는 하나의 정숫값에 대응  
열거 타입의 몇 번째 위치인지 반환  
ordinal 메서드보단 인스턴스 필드에 저장 권장  
ordinal 인덱싱보단 EnumMap 권장  

````java
//유지보수가 힘든 ordinal 방식
public enum Ensemble {
    SOLO, DUET, TRIO, QUARTET, QUINTET,
    SEXTET, SEPTET, OCTET, NONET, DECTET;
    
    public int numberOfMusicians() { return ordinal() + 1; }
}

//ordinal 메서드가 아닌 인스턴스 필드 저장 방식
public enum Ensemble {
    SOLO(1), DUET(2), TRIO(3), QUARTET(4), QUINTET(5),
    SEXTET(6), SEPTET(7), OCTET(8), DOUBLE_QUARTET(8),
    NONET(9), DECTET(10), TRIPLE_QUARTET(12);
    
    private final int numberOfMusicians;
    Ensemble(int size) { this.numberOfMusicians = size; }
    public int numberOfMusicians() { return numberOfMusicians; }
}
````

<br>

## EnumSet
열거한 값들이 주로 집합으로 사용되는 경우  
비트 필드 방식보다 EnumSet 권장  
Set 인터페이스 완벽히 구현 및 내부적으로 비트 벡터로 구현  

````java
//비트 필드 열거 상수
public class Text {
    public static final int STYLE_BOLD          = 1 << 0;
    public static final int STYLE_ITALIC        = 1 << 1;
    public static final int STYLE_UNDERLINE     = 1 << 2;
    public static final int STYLE_STRIKETHROUGH = 1 << 3;
    
    public void applyStyles(int styles) { ... }
}

//EnumSet
public class Text {
    public enum Style { BOLD, ITALIC, UNDERLINE, STRIKETHROUGH }
    
    public void applyStyles(Set<Style> styles) { ... }
}
````

<br>

## EnumMap
배열이나 리스트에서 원소를 꺼낼 때 ordinal 메서드보다 권장  

````java
//ordinal 인덱싱 방식
Set<Plant>[] plantsByLifeCycle = (Set<Plant>[]) new Set[Plant.LifeCycle.values().length];
for (int i = 0; i < plantsByLifeCycle.length; i++)
    plantsByLifeCycle[i] = new HashSet<>();
for (Plant p : garden)
    plantsByLifeCycle[p.lifeCycle.ordinal()].add(p);

//EnumMap
Map<Pant.LifeCycle, Set<Plant>> plantsByLifeCycle = new EnumMap<>(Plant.LifeCycle.class);
for (Plant.LifeCycle lc : Plant.LifeCycle.values())
    plantsByLifeCycle.put(lc, new HashSet<>());
for (Plant p : garden)
    plantsByLifeCycle.get(p.lifeCycle).add(p);

//스트림 사용
Arrays.stream(garden).collect(groupingBy(p -> p.lifeCycle,
    () -> new EnumMap<>(LifeCycle.class), toSet()));
````

<br>
