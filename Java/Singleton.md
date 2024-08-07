## 싱글톤
인스턴스를 오직 하나만 생성할 수 있는 클래스  
함수와 같은 무상태 객체 또는 설계상 유일해야 하는 시스템 컴포넌트  

<br>

## 싱글톤 생성
1. 생성자를 private, public static final 인스턴스 상수로 초기화  
    권한이 있는 클라이언트는 리플렉션 API(AccessibleObject.setAccessible)를 통해 생성자 호출가능  

    ````java
    public class Elvis {
        public static final Elvis INSTANCE = new Elvis();
        private Elvis() { ... }
        public void leaveTheBuilding() { ... }
    }
    ````

<br>

2. 정적 팩토리 메서드를 public static 멤버로 제공
    getInstance()는 항상 같은 객체의 참조를 반환, 제2의 Elvis 인스턴스 생성 방지  
    readResolve()를 제공해야 직렬화된 인스턴스를 역직렬화할 때마다 인스턴스 생성 방지 가능  

    ````java
    public class Elvis {
        private static final Elvis INSTANCE = new Elvis();
        public static Elvis getInstance() { return INSTANCE; }
        private Elvis() { ... }
        public void leaveTheBuilding() { ... }
    }
    ````

<br>

3. 원소가 하나인 열거 타입 선언 - 가장 이상적인 싱글톤 방식  
    복잡한 직렬화 상황이나 리플렉션 공격에서도 제2의 인스턴스 생성 방지

    ````java
    public enum Elvis {
        INSTANCE;
    
        public void leaveTheBuilding() { ... }
    }
    ````

<br>

## 인스턴스화 방지
private 생성자를 추가해서 방지  
상속 불가한 클래스 상속 방지  

````java
public class UtilityClass {
    private UtilityClass() {
        throw new AssertionError();
    }
    ...
}
````

<br>
