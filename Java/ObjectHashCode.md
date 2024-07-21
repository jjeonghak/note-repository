## Object 명세
equals 비교에 사용되는 정보가 변경되지 않는다면, 애플리케이션이 실행되는 동안 그 객체의 hashCode는 일관성있게 같은 값 반환  
equals(Object)가 두 객체를 같다고 판단한 경우, 두 객체의 hashCode는 같은 값 반환  
equals(Object)가 두 객체가 다르다고 판단한 경우, 두 객체의 hashCode가 서로 다른 값을 반환할 필요 없음  

<br>

## hahsCode 오류
논리적으로 같은 객체는 같은 해시코드를 반환해야함  
hashCode 재정의를 하지않은 경우 논리적으로 같은 객체를 다르게 판단  
HashMap 같은 자료구조는 해시코드가 서로 다른 엔트리끼리의 동치성 비교를 하지 않도록 최적화  

````java
Map<PhoneNumber, String> m = new HashMap<>();
m.put(new PhoneNumber(010, 1234, 5678), "userA");
String username = m.get(new PhoneNumber(010, 1234, 5678));
//username == null, username != "userA"
````

<br>

## hashCode 구현
이상적인 해시 함수는 주어진 인스턴스들을 32비트 정수 범위에서 균일하게 분배  
아래 코드는 동치인 모든 객체에서 똑같은 해시코드를 반환하지만 모든 객체에게 똑같은 값만 반환  
모든 객체가 해시테이블의 버킷 하나에 담겨 마치 연결리스트처럼 동작  

````java
@Override public int hashCode() { return 42; }
````

<br>

1. int 변수 result 선언후 값 c로 초기화  
    c는 해당 객체의 첫번째 핵심필드를 2.a 방식으로 계산한 해시코드  
    
2. 해당 객체의 나머지 핵심필드(f)에 대해 다음 작업 수행   
    a. 해당 필드의 해시코드 c 계산  
      1) 기본타입필드 : Type.hashCode(f) //Type은 해당 기본 타입의 박싱 클래스  
      2) 참조타입필드 : 클래스의 equals 메서드가 필드의 equals 재귀적으로 호출한다면 hashCode를 재귀적으로 호출  
                    계산이 복잡해질 것 같으면 이 필드의 표준형(canonical representation)을 만들어 hashCode 호출  
      3) 배열필드 : 핵심 원소 각각을 별도의 필드처럼 사용  
                  모든 원소가 핵심원소인 경우 Arrays.hashCode 사용  
    b. 해시코드 c로 result 갱신  
      result = 31 * result + c;  
    
3. result 반환  

<br>

## hashCode 구현 주의사항
equals 비교에 사용되지 않은 필드는 반드시 제외  
성능을 위해 해시코드 계산시 핵심필드 생략 금지(해시 품질 저하로 인해 해시테이블 성능이 심각하게 저하)  
해시코드 반환값의 생성 규칙을 API 사용자에게 공표금지  
곱셈을 통해 필드를 곱하는 순서에 따라 result 값 상이(아나그램과 같이 구성하는 요소가 같고 그 순서만 같은 경우)   
곱하는 숫자는 홀수이면서 소수인 수(짝수이고 오버플로 발생시 정보를 잃게됨)  
클래스가 불변이고 해시코드 계산 비용이 크다면 캐싱해서 사용  

<br>

## 전형적인 해시코드 메서드
````java
@Override public int hashCode() {
    int result = Short.hashCode(areaCode);
    result = 31 * result + Short.hashCode(prefix);
    result = 31 * result + Short.hashCode(lineNum);
    return result;
}

//Objects 클래스는 임의의 개수만큼 객체를 받아 해시코드를 계산, 성능이 조금 아쉬움
@Override public int hashCode() {
    return Objects.hash(lineNum, prefix, areaCode);
}
````

<br>
 
## 해시코드 지연초기화 후 캐싱

````java
@Override public int hashCode() {
    int result = hashCode;
    if (result = 0) {
        result = Short.hashCode(areaCode);
        result = 31 * result + Short.hashCode(prefix);
        result = 31 * result + Short.hashCode(lineNum);
        hashCode = result;
    }
    return result;
}
````

<br>

