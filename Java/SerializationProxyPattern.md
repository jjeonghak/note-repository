## 직렬화 프록시 패턴
바깥 클래스의 논리적 상태를 정밀하게 표현한 중첩 클래스 설계한 후 private static 선언  
중첩 클래스의 생성자는 단 하나이며 바깥 클래스를 매개변수로 받아야 함  
일관성 검사 및 방어적 복사 필요없이 인수로 넘어온 인스턴스 데이터 복사  
바깥 클래스와 직렬화 프록시 모두 Serializable 구현  
writeReplace 메서드를 통해 직렬화 시스템은 결코 바깥 클래스의 직렬화된 인스턴스를 생성 불가  
가짜 바이트 스트림 공격과 내부 필드 탈취 공격을 프록시 수준에서 차단  
여러 직렬화 방식과 달리 final 선언해도 불변 클래스로 사용 가능  
역직렬화한 인스턴스와 원래의 직렬화된 인스턴스 클래스가 상이해도 정상 작동(EnumSet 사용시 매우 유용)  
클라이언트가 확장 가능한 클래스에 적용 불가  
객체 그래프 순환이 있는 클래스 적용 불가  
성능이 방어적 복사에 비해   

<br>

### Period 클래스용 직렬화 프록시
````java
private static class SerializationProxy implements Serializable {
    private final Date start;
    private final Date end;
    
    SerializationProxy(Period p) {
        this.start = p.start;
        this.end = p.end;
    }
    
    private static final long serialVersionUID = 234098243823485285L;
}
````

<br>

### 바깥 클래스의 직렬화 프록시 패턴용 writeReplate 메서드
````java
private Object writeReplace() {
    //해당 메서드는 직렬화 시스템이 바깥 클래스의 인스턴스 대신 SerializationProxy 인스턴스를 반환
    //직렬화가 이뤄지기 전에 바깥 클래스의 인스턴스를 직렬화 프록시로 변환
    return new SerializationProxy(this);
}
````

<br>

### 바깥 클래스의 직렬화 프록시 패턴용 readObject 메서드
````java
private void readObject(ObjectInpurStream stream) throws new InalidObjectException {
    throw new InvalidObjectException("need proxy instance");
}
````

<br>

### Period.SerializationProxy용 readResolve 메서드
````java
private Object readResolve() {
    //공개된 API만을 이용해 바깥 클래스 인스턴스 생성
    //직렬화의 언어도단적 특성을 상당 부분 제거
    return new Period(start, end);
}
````

<br>

## EnumSet
public 생성자가 없이 정적 팩토리만 제공  
열거 타입의 크기에 따라(64 이하, 초과) RegularEnumSet, JumboEnumSet 사용  
원소 64개의 RegularEnumSet 인스턴스를 직렬화 후 원소를 추가하는 경우 JumboEnumSet으로 역직렬화 필요  
직렬화 프록시 패턴을 사용해서 직렬화 전후 클래스 차이 무시  

<br>

### EnumSet 직렬화 프록시
````java
private static class SerializationProxy <E extends Enum<E>> implements Serializable {
    //EnumSet의 원소 타입
    private final Class<E> elementType;
    //EnumSet의 원소
    private final Enum<?>[] elements;
    
    SerializationProxy(EnumSet<E> set) {
        elementType = set.elementType;
        elements = set.toArray(new Enum<?>[0]);
    }
    
    private Object readResolve() {
        EnumSet<E> result = EnumSet.noneOf(elementType);
        for (Enum<?> e : elements)
            result.add((E) e);
        return result;
    }
    
    private static final long serialversionUID = 362491234563181265L;
}
````

<br>

