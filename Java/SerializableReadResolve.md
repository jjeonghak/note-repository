## 싱글톤 직렬화
바깥에서 생성자를 호출하지 못하게 막음으로 인스턴스가 오직 하나만 존재하도록 보장  

````java
public class Elvis {
    public static final Elvis INSTANCE = new Elvis();
    private Elvis() { ... }
    
    public void leaveTheBuilding() { ... }
}
````

<br>

싱글톤으로 정의된 클래스에 implements Serializable 선언시 더 이상 싱글톤으로 유지되지 않음  
readObject 메서드 호출시 이 클래스가 초기화될 때 만들어진 인스턴스와는 별개인 인스턴스 반환  

<br>

## readResolve
readResolve 기능을 사용하면 readObject 메서드가 만들어낸 인스턴스를 다른 것으로 대체 가능  
역직렬화 후 새로 생성된 객체를 인수로 해당 메서드 호출  
해당 메서드가 반환한 객체 참조가 새로 생성된 객체 대신 반환  
이때 새로 생성된 객체의 참조를 유지하지 않은 경우 가비지 컬렉션 대상  
싱글톤으로 선언된 객체가 Serializable 구현한다면 readResolve 메서드를 추가해 싱글톤 속성 유지 가능  

````java
//인스턴스 통제를 위한 readResolve
//역직렬화한 객체는 무시하고 클래스 초기화때 만들어진 인스턴스 반환
private Obejct readResolve() {
    //진짜 Elvis 반환, 가짜 Elvis 가비지 컬렉터 대상
    return INSTANCE;
}
````

<br>

인스턴스 통제를 위해 해당 메서드 사용시 모든 필드를 transient 한정자 사용 필수  
만약 그렇지 않으면 해당 메서드 실행전에 역직렬화된 시점의 인스턴스 참조를 훔칠 가능성 존재  

<br>

### 잘못된 싱글톤 직렬화
````java
public class Elvis implements Serializable {
    public static final Elvis INSTANCE = new Elvis();
    private Elvis();
    
    private String[] data = { "data1", "data2" };
    private Object readResolve() {
        return INSTANCE;
    }
}
````

<br>

### 도둑 클래스
````java
public class ElvisStealer implements Serializable {
    static Elvis impersonator;
    private Elvis payload;
    
    private Object readResolve() {
        //resolve 전에 Elvis 인스턴스 참조 저장
        impersonator = payload;
        //transient 한정자가 없는 필드에 맞는 타입 객체 반환
        return new String[] { "stealer" };
    }
    private static final long serialVerionUID = 0;
}
````

직렬화된 스트림에서 싱글톤의 비휘발성 필드를 이 도둑 인스턴스로 교체  

<br>
  
## 열거타입
transient 한정자를 사용해도 AccessibleObject.setAccessible 특권(privileged) 메서드에 무력화  
직렬화 가능 인스턴스 통제 클래스를 열거 타입으로 구현하면 싱글톤 속성을 자바가 보장  
컴파일타임에 어떤 인스턴스가 존재하는지 알 수 없는 상황이라면 열거 타입 사용 불가  

````java
//전통적 싱글톤보다 우수
public enum Elvis {
    INSTANCE;
    private String[] data = { "data1", "data2" };
    public void printData() {
        System.out.println(Arrays.toString(data));
    }
}
````

<br>
