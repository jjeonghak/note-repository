## 매개변수
메서드와 생성자 대부분은 입력 매개변수의 값이 특정 조건으로 제약  
이런 메서드의 매개변수 제약은 문서화 필수  
메서드 몸체 실행전 매개변수 제약을 만족하지 못한 경우 예외 발생 방식 사용  

<br>

## 매개변수 제약 검사를 하지않고 실행된 경우
1. 메서드가 수행되는 중간에 모호한 예외 발생   
2. 메서드가 잘 실행되지만 잘못된 결과 반환 후 어떤 객체의 상태에 영향  
    알 수 없는 미래에 메서드와 관련 없는 오류 발생  
    매개변수 검사에 실패후 실패 원자성(failure atomicity) 위반  
    매개변수가 잘못된 경우 보통 IllegalArgumentException, IndexOutOfBoundsException, NullPointerException  

    ````java
    //올바른 메서드 명세
    /**
     * (현재 값 mod m) 값을 반환한다. 이 메서드는
     * 항상 음이 아닌 BigInteger를 반환한다는 점에서 remainder 메서드와 다르다.
     *
     * @param m 계수(양수여야 한다.)
     * @return 현재 값 mod m
     * @throws ArithmeticException m이 0보다 작거나 같으면 발생한다.
     */
    public BigInteger mod(BigInteger m) {   
        if (m.signum() <= 0)     //m이 null일 때 NullPointersException 발생, 이미 BigInteger 명세 존재
            throw new ArithmeticException("계수(m)는 양수여야 합니다. " + m);
        ...
    }
    ````

<br>
  
## null 검사
자바 7에 추가된 java.util.Objects.requireNonNull 메서드를 이용해 검사  

````java
this.strategy = Object.requireNonNull(strategy, "전략");    //반환값은 무시하고 순수하게 null 검사 목적
````

<br>

## 단언문 사용
단언문은 자신이 단언한 조건이 무조건 참이라고 선언  
실패한 경우 AsserttionError 발생  
런타임에 아무런 효과 및 성능 저하 없음(-ea, -enableassertions 플래그 사용시 런타임에 영향)  

````java
private static void sort(long a[]. int offset, int length) {
    assert a != null;
    assert offset >= 0 && offset <= a.length;
    assert length >= 0 && length <= a - offset;
    ...
}
````

<br>


