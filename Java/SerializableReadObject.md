## readObject
매개변수로 바이트 스트림을 받는 실질적으로 또 다른 public 생성자  
다른 생성자와 똑같은 수준으로 주의 필수  
인수의 유효성 검사 및 방어적 복사 필수  

<br>

## 불변식 유효성 검사  
직렬화 가능으로 선언한 경우 생성된 객체 인스턴스의 불변식 확인 필수  

````java
//허용되지 않는 Period 인스턴스 생성 가능성 존재
public class BogusPeriod {
    //실제 Period 인스턴스로 만들어질 수 없는 바이드 스트림
    private static final byte[] serializedForm = {
        (byte)0xac, (byte)0xed, 0x00, 0x05, 0x73, 0x72, 0x00, 0x06,
        0x50, 0x65, 0x72, 0x69, 0x6f, 0x64, 0x40, 0x7e, (byte)0xf8,
        0x2b, 0x4f, 0x46, (byte)0xc0, (byte)0xf4, 0x02, 0x00, 0x02,
        0x4c, 0x00, 0x03, 0x65, 0x6e, 0x64, 0x74, 0x00, 0x10, 0x4c,
        0x6a, 0x61, 0x76, 0x61, 0x2f, 0x75, 0x74, 0x69, 0x6c, 0x2f,
        0x44, 0x61, 0x74, 0x65, 0x3b, 0x4c, 0x00, 0x05, 0x73, 0x74,
        0x61, 0x72, 0x74, 0x71, 0x00, 0x7e, 0x00, 0x01, 0x78, 0x70,
        0x73, 0x72, 0x00, 0x0e, 0x6a, 0x61, 0x76, 0x61, 0x2e, 0x75,
        0x74, 0x69, 0x6c, 0x2e, 0x44, 0x61, 0x74, 0x65, 0x68, 0x6a,
        (byte)0x81, 0x01, 0x4b, 0x59, 0x74, 0x19, 0x03, 0x00, 0x00,
        0x78, 0x70, 0x77, 0x08, 0x00, 0x00, 0x00, 0x66, (byte)0xdf,
        0x6e, 0x1e, 0x00, 0x78, 0x73, 0x71, 0x00, 0x7e, 0x00, 0x03,
        0x77, 0x08, 0x00, 0x00, 0x00, (byte)0xd5, 0x17, 0x69, 0x22,
        0x00, 0x78
    };
    
    public static void main(String[] args) {
        Period p = (Period) deserialize(serializedForm);
        
        //Period를 직렬화 가능으호 선언한 것으로 클래스의 불변식 깨짐
        //Fri Jan 01 12:00:00 PST 1999 - Sun Jan 01 12:00:00 PST 1984
        System.out.println(p);
    }
    
    static Object deserialize(byte[] sf) {
        try {
            return new ObjectInputStream(new BytearrayInputStream(sf)).readObject();
        } catch (IOException | ClassNotFoundException e) {
            throw new IllegalArgumentException(e);
        }
    }
}

//유효성 검사
private void readObject(ObjectInputStream s) throws IOException, ClassNotFoundException {
    s.defaultReadObject();
    
    //불변식 검사
    if (start.compareTo(end) > 0)
        throw new InvalidObjectException(start + ", " + end + " 기간 오류");
}
````

<br>
  
## 방어적 복사
직렬화 이후 생성된 불변 객체 인스턴스를 악의적으로 가변 객체 변경 가능  
역직렬화할 때 클라이언트가 소유해서는 안 되는 객체 참조 필드는 반드시 방어적 복사  

<br>

### 가변 공격
````java
public class MutablePeriod {
    public final Period period;
    public final Date start;
    public final Date end;
    
    public MutablePeriod() {
        try {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            ObjectOutputStream out = new ObjectOutputStream(bos);
            
            //유효한 Period 인스턴스 직렬화
            out.writeObject(new Period(new Date(), new Date()));
            
            /**
             * 악의적인 '이전 객체 참조', 즉 내부 Date 필드로의 참조를 추가한다.
             * 상세 내용은 자바 객체 직렬화 명세의 6.4절을 참고하자.
             */
            byte[] ref = { 0x71, 0, 0x7e, 0, 5 };
            bos.write(ref); //start 필드
            ref[4] = 4;
            bos.write(ref); //end 필드
            
            //Period 역직렬화 후 Date 참조를 훔침
            ObjectInputStream in = new ObjectInputStream(new ByteArrayInputStream(bos.toByteArray()));
            period = (Period) in.readObject();
            start = (Date) in.readObject();
            end = (Date) in.readObject();
        } catch (IOException | ClassNotfoundException e) {
            throw new AssertionError(e);
        }
    }
}

//공격 코드
public static void main(String[] args) {
    MutablePeriod mp = new MutablePeriod();
    Period d = mp.period;
    Date pEnd = mp.end;
    
    pEnd.setYear(78);
    System.out.println(p);  //Wed Nov 22 00:21:29 PST 2023 - Wed Nov 22 00:21:29 PST 1978
}
````

<br>

### 방어적 복사 및 유효성 검사
````java
public void readObject(ObjectInputStream s) throws IOException, ClassNotFoundException {
    s.defaultReadObject();
    
    //가변 요소 방어적 복사
    start = new Date(start.getTime());
    end = new Date(end.getTime());
    
    //불변식 유효성 검사
    if (start.compareTo(end) > 0)
        throw new InvalidObjectException(start + ", " + end + " 기간 오류");
}
````

<br>
