## serializable
어떤 클래스의 인스턴스를 직렬화 가능하게 하는 기능  
클래스 선엔에 상속만으로 사용 가능  
serializable 구현한 클래스는 릴리스 이후 수정하기 어려움  
직렬화된 바이트 스트림 인코딩도 하나의 공개 API  
이 클래스가 널리 퍼질수록 직렬화 형태도 영원히 지원해야 하는 문제점  
클래스 내부 구현 방식에 영원히 구속되어 유지보수 어려움  
ObjectOutputStream의 putFields와 readFields 메서드를 사용해서 기존 직렬화 형태를 유지하며 내부 표현 변경 가능  
역사적으로 BigInteger와 Instant 같은 값 클래스와 컬렉션 클래스들이 serializable 구현  
스레드 풀처럼 동작하는 객체 클래스는 구현하지 않음  
상속용 클래스 및 인터페이스는 대부분 구현하지 않음  
> Throwable, Component 클래스는 예외  

<br>

## 직렬 버전 UID(serial version UID)  
스트림 고유 식별자  
모든 직렬화된 클래스는 고유 식별 번호 부여  

````java
static final long serialVersionUID;
````

<br>
  
명시하지 않는 경우 런타임에 암호 해시 함수(SHA-1) 적용 및 자동 생성  
이 값은 클래스 이름, 구현한 인터페이스, 대부분의 클래스 멤버들이 고려  
후에 편의 메서드를 추가해서 이들 중 하나라도 수정한다면 직렬 버전 UID 값도 변화  
자동 생성 값에 의존한 경우 InvalidClassException 오류 발생  
  
<br>

## 생성자
객체는 생성자를 통해 생성하는 것이 기본  
직렬화는 언어의 기본 메커니즘을 우회해서 객체 생성하는 기법  
역직렬화는 일반 생성자의 문제가 그대로 적용되는 숨은 생성자  
즉 불변식 깨짐과 허가되지 않은 접근에 쉽게 노출  
  
<br>

## 테스트
직렬화 가능 클래스 수정시 신버전 인스턴스를 직렬화한 후 구버전 역직렬화 가능한지, 그 반대 경우도 테스트  
양방향 직렬화/역직렬화 모두 가능한지 테스트 필수  

<br>

## 구현시 주의 사항
인스턴스 필드 값 중 불변식 보장해야 하는 경우 반드시 하위 클래스에서 finalize 메서드 재정의 금지  
즉 finalize 메서드를 자신이 재정의하면서 final로 선언  
인스턴스 필드 중 기본값(0, false, null)으로 초기화되면 위배되는 불변식이 존재한다면 클래스 readObjectNoData 메서드 반드시 추가  

````java
//기존 직렬화 가능 클래스에 직렬화 가능 상위 클래스를 추가하는 드문 경우를 위한 메서드
private void readObjectNoData() throws InvalidObjectException {
    throw new InvalidObjectException("need stream data");
}
````

<br>
