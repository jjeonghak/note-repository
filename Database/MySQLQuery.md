# 쿼리 작성 및 최적화
데이터베이스나 테이블 구조를 변경하기 위한 문장을 DDL(`Data Definition Language`)  
테이블의 데이터를 조작하기 위한 문장을 DML(`Data Manipulation Language`)  
애플리케이션은 데이터베이스에 SQL 쿼리만 전달하며, 해당 쿼리를 어떻게 처리할지는 MySQL 서버가 결정  

<br>

## 쿼리 작성과 연관된 시스템 변수
대소문자 구분, 문자열 표기 방법 등 SQL 작성 규칙은 시스템 설정에 따라 상이  

<br>

### SQL 모드
`sql_mode` 시스템 설정을 통해 여러 설정 가능  
SQL 문장 작성 규칙뿐만 아니라 내부적으로 자동 실행되는 데이터 타입 변환 및 기본값 제어 등 여러 옵션 존재  
이미 동작하고 있는 서버에는 해당 값을 변경하지 않는 것 권장  

- `STRICT_ALL_TABLES` & `STRICT_TRANS_TABLES`  
데이터를 변경하는 경우 칼럼의 타입과 저장되는 값의 타입이 다를 때 자동으로 타입 변경  
만약 불가능하다면 해당 문장을 계속 실행할지 에러를 발생시킬지 결정  
트랜잭션 여부에 상관없이, 또는 여부에 따라 엄격한 모드 적용  
사용자가 원하지 않는 방향으로 자동 타입 변환 발생 가능성 존재하기 때문에 시작전에 활성화 권장  

- `ANSI_QUOTES`  
기본적으로 MySQL에서는 문자열 값 표현이 홑따옴표, 쌍따옴표 둘다 사용 가능  
홉따옴표만 문자열 값 표기로 사용할 수 있고, 쌍따옴표는 칼럼명이나 테이블명과 같은 식별자 표기로 설정  

- `ONLY_FULL_GROUP_BY`  
GROUP BY 절에 포함되지 않은 칼럼의 SELECT 집합 함수 사용 불가  
5.7 버전까지는 기본값이 비활성화지만 8.0 버전부터 활성화  

- `PIPES_AS_CONCAT`  
`||`는 기본적으로 OR 연산자이지만, 오라클처럼 문자열 연결 연산자(`CONCAT`)으로도 사용 가능  

- `PAD_CHAR_TO_FULL_LENGTH`  
기본적으로 CHAR 타입이라도 VARCHAR 타입과 같이 유효 문자열 뒤의 공백 문자는 제거되어 반환  
CHAR 타입의 칼럼값을 가져올 때 뒤쪽의 공백이 제거되지 않고 반환돼야 하는 경우 활성화  

- `NO_BACKSLASH_ESCAPES`  
기본적으로 역슬래시 문자를 이스케이프 문자로 사용 가능  
역슬래시 문자를 이스케이프 용도로 사용하지 못하도록 설정  
다른 문자와 역슬래시 문자를 동일하게 취급  

- `IGNORE_SPACE`  
기본적으로 스토어드 프로시저나 함수명과 괄호 사이에 있는 공백도 스토어드 프로시저나 함수의 이름으로 간주  
프로시저나 함수명과 괄호 사이의 공백을 무시하도록 설정  
해당 옵션은 MySQL 서버의 내장 함수에만 적용되며, 해당 옵션 활성화시 내장 함수는 모두 예약어로 간주  

- `REAL_AS_FLOAT`  
기본적으로 부동 소수점 타입은 FLOAT, DOUBLE 두 타입 지원, REAL 타입은 DOUBLE 타입의 동의어로 사용  
REAL 타입을 FLOAT 타입의 동의어로 설정  

- `NO_ZERO_IN_DATE` & `NO_ZERO_DATE`  
해당 옵션 활성화시 DATE 또는 DATETIME 타입의 칼럼에 0000-00-00 같은 잘못된 날짜 저장 불가  
실제로 존재하지 않는 날짜를 저장하지 못하게 설정  

- `ANSI`  
최대한 SQL 표준에 맞게 동작하도록 옵션 설정  
`REAL_AS_FLOAT`, `PIPES_AS_CONCAT`, `ANSI_QUOTES`, `IGNORE_SPACE`, `ONLY_FULL_GROUP_BY` 모드의 조합  

- `TRADITIONAL`  
보다 더 엄격한 방법으로 SQL 작동 제어  
`STRICT_*_TABLES`, `NO_ZERO_*`, `ERROR_FOR_DIVISION_BY_ZERO`, `NO_ENGINE_SUBSTITUTION` 모드의 조합  

<br>

### 영문 대소문자 구분
MySQL 서버는 설치된 운영체제에 따라 테이블명 대소문자를 구분  
파일시스템에 매핑되기 때문에 윈도우는 대소문자 구분하지 않고, 유닉스는 대소문자 구분  
운영체제와 관계없이 대소문자 구분의 영향을 받지 않기위해 `lower_case_table_names` 시스템 변수 설정 가능  
기본값은 0으로 대소문자를 구분, 2로 설정한 경우 저장할때는 대소문자를 구분하지만 쿼리에서는 대소문자 구분하지 않음  

<br>

### MySQL 예약어
예약어로 데이터베이스, 테이블, 칼럼을 생성하려면 역따옴표(\`) 필수  
테이블을 생성할 떄는 항상 역따옴표가 아닌 홑따옴표를 사용해서 해당 이름이 예약어인지 확인 권장  

<br>

## 매뉴얼의 SQL 문법 표기를 읽는 방법

<img width="350" alt="mysqlmanual" src="https://github.com/user-attachments/assets/aec16691-79e3-410f-abf3-a42c8abbbd33" />

대문자로 표현된 단어는 모두 키워드를 의미  
이탤릭체로 표현한 단어는 사용자가 선택해서 작성하는 토큰을 의미  
대괄호는 해당 키워드나 표현식 자체가 선택 사항임을 의미  
파이프는 앞과 뒤의 키워드나 표현식 중에서 단 하나만 선택해서 사용 가능함을 의미  
중괄호는 괄호 내의 아이템 중에서 반드시 하나를 사용해야 하는 경우를 의미  

<br>

## MySQL 연산자와 내장 함수
MySQL에서만 사용되는 연산자나 표기법이 많이 존재  
가능하면 ANSI 표준 형태의 연산자를 사용하길 권장  
일반적으로 각 DBMS 내장 함수는 거의 같은 기능을 제공하지만 이름이 호환되는 것은 거의 없음  

<br>

## 리터럴 표기법 문자열

### 문자열
SQL 표준에서는 문자열을 항상 홑따옴표(') 사용해서 표시  
문자열 값에 홑따옴표가 포함된 경우 두번 연속 입력해서 표기  
이러한 문제를 MySQL에서는 쌍따롬표와 홑따옴표를 혼합해서 사용  

```sql
SELECT * FROM departments WHERE dept_no = 'd''001';
SELECT * FROM departments WHERE dept_no = 'd"001';
SELECT * FROM departments WHERE dept_no = "d'001";
SELECT * FROM departments WHERE dept_no = "d""001";
```

<br>

사용되는 식별자가 키워드와 충돌할 경우 오라클이나 PostgreSQL에서는 쌍따옴표나 대괄호로 감싸서 충돌 해결  
MySQL에서는 역따롬표(\`)로 감싸서 사용  
해당 방식은 `sql_mode` 시스템 변수의 `ANSI_QUOTES`에 영향  

```sql
CREATE TABLE tab_test (`table` VARCHAR(20) NOT NULL, ...);
SELECT `column` FROM tab_test;
```

<br>

### 숫자
상수로 사용하는 경우 따옴표 없이 숫자 값을 입력해서 사용  
문자열 형태로 따롬표를 사용하더라도 비교 대상이 숫자 타입의 칼럼이면 숫자 값으로 자동 변환  
문자열과 숫자 타입 비교는 숫자 타입이 우선순위가 높아 문자열을 숫자로 변환  
만약 칼럼의 타입이 문자열인 경우 비교를 위해 모든 칼럼값의 변환이 필요  

```sql
## 상수값 하나만 변환
SELECT * FROM tab_test WHERE number_column = '10001';

## 칼럼의 모든 문자열 변환, 인덱스 사용 불가
SELECT * FROM tab_test WHERE string_column = 10001;
```

<br>

### 날짜
다른 DBMS의 경우 날짜 타입 비교/삽입을 하려면 문자열을 DATE 타입으로 변환하는 코드 필수  
MySQL에서는 정해진 형태의 날짜 포맷으로 표기한 경우 자동으로 타입 변환  

```sql
SELECT * FROM dept_emp WHERE from_date = '2011-04-29';
SELECT * FROM dept_emp WHERE from_date = STR_TO_DATE(`2011-04-29`, '%Y-%m-%d');
```

<br>

### 불리언
BOOL, BOOLEAN 타입은 사실 TINYINT 타입에 대한 동의어  
TRUE, FALSE 값으로 비교 가능하지만 사실 정수 비교  
MySQL은 C/C++ 언어와 같이 불리언 값을 정수로 매핑해서 사용하지만, 오직 1과 0만 사용   

```
mysql> SELECT * FROM tb_boolean WHERE bool_value IN (FALSE, TRUE);
+------------+
| bool_value |
+------------+
|          0 |
|          1 |
+------------+
```

<br>
