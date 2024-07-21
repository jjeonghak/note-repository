## 자바의 안전성
자바는 네이티브 메서드를 사용하지 않음  
C/C++ 같이 버퍼 오버런, 배열 오버런, 댕글링 포인터 같은 메모리 충동 오류로부터 안전  
메모리 전체를 하나의 거대한 배열로 다루는 언어와는 상이  
하지만 다른 클래스로부터 불변식 위반 가능  

<br>

## 방어적 복사
클라이언트가 불변식을 깨뜨리려는 노력을 한다고 가정하고 방어적으로 프로그래밍 필수  
클래스가 클라이언트로부터 받는 혹은 클라이언트로 반환하는 구성요소가 가변이라면 반드시 방어적 복사  
신뢰한다면 생략가능하나 해당 구성요소를 수정했을 경우 책임이 클라이언트에 있음을   

````java
//불변식 위반
public final class Period {
    private final Date start;
    private final Date end;
    
    /**
     * @param start 시작 시각
     * @param end 종료시각; 시작 시각보다 뒤어야 한다.
     * @throws IllegalArgumentException 시작 시각이 종료 시각보다 늦을 때 발생한다.
     * @throws NullPointerException start나 en가 null이면 발생한다.
     */
    public Period(Date start, Date end) {
        if (start.compareTo(end) > 0)
            throw new IllegalArgmentException(start + "가 " + end + "보다 늦다.");
        this.start = start;
        this.end = end;
    }
    
    public Period end() {
        return end;
    }
    
    ...
}

Date start = new Date();
Date end = new Date();
Period p = new Period(start, end);
end.setYear(78); //p의 내부 수정, Date는 가변 객체
//Date는 낡은 API
//Date 보단 불변 객체인 Instant, LcalDateTime, ZonedDateTime 사용 권장
````

<br>

## 방어적 복사로 불변식 방어
````java
public Period(Date start, Date end) {
    //매개변수가 제 3자에 의해 확장가능한 경우 clone 사용 금지
    this.start = new Date(start.getTime());
    this.end = new Date(end.getTime());
    
    //방어적 복사본 생성 후 매개변수 유효성 검사순으로 구현
    //멀티스레드 환경이라면 원본 객체의 유효성 검사 후 복사본을 만드는 과정에 값 변경 위험 존재
    //컴퓨터 보안 분야는 검사시점/사용시점(time-of-check/time-of-use) 공격 혹은 TOCTOU 공격이라고 부름
    if (start.compareTo(end) > 0)
        throw new IllegalArgmentException(start + "가 " + end + "보다 늦다.");
}

p.end().setYear(78);  //p의 내부 수정, Period 객체를 불변으로 변경 필수

public Date end() {
    return new Date(end.getTime());
}
````

<br>

