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

<br>

자바 코드를 `javac`으로 컴파일할때 c 언어와 달리 링크 단계 없음, 클래스 파일을 로드할때 동적으로  
필드와 메서드가 메모리에서 어떤 구조로 표현되는가에 관한 정보는 클래스 파일에 저장되지 않는다는 뜻  
가상머신이 필드와 메서드의 심벌 참조은 클래스 파일을 로드할때 상수 풀에서 해당 심벌 참조를 가져옴  
이후 클래스가 생성되거나 구동할때 해석하여 실제 메모리 주소로 변환  

<br>

상수 풀 안의 상수 각각이 모두 테이블  
초기에는 17가지 상수 타입 존재, 공통적으로 u1 타입의 플래그 비트로 시작  

<img width="550" height="400" alt="constant_pool_analystics" src="https://github.com/user-attachments/assets/2e710e9f-daad-4dc4-af47-eae0e736caef" />

| 타입 | 플래그 | 설명 |
|--|--|--|
| CONSTANT_Utf8_info | 1 | utf8 인코딩 문자열 |
| CONSTANT_Integer_info | 3 | int 타입 리터럴 |
| CONSTANT_Float_info | 4 | float 타입 리터럴 |
| CONSTANT_Long_info | 5 | long 타입 리터럴 |
| CONSTANT_Double_info | 6 | double 타입 리터럴 |
| CONSTANT_Class_info | 7 | 클래스나 인터페이스를 가리키는 심벌 참조 |
| CONSTANT_String_info | 8 | 문자열 타입 리터럴 |
| CONSTANT_Fieldref_info | 9 | 필드를 가리키는 심벌 |
| CONSTANT_Methodref_info | 10(0A) | 같은 클래스의 메서드를 가리키는 심벌 |
| CONSTANT_InterfaceMethodref_info | 11(0B) | 같은 인터페이스의 메서드를 가리키는 심벌 |
| CONSTANT_NameAndType_info | 12(0C) | 필드나 메서드를 가리키는 심벌 |
| CONSTANT_MethodHandle_info | 15(0F) | 메서드 핸들 |
| CONSTANT_MethodType_info | 16(10) | 메서드 타입 |
| CONSTANT_Dynamic_info | 17(11) | 동적으로 계산된 상수 |
| CONSTANT_InvokeDynamic_info | 18(12) | 동적으로 계산된 메서드 호출 사이트 |
| CONSTANT_Module_info | 19(13) | 모듈 |
| CONSTANT_Package_info | 20(14) | 모듈에서 외부로 공개하거나 익스포트한 패키지 |

<br>

직접 분석하기 보다는 `javap` 사용  

```
$ javap -verbose TestClass
...
  Compiled from "TestClass.java"
public class org.fenixsoft.clazz.TestClass
  minor version: 0
  major version: 61
  flags: (0x0021) ACC_PUBLIC, ACC_SUPER
  this_class: #8
  super_class: #2
  interfaces: 0, fields: 1, methods: 2, attributes: 1
Constant pool:
  #1 = Methodref          #2.#3
  #2 = Class              #4
  #3 = NameAndType        #5:#6
  #4 = Utf8               java/lang/Object
  #5 = Utf8               <init>
  #6 = Utf8               ()V
  #7 = Fieldref           #8.#9
  #8 = Class              #10
  #9 = NameAngType        #11:#12
 #10 = Utf8               org/fenixsoft/clazz/TestClass
 #11 = Utf8               m
 #12 = Utf8               I
 #13 = Utf8               Code
 #14 = Utf8               LineNumberTable
 #15 = Utf8               inc
 #16 = Utf8               ()I
 #17 = Utf8               SourceFile
 #18 = Utf8               TestClass.java
```

<br>

### 접근 플래그
상수 풀 다음의 `2byte`는 현재 클래스의 접근 정보를 식별하는 접근 플래그(`access_flags`)  
플래그 비트를 최대 16개까지 사용 가능(현재는 9개만 정의)  

<img width="550" height="100" alt="access_flags" src="https://github.com/user-attachments/assets/0d163dde-a7d0-4731-b06f-ee1d9700d32c" />

| 플래그 | 값 | 의미 |
|--|--|--|
| ACC_PUBLIC | 0x0001 | public 타입 여부 |
| ACC_FINAL | 0x0010 | final 선언 여부 |
| ACC_SUPER | 0x0020 | invokespecial 바이트코드 새로운 의미 허용 여부 |
| ACC_INTERFACE | 0x0200 | 인터페이스 여부 |
| ACC_ABSTRACT | 0x0400 | 추상 클래스 및 인터페이스인 경우 true |
| ACC_SYNTHETIC | 0x1000 | 컴파일러 자동 생성 여부 |
| ACC_ANNOTATION | 0x2000 | 어노테이션 여부 |
| ACC_ENUM | 0x4000 | 열거 타입 여부 |
| ACC_MODULE | 0x8000 | 모듈 여부 |

<br>

### 인덱스
이어서 클래스 인덱스, 부모 클래스 인덱스, 인터페이스 인덱스 컬렉션  
클래스 파일의 상속 관계를 규정, 앞의 두 인덱스는 u2, 마지막 인터페이스 인덱스는 u2 타입 데이터 묶음  
`java.lang.Object`를 제외한 모든 자바 클래스의 부모 클래스 인덱스 값은 `0`이 아님  

<img width="550" height="150" alt="index" src="https://github.com/user-attachments/assets/87cf9343-7b7a-4e3c-866d-4b86b54bd45b" />

<br>
<br>

### 필드 테이블
인터페이스나 클래스 안에 선언된 변수들을 설명  

```c
field_info {
  u2              access_flags;
  u2              name_index;
  u2              descriptor_index;
  u2              attributes_count;
  attribute_info  attributes[attributes_count];
}
```

<br>

필드의 `access_flags` 항목은 클래스의 접근 플래그와 매우 비슷  

| 플래그 | 값 | 의미 |
|--|--|--|
| ACC_PUBLIC | 0x0001 | public 필드 여부 |
| ACC_PRIVATE | 0x0002 | private 필드 여부 |
| ACC_PROTECTED | 0x0004 | protected 필드 여부 |
| ACC_STATIC | 0x0008 | static 필드 여부 |
| ACC_FINAL | 0x0010 | final 필드 여부 |
| ACC_VOLATILE | 0x0040 | volatile 필드 여부 |
| ACC_TRANSIENT | 0x0080 | transient 필드 여부 |
| ACC_SYNTHETIC | 0x1000 | 컴파일러 자동 생성 여부 |
| ACC_ENUM | 0x4000 | 열거 필드 여부 |

<br>

<img width="550" height="150" alt="field_table" src="https://github.com/user-attachments/assets/00a0dccf-1b4e-4d76-8077-893877c45002" />

단순 이름은 메서드나 필드의 이름을 참조할때 이용, 타입과 매개변수 정보가 생략된 형태  
배열 타입은 차원 수만큼 `[`를 붙임  
- void inc() -> `()V`
- java.lang.String.toString() -> `()Ljava/lang/String`
- int indexOf(char[] s, int so, int sc, char[] t, int to, int tc, int fi) -> `([CII[CIII)I`

<br>

### 메서드 테이블
필드 테이블과 매우 유사  
메서드 정의는 필드 정의와 똑같이 저장되지만 실제 코드는 메서드 속성 테이블 컬렉션의 `Code` 속성에 따로 저장  

<img width="550" height="150" alt="method_table" src="https://github.com/user-attachments/assets/4ab779e7-6cb9-4e20-b435-c562e0948d03" />

<br>
<br>

### 속성 테이블
속성 테이블은 클래스 파일, 필드 테이블, 메서드 테이블, Code 속성, 레코드 구성 요소 등 특정 시나리오에 특정한 정보를 설명  
자바 가상머신은 자신이 인식하지 못하는 속성은 그저 무시  

```c
attribute_info {
  u2 attribute_name_index;
  u4 attribute_length;
  u1 info[attribute_length];
}
```

<br>

<img width="550" height="150" alt="code_attribute" src="https://github.com/user-attachments/assets/59305575-644c-41c1-aae4-690b9fa2e74a" />

```c
Code_attribute {
  u2 attribute_name_index;
  u4 attribute_length;
  u2 max_stack;
  u2 max_locals;
  u4 code_length;
  u1 code[code_length];
  u2 exception_table_length;
  {
    u2 start_pc;
    u2 end_pc;
    u2 handler_pc;
    u2 catch_type;
  } exception_table[exception_table_length];
  u2 attributes_count;
  attribute_info attributes[attributes_count];
}
```

<br>

<img width="550" height="150" alt="code_analystic" src="https://github.com/user-attachments/assets/81b77c7e-3853-4aad-b56b-4d4ccf1efb59" />

```
$ javap -verbose TestClass
...
{
  public org.fenixsoft.clazz.TestClass();
    descriptor: ()V
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
        0: aload_0
        1: invokespecial #1  // Method java/lang/Object."<init>":()V
        4: return
      LineNumberTable:
        line 3: 0

  public int inc();
    descriptor: ()I
    flags: (0x0001) ACC_PUBLIC
    Code:
      stack=2, locals=1, args_size=1
        0: aload_0
        1: getfield
        4: iconst_1
        5: iadd
        6: ireturn
      LineNumberTable:
        line 7: 0
}
```

<br>
