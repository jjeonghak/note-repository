# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## 숫자
숫자를 저장하는 타입은 값의 정확도에 따라 참값(`Exact value`)과 근삿값 타입으로 구분  
근삿값은 저장할 때와 조회할 때의 값이 정확히 일치하지 않음, 부동 소수점 타입은 잘 사용하지 않음   
- 참값: 소수점 이하 값의 유무와 관계없이 정확히 그 값을 그대로 유지하는 것 의미(`INT`, `DECIMAL`)
- 근삿값: 흔히 부동 소수점이라고 불리는 값(`FLOAT`, `DOUBLE`)

<br>

또한 값이 저장되는 포맷에 따라 십진 표기법과 이진 표기법으로 구분  
- 이진 표기법: 흔히 프로그래밍 언어에서 사용하는 정수나 실수 타입 의미
- 십진 표기법: 숫자 값의 각 자릿값을 표현하기 위해 표기하는 방법(`DECiMAL`)

<br>

### 정수
| 데이터 타입 | 저장공간<br>(bytes) | 최솟값<br>(signed) | 최솟값<br>(unsigned) | 최댓값<br>(signed) | 최댓값<br>(unsigned) |
|--|--|--|--|--|--|
| TINYINT | 1 | -128 | 0 | 127 | 255 |
| SMALLINT | 2 | -32768 | 0 | 32767 | 65535 |
| MEDIUMINT | 3 | -8388608 | 0 | 8388607 | 16777215 |
| INT | 4 | -2147483648 | 0 | 2147482647 | 4294967295 |
| BIGINT | 8 | -263 | 0 | 263-1 | 264-1 |

<br>

### 부동 소수점
부동 소수점을 저장하기 위해 `FLOAT`, `DOUBLE` 타입 사용 가능  
부동은 소수점의 위치가 고정적이지 않다는 의미, 근사값 저장 방식이라 동등 비교 사용 불가  
부동 소수점 값을 저장해야 한다면 유효 소수점 자릿수만큼 10을 곱해서 정수 타입의 칼럼에 저장하는 방법 가능  

```
mysql> CREATE TABLE tb_float (fd1 FLOAT);
mysql> INSERT INTO tb_float VALUES (0.1);
mysql> SELECT * FROM tb_float WHERE fd1 = 0.1;
Empty set (0.00 sec)

mysql> CREATE TABLE tb_location (
  latitude INT UNSIGNED,
  longitude INT UNSIGNED,
  ...
);
mysql> INSERT INTO tb_location (latitude, longitude, ...) VALUES (37.1422 * 10000, 131.5208 * 10000, ...);
```

<br>

### DECIMAL
부동 소수점에서 유효 범위 이외의 값은 가변적이므로 정확한 값 보장 불가  
금액이나 대출 이자 등과 같이 고정된 소수점까지 정확하게 관리햐야하는 경우 사용  
두 자릿수를 저장하는데 1byte 필요  
소수가 아닌 정수값을 관리하기 위해 사용하는 것은 성능 및 공간 사용면에서 좋지 않음  

<br>

### 정수 타입의 칼럼을 생성할 때의 주의사항
부동 소수점이나 `DECIMAL` 타입을 사용하는 경우 타입의 이름 뒤에 괄호로 정밀도를 표시하는 것이 일반적  
다른 부동 소수점 타입과 다르게 `DECIMAL` 타입은 가변 타입이라 저장 가능한 자릿수를 결정함과 동시에 저장 공간 크기 제한  
8.0 버전부터 정수 타입에 화면 표시 자릿수를 사용하는 기능은 제거  

```
mysql> CREATE TABLE not_support_int (age BIGINT(10));
Query OK, 0 rows affected, 1 warning (0.02 sec)

mysql> SHOW WARNINGS;
+---------+------+------------------------------------------------------------------------------+
| Level   | Code | Message                                                                      |
+---------+------+------------------------------------------------------------------------------+
| Warning | 1681 | Integer display width is deprecated and will be removed in a future release. |
+---------+------+------------------------------------------------------------------------------+
```

<br>

### 자동 증가(AUTO_INCREMENT) 옵션 사용
숫자 타입의 칼럼에 자동 증가 옵션을 사용한 인조키 생성 가능, 테이블 당 하나만 사용 가능  
`auto_increment_increment`, `auto_increment_offset` 시스템 변수값으로 자동 증가값이 얼마씩 변경될지 설정 가능  
자동 증가 옵션을 사용한 칼럼은 반드시 그 테이블에서 프라이머리 키나 유니크 키의 일부로 정의  
- MyISAM 스토리지 엔진을 사용하는 테이블은 자동 증가 옵션이 사용된 칼럼이 프라이머리 키나 유니크 키의 아무 위치나 사용 가능
- InnoDB 스토리지 엔진을 사용하는 테이블은 자동 증가 옵션이 사용된 칼럼으로 시작되는 인덱스 생성 필수

```
-- // AUTO_INCREMENT 칼럼을 프라이머리 키 뒤쪽에 배치해 테이블 생성 시 오류 발생
mysql> CREATE TABLE tb_autoinc_innodb (
  fd_pk1 INT NOT NULL DEFAULT '0',
  fd_pk2 INT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (fd_pk1, fd_pk2)
) ENGINE=INNODB;
ERROR 1075 (42000): Incorrect table definition; there can be only one auto column and it must
be defined as a key

-- // AUTO_INCREMENT 칼럼을 프라이머리 키 뒤쪽에 배치했지만 유니크 키에서 제일 선두이기 때문에 정상 생성
mysql> CREATE TABLE tb_autoinc_innodb (
  fd_pk1 INT NOT NULL DEFAULT '0',
  fd_pk2 INT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (fd_pk1, fd_pk2),
  UNIQUE KEY ux_fdpk2 (fd_pk2)
) ENGINE=INNODB;
Query OK, 0 rows affected (0.01 sec)
```

<br>
