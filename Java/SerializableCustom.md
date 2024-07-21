## 기본 직렬화
객체의 물리적 표현과 논리적 내용이 같은 경우 적합  
기본 직렬화의 경우 객체를 루트로 하는 객체 그래프의 물리적 모습을 효율적으로 인코딩  
객체가 포함한 데이터들과 그 객체에서부터 시작해 접근할 수 있는 모든 객체의 위상까지 기술  
기본 직렬화가 적합하더라도 불변식 보장과 보안을 위해 readObject 메서드 제공해야 할 때가 많음  

<br>

### 기본 직렬화 형태에 적합
````java
public class Name implements Serializable {
    /**
     * 성. null이 아니어야 함.
     * @serial
     */
     private final String lastName;
     
     /**
     * 이름. null이 아니어야 함.
     * @serial
     */
     private final String firstName;
     
     /**
     * 중간이름. 중간이름이 없다면 null.
     * @serial
     */
     private final String middleName;
     
     ...
     
     //논리적으로 이름, 성, 중간이름 
     //물리적으로 3개의 문자열
}
````

<br>

### 기본 직렬화 형태에 적합하지 않음
````java
public final class StringList implements Serializable {
    private int size = 0;
    private Entry head = null;
    
    private static class Entry implements Serializable {
        String data;
        Entry next;
        Entry previous;
    }
    
    ...
    
    //논리적으로 이 클래스는 일련의 문자열을 표현
    //물리적으로 문자열들을 이중 연결 리스트로 연결
    //기본 직렬화 형태 사용시 각 노드의 양방향 연결 정보를 포함한 모든 엔트리를 기록
}
````

<br>

## 논리적, 물리적 차이가 큰 기본 직렬화 문제
1. 공개 API가 현재 내부 표현 방식에 영구히 종속  
    private 필드가 공개 API로 변경  
    더는 사용하지 않더라도 관련 코드를 절대 제거할 수 없음  
    
2. 많은 공간 차지  
    앞 예에서 엔트리 연결 정보는 내부 구현에 해당  
    직렬화 형태에 포함할 가치가 없지만 포함되어 많은 메모리 차지  
    
3. 많은 시간 소요  
    직렬화 로직은 객체 그래프의 위상에 관한 정보가 없음  
    그래프의 모든 객체를 직접 순회함으로 많은 시간 소요  
  
4. 스택 오버플로 발생 가능성  
    기본 직렬화 과전은 객체 그래프를 재귀 순회  
    플랫폼에 따라 스택 오버플로 최소 크기가 상이하기 때문에 발생 가능성 존재  

<br>

## 커스텀 직렬화
논리적, 물리적 차이가 큰 경우 물리적 상세 표현을 배제한 채 논리적인 구성만 담음  

<br>

### 합리적인 커스텀 직렬화 형태
````java
public final class StringList implements Serializable {
    //transient 한정자는 해당 인스턴스 필드가 기본 직렬화 형태에 포함되지 않음
    private transient int size = 0;
    private transient Entry head = null;
    
    //직렬화되지 않음
    private static class Entry {
        String data;
        Entry next;
        Entry previous;
    }
    
    //지정한 문자열을 이 리스트에 추가
    public final void add(String s) { ... }
    
    /**
     * 이 {@code StringList} 인스턴스를 직렬화한다.
     * 
     * @serialData 이 리스트의 크기(포함된 문자열의 개수)를 기록한 후
     * ({@code int}), 이어서 모든 원소를(각각은 {@code String})
     * 순서대로 기록한다.
     */
    private void writeObject(ObjectOutputStream s) throws IOException {
        //transient 선언하지 않은 필드 직렬화
        s.defaultWriteObject();
        
        s.writeInt(size);
        
        for (Entry e = head; e != null; e = e.next)
            s.writeObject(e.data);
    }
    
    private void readObject(ObjectInputStream s) throws IOException, ClassNotFoundException {
        //transient 선언하지 않은 필드 역직렬화
        //transient 선언된 필드는 기본값으로 초기화
        s.defaultReadObject();
        
        int numElements = s.readInt();
        
        //모든 원소를 읽어 이 리스트에 삽입한다.
        //transient 선언된 필드 값 복원
        for (int i = 0; i < numElements; i++)
            add((String) s.readObject());
    }
    
    ...
}
````

<br>

## 동기화된 클래스 직렬화  
객체 전체 상태를 읽는 메서드에 적용해야하는 동기화 메커니즘을 직렬화에도 적용  
모든 메서드를 synchronized 선언된 객체의 기본 직렬화도 synchronized 선언 필수  
메서드 안에서 동기화를 하는 경우 클래스의 다른 부분에서 사용하는 락 순서로  
> 자원 순서 교착상태(resource-ordering deadlock) 발생 가능성

````java
private synchronized void writeObject(ObjectOutputStream s) throws IOException {
    s.defaultWriteObject();
}
````

<br>

## 직렬 버전 UID  
어떤 직렬화 형태를 택하든 직렬화 가능 클래스 모두에 직렬 버전 UID 명시적 부여  
런타임에 값 생성을 위한 연산 생략 가능  
구버전으로 직렬화된 인스턴스들과의 신버전 호환성을 끊으려는 경우를 제외하곤 직렬 버전 UID 수정 금지  

````java
private static final long serialVersionUID = <무작위 long 값>;
````

<br>
