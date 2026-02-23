# 클래스 파일

## 플랫폼 독립성
자바 가상머신이 다양한 플랫폼을 지원, 동일한 프로그램 저장 형식 지원  
자바 가상머신은 자바 뿐만 아니라 다른 언어도 지원  

<br>

<img width="500" height="300" alt="language_independence" src="https://github.com/user-attachments/assets/a2e68a5c-fb2b-4c66-aab9-ce0005f2c491" />

언어 독립성을 보장하는 핵심은 가상머신과 바이트코드 저장 형식  
자바 가상머신은 자바 언어를 포함한 어떤 언어에도 종속되지 않고 클래스 파일이라는 특정 바이너리 파일 형식에만 의존  
바이트코드 형식은 튜링 완전(`turing complete`)하기 때문에 어떠한 언어도 표현 보장  

<br>

## 클래스 파일 구조
자바 기술이 항상 하위 호환성을 잘 유지할 수 있었던 이유가 안정적인 클래스 파일 구조  
모든 클래스 파일은 각각 하나의 클래스 또는 인터페이스 정의  
클래스 파일은 바이트를 하나의 단위로 하는 이진 스트림 집합체로 정해진 순서에 맞게 조밀하게 나열  
낭비없이 큰 단위의 바이트가 먼저 저장되는 빅 엔디언 방식으로 표현  
클래스 파일에 데이터를 저장하는 데는 c 언어의 구조체와 비슷한 의사 구조를 사용  
`부호 없는 숫자`(u1, u2, u4, u8)와 `테이블`(_info) 두가지 데이터 타입만 존재  

```c
ClassFile {
  u4              magic;
  u2              minor_version;
  u2              major_version;
  u2              constant_pool_count;
  cp_info         constant_pool[constant_pool_count-1];
  u2              access_flags;
  u2              this_class;
  u2              super_class;
  u2              interfaces_count;
  u2              interfaces[interfaces_count];
  u2              fields_count;
  field_info      fields[fields_count];
  u2              methods_count;
  method_info     methods[methods_count];
  u2              attributes_count;
  attribute_info  attributes[attributes_count];
}
```

<br>

### 매직 넘버와 클래스 파일 버전
모든 클래스 파일의 처음 `4byte`는 매직 넘버로 시작(`0xCAFEBASE`)  
가상머신이 허용하는 클래스 파일인지 여부를 빠르게 확인하는 용도로만 사용  
매직 넘버 다음 `4byte`는 클래스 파일의 버전 번호(마이너 버전 + 메이저 버전)  
하위 버전 JDK가 파일 형식이 변경되지 않았더라도 상위 버전 클래스 파일을 실행 금지  

<br>

```java
package org.fenixsoft.clazz;

/**
 * JDK 17 version
 */
public class TestClass {
  private int m;

  public int inc() {
    return m + 1;
  }
}
```

<img width="550" height="150" alt="java_class_file" src="https://github.com/user-attachments/assets/36b29b04-2d26-403a-94e1-6e9ae9555578" />

<br>
<br>

### 상수풀
버전 번호 다음으로 상수풀은 클래스 파일의 자원 창고  
클래스 파일 구조에서 다른 클래스와 가장 많이 연관된 부분  
클래스 파일에서 가장 먼저 등장하는 테이블 타입 데이터 항목  
상수의 수는 고정적이지 않기 때문에 항목 개수를 알려주는 데이터 필요  
해당 필드만 0이 아닌 `1`부터 시작, 0은 참조하지 않음을 표시  

<br>

<img width="550" height="150" alt="constant_pool" src="https://github.com/user-attachments/assets/fd1f9946-de45-45e2-ab43-f51234e607b1" />

상수 풀에 담기는 상수 유형은 `리터럴`과 `심벌 참조`   
- 모듈에서 익스포트하거나 임포트하는 패키지
- 클래스와 인터페이스 이름
- 필드 이름과 서술자
- 메서드 이름과 서술자
- 메서드 핸들과 메서드 타입
- 동적으로 계산되는 호출 사이트와 동적으로 계산되는 상수














