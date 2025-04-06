# 파티션
파티션 기능은 테이블을 논리적으로 하나의 테이블이지만 물리적으로 분리해서 관리  
주로 대용량의 테이블을 물리적으로 여러 개의 소규모 테이블로 분산하는 목적  

<br>

## 레인지 파티션
파티션 키의 연속된 범위로 파티션을 정의하는 방법, 가장 일반적으로 사용되는 파티션 방법  
`MAXVALUE` 키워드를 이용해서 명시되지 않은 범위의 키 값이 담긴 레코드를 저장하는 파티션 정의 가능  

<br>

### 레인지 파티션의 용도
아래와 같은 경우 레인지 파티션 사용  
- 날짜를 기반으로 데이터가 누적되고 연도나 월, 또는 일 단위로 분석하고 삭제하는 경우
- 범위 기반으로 데이터를 여러 파티션에 균등하게 분리하는 경우
- 파티션 키 위주로 검색이 자주 실행되는 경우

<br>

### 레인지 파티션 테이블 생성
```sql
CREATE TABLE employees (
  id INT NOT NULL,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  hired DATE NOT NULL DEFAULT '1970-01-01',
  ...
) PARTITION BY RANGE(YEAR(hired)) (
  PARTITION p0 VALUES LESS THAN (1991),
  PARTITION p1 VALUES LESS THAN (1996),
  PARTITION p2 VALUES LESS THAN (2001),
  PARTITION p3 VALUES LESS THAN MAXVALUE
);
```

<br>

### 단순 파티션의 추가
레인지 파티션을 사용하는 테이블에서는 가장 마지막 파티션만 새로 추가 가능, 중간 파티션 추가 불가  

```sql
ALTER TABLE employees ADD PARTITION (PARTITION p4 VALUES LESS THAN (2011));
```

만약 `LESS THAN MAXVALUE` 파티션이 존재하는 경우 에러 발생  
일반적으로 `LESS THAN MAXVALUE` 파티션은 사용하지 않고, 미래에 사용될 파티션을 미리 만들어 두는 형태로 사용  

```
ERROR 1481 (HY000): MAXVALUE can only be ussed in last partition definition
```

<br>

또한 이미 저장되어 있는 레코드 변경 필수  
변경되기 전의 파티션 레코드를 모두 새로운 두개의 파티션으로 복사하는 작업  

```sql
ALTER TABLE employees ALGORITHM=INPLACE, LOCK=SHARED,
REORGANIZE PARTITION p3 INTO(
  PARTITION p3 VALUES LESS THAN (2011),
  PARTITION p4 VALUES LESS THAN MAXVALUE
);
```

<br>

### 파티션 삭제
레인지 파티션을 삭제하는 작업은 빠르게 처리되므로 날짜 단위 갱신에 자주 사용  
레인지 파티션을 사용하는 테이블에서는 가장 오래된 파티션 순서로만 삭제 가능  

```sql
ALTER TABLE employees DROP PARTITION p0;
```

<br>

### 기존 파티션의 분리
기존 파티션의 레코드가 많다면 온라인 DDL로 실행 가능  

```sql
ALTER TABLE employees ALGORITHM=INPLACE, LOCK=SHARED,
REORGANIZE PARTITION p3 INTO (
  PARTITION p3 VALUES LESS THAN (2011),
  PARTITION p4 VALUES LESS THAN MAXVALUE
);
```

<br>

### 기존 파티션의 병합
```sql
ALTER TABLE employees ALGORITHM=INPLACE, LCOK=SHARED,
REORGANIZE PARTITION p2, p3 INTO (
  PARTITION p23 VALUES LESS THAN (2011)
);
```

<br>

## 리스트 파티션
레인지 파티션과 많은 부분에서 흡사하게 동작  
리스트 파티션은 파티션 키 값 하나하나를 리스트로 나열  
`MAXVALUE` 파티션 정의 불가  

<br>

### 리스트 파티션의 용도
아래와 같은 경우 리스트 파티션 사용  
- 파티션 키 값이 코드 값이나 카테고리와 같이 고정적인 경우
- 키 값이 연속되지 않고 정렬 순서와 관계없이 파티션을 하는 경우
- 파티션 키 값을 기준으로 레코드의 건수가 균일하고 검색 조건에 파티션 키가 자주 사용되는 경우

<br>

### 리스트 파티션 테이블 생성
```sql
CREATE TABLE product(
  id INT NOT NULL,
  name VARCHAR(30),
  category_id INT NOT NULL,
  ...
) PARTITION BY LIST(category_id) (
  PARTITION p_appliance VALUES IN (3),
  PARTITION p_computer VALUES IN (1, 9),
  PARTITION p_sports VALUES IN (2, 6, 7),
  PARTITION p_etc VALUES IN (4, 5, 8, NULL)
);
```

<br>

### 리스트 파티션의 분리와 병합
파티션을 정의하는 부분에서 `VALUES LESS THAN` 구문이 아닌 `VALUES IN`을 사용하는 것 외에는 레인지 파티션과 동일  

<br>

### 리스트 파티션 주의사항
다른 파티션에 비해 아래와 같은 제약 사항 존재  
- 명시되지 않은 나머지 값을 저장하는 `MAXVALUE` 정의 불가
- 레인지 파티션과 달리 `NULL` 저장 파티션 생성 가능

<br>

## 해시 파티션
MySQL에서 정의한 해시 함수에 의해 레코드가 저장될 파티션 결정  
정의된 해시 함수는 복잡한 알고리즘이 아닌 파티션 갯수로 나눈 나머지로 결정하는 방식  
파티션 키는 항상 정수 타입 또는 정수 반환 표현식만 가능  
파티션 추가 또는 삭제 작업에는 테이블 전체적으로 레코드 재분배 필수  

<br>

### 해시 파티션의 용도
아래와 같은 경우 해시 파티션 사용  
- 레인지 파티션이나 리스트 파티션으로 데이터를 균등하게 나누기 어려운 경우
- 테이블의 모든 레코드가 비슷한 사용 빈도를 보이지만 테이블이 너무 커서 파티션을 적용하는 경우

대표적인 용도로 회원 테이블과 같이 가입 일자에 따라 사용 빈도가 상이하지 않은 경우  
지역, 취미 같은 정보 또한 사용 빈도에 미치는 영향이 적은 경우  

<br>

### 해시 파티션 테이블 생성
```sql
## 파티션 개수만 지정하는 경우
CREATE TABLE employees (
  id INT NOT NULL,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  hired DATE NOT NULL DEFAULT '1970-01-01',
  ...
) PARTITION BY HASH(id) PARTITIONS 4;

## 파티션 이름을 별도로 지정하는 경우
CREATE TABLE employees (
  id INT NOT NULL,
  first_name VARCHAR(30),
  last_name VARCHAR(30),
  hired DATE NOT NULL DEFAULT '1970-01-01',
  ...
) PARTITION BY HASH(id) PARTITIONS 4 (
  PARTITION p0 ENGINE=INNODB,
  PARTITION p1 ENGINE=INNODB,
  PARTITION p2 ENGINE=INNODB,
  PARTITION p3 ENGINE=INNODB
);
```

<br>

### 해시 파티션의 분리와 병합
해시 파티션의 분리와 병합은 다른 파티션과 달리 대상 테이블의 모든 파티션에 저장된 레코드 재분배 필수  

<br>

### 해시 파티션 추가
해시 파티션은 테이블에 존재하는 파티션의 개수에 의해 파티션 알고리즘이 변함  

<img width="450" alt="hashpartition" src="https://github.com/user-attachments/assets/6c4045e0-9988-4bdd-b98b-b47152c35250" />

```sql
## 하나의 파티션만 추가 및 이름 부여하는 경우
ALTER TABLE employees ALGORITHM=INPLACE, LOCK=SHARED,
ADD PARTITION(PARTITION p5 ENGINE=INNODB);

## 여러 파티션 추가 및 이름 부여하지 않는 경우
ALTER TABLE employees ALGORITHM=INPLACE, LOCK=SHARED,
ADD PARTITION PARTITIONS 6;
```

<br>

### 해시 파티션 삭제
특정 파티션만 삭제하려는 경우 에러 발생  
해시 파티션이나 키 파티션을 사용한 테이블에서 파티션 단위로 데이터를 삭제하는 것 금지

```
mysql> ALTER TABLE employees DROP PARTITION p0;
Error Code : 1512
DROP PARTITON can only be used on RANGE/LIST partitions
```

<br>

### 해시 파티션 분할
해시 파티션이나 키 파티션에서 특정 파티션을 분할하는 것은 불가능  
테이블 전체적으로 파티션 개수를 늘리는 것만 가능  

<br>

### 해시 파티션 병합
파티션 통합은 불가능하지만 단지 파티션 개수를 줄이는 것은 가능  

<img width="450" alt="hashpartitioncoalesce" src="https://github.com/user-attachments/assets/4b16dd5a-7eb5-4739-a200-51dcc585ddec" />

```sql
ALTER TABLE employees ALGORITHM=INPLACE, LOCK=SHARED
COALESCE PARTITION 1;
```

<br>

### 해시 파티션 주의사항
- 특정 파티션만 삭제하는 것 불가능
- 새로운 파티션을 추가하는 작업은 단순히 파티션만 추가되는 것이 아닌 전체 데이터 재배치
- 다른 파티션과 다른 방식으로 관리되기 때문에 용도에 적합한지 확인 필요

<br>

## 키 파티션
해시 파티션과 사용법과 특성이 거의 유사  
키 파티션은 해시 값 계산도 MySQL 서버가 수행  
정수 타입 또는 정수 반환 표현식뿐만 아니라 대부분의 데이터 타입 가능  

<br>

### 키 파티션의 생성
```sql
## 프라이머리 키가 있는 경우 자동으로 프라이머리 키가 파티션 키로 사용
CREATE TABLE k1 (
  id INT NOT NULL,
  name VARCHAR(20),
  PRIMARY KEY (id)
) PARTITION BY KEY()
PARTITIONS 2;

## 프라이머리 키가 없는 경우 유니크 키가 파티션 키로 사용
CREATE TABLE k1 (
  id INT NOT NULL,
  name VARCHAR(20),
  UNIQUE KEY (id)
) PARTITION BY KEY()
PARTITIONS 2;

## 프라이머리 키나 유니크 키의 칼럼 일부를 파티션 키로 명시적 설정
CREATE TABLE dept_emp (
  emp_no INT NOT NULL,
  dept_no CHAR(4) NOT NULL,
  ...
  PRIMARY KEY (dept_no, emp_no)
) PARTITION BY KEY(dept_no)
PARTITIONS 2;
```

<br>

### 키 파티션의 주의사항 및 특이사항
- 키 파티션은 MySQL 서버가 내부적으로 MD5() 함수를 이용해 파티션하기 때문에 키가 정수 타입일 필요 없음
- 프라이머리 키나 유니크 키를 구성하는 칼럼 중 일부만으로 파티션 가능
- 유니크 키를 파티션 키로 사용하는 경우 해당 유니크 키는 NOT NULL
- 해시 파티션에 비해 파티션 간의 레코드를 더 균등하게 분할 가능

<br>

## 리니어 해시 파티션/리니어 키 파티션
파티션 개수 변경에 따라 테이블 전체 데이터 재분배 단점을 해결하기 위해 고안  
각 레코드 분배를 위해 `Power-of-two`(2의 승수) 알고리즘 사용  
파티션 개수 변경시 다른 파티션에 미치는 영향 최소화  

<br>

### 리니어 해시 파티션/리니어 키 파티션의 추가 및 통합
파티션 개수 변경에 대해 특정 파티션의 데이터만 이동  
나머지 파티션의 데이터는 재분재 대상이 되지 않음  

<br>

### 리니어 해시 파티션/리니어 키 파티션의 추가

<img width="450" alt="linearhashpartitionadd" src="https://github.com/user-attachments/assets/95a31991-f142-4a2e-8eb8-9c6c3ce9f05a" />

다른 파티션 데이터는 레코드 재분배 작업과 관련이 없기 때문에 빠르게 처리 가능  

<br>

### 리니어 해시 파티션/리니어 키 파티션의 통합

<img width="450" alt="linearhashpartitionmerge" src="https://github.com/user-attachments/assets/7dbb6e93-2bc3-4334-a164-9334d7783394" />

새로운 파티션을 추가할 때와 같이 일부 파티션에 대해서만 레코드 통합  

<br>

### 리니어 해시 파티션/리니어 키 파티션과 관련된 주의사항
일반 해시 파티션보다 각 파티션이 가지는 레코드 건수가 덜 균등  
하지만 파티션 추가/삭제할 요건이 많다면 사용  

<br>
