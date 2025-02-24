# 스키마 조작(DDL)
DBMS 서버의 모든 오브젝트를 생성하거나 변경하는 쿼리는 DDL(`Data Definition Language`)  
스토어드 프로시저나 함수, DB 또는 테이블 등을 생성하거나 변경하는 대부분의 명령이 해당  
스키마를 변경하는 작업은 서버에 많은 부하를 발생  

<br>

## 온라인 DDL
5.5 버전까지 테이블의 구조를 변경하는 동안 다른 커넥션이 DML 실행 불가  
8.0 버전부터 내장된 온라인 DDL 기능으로 처리 가능  

<br>

### 온라인 DDL 알고리즘
스키마 변경하는 작업 중에 다른 커넥션이 해당 테이블의 데이터를 변경하거나 조회하는 작업을 가능하게 지원  
`old_alter_table` 시스템 변수를 이용해 온라인 DDL 사용 여부 결정, 기본값 OFF로 온라인 DDL 사용  

<br>

ALTER TABLE 명령이 실행되는 경우 아래 순서로 스키마 변경에 적합한 알고리즘 탐색  
1. `ALGORITHM=INSTANT`로 스키마 변경이 가능한지 확인 후, 가능하면 선택
2. `ALGORITHM=INPLACE`로 스키마 변경이 가능한지 확인 후, 가능하면 선택
3. `ALGORITHM=COPY` 알고리즘 선택

<br>

스키마 변경 알고리즘의 우선순위가 낮을수록 스키마 변경을 위해 더 큰 잠금과 작업 필요  
- `INSTANT`  
테이블의 데이터는 전혀 변경하지 않고 메타데이터만 변경하고 작업 완료  
테이블의 레코드 건수와는 무관하게 매우 짧은 작업 시간  

- `INPLACE`  
임시 테이블로 데이터를 복사하지 않고 스키마 변경 실행  
경우에 따라 내부적으로 테이블 리빌드 필요, 대표적으로 프라이머리 키를 추가하는 작업  
스키마 변경 중에도 테이블 읽기, 쓰기 모두 가능  

- `COPY`  
임시 테이블을 생성하고 테이블의 레코드를 모두 임시 테이블로 복사 후 임시 테이블 이름 변경해서 스키마 변경  
테이블 읽기만 가능하고 DML 실행 불가  

<br>

온라인 DDL 명령은 `ALGORITHM`과 `LOCK` 옵션을 이용해서 어떤 모드로 스키마 변경을 실행할지 결정  

```sql
ALTER TABLE salaries CHANGE to_date end_date DATE NOT NULL,
  ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

`LOCK` 옵션은 `INSTANT` 알고리즘을 제외하고 사용 가능  
- `NONE`: 아무런 잠금 없음
- `SHARED`: 읽기 잠금, 스키마 변경 중 읽기는 가능하지만 쓰기는 불가능
- `EXCLUSIVE`: 쓰기 잠금, 스키마 변경 중 읽기, 쓰기 불가능

<br>

### 온라인 처리 가능한 스키마 변경

- 인덱스 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 프라이머리 키 추가 | X | O | O | O | X |
| 프라이머리 키 삭제 | X | X | O | X | X |
| 프라이머리 키 삭제 + 추가 | X | O | O | O | X |
| 세컨더리 인덱스 생성 | X | O | X | O | X | 
| 세컨더리 인덱스 삭제 | X | O | X | O | O |
| 세컨더리 인덱스 이름 변경 | X | O | X | O | O |
| 전문 검색 인덱스 생성 | X | O | X | X | X |
| 공간 검색 인덱스 생성 | X | O | X | X | X |
| 인덱스 타입 변경 | O | O | X | O | O |

<br>

- 칼럼 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 칼럼 추가 | O | O | X | O | X |
| 칼럼 삭제 | X | O | O | O | X |
| 칼럼 이름 변경 | X | O | X | O | O |
| 칼럼 순서 변경 | X | O | O | O | X |
| 칼럼 기본값 설정 | O | O | X | O | O |
| 칼럼 기본값 제거 | O | O | X | O | O |
| 칼럼 데이터 타입 변경 | X | X | O | X | X |
| VARHCHAR 타입 길이 확장 | X | O | X | O | O | 
| 자동 증가값 변경 | X | O | X | O | X | 
| 칼럼 NULLABLE 변경 | X | O | O | O | X |
| 칼럼 NOT NULL 변경 | X | O | O | O | X |
| ENUM 또는 SET 정의 변경 | O | O | X | O | O |

<br>

- 가상 칼럼 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| STORED 추가 | X | X | O | X | X |
| STORED 순서 변경 | X | X | O | X | X |
| STORED 삭제 | X | O | O | O | X |
| VIRTUAL 추가 | O | O | X | O | O |
| VIRTUAL 순서 변경 | X | X | O | X | X |
| VIRTUAL 삭제 | O | O | X | O | O |

<br>

- 외래키 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 외래키 생성 | X | O | X | O | O |
| 외래키 삭제 | X | O | X | O | O |

<br>

- 테이블 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| ROW_FORMAT 변경 | X | O | O | O | X |
| KEY_BLOCK_SIZE 변경 | X | O | O | O | X |
| STATS_PERSISTENT 설정 | X | O | X | O | O |
| CHARACTER SET 설정 | X | O | O | X | X | 
| CHARACTER SET 변경 | X | X | O | X | X |
| 테이블 최적화(OPTIMIZE) | X | O | O | O | X |
| 테이블 리빌드(FORCE 옵션) | X | O | O | O | X | 
| 테이블명 변경 | O | O | X | O | O |

<br>

- 테이블 스페이스 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| 제너럴 테이블스페이스 이름 변경 | X | O | X | O | O |
| 제너럴 테이블스페이스 암호화 옵션 변경 | X | O | X | O | X |
| 테이블별 테이블스페이스 암호화 옵션 변경 | X | X | O | X | X |

<br>

- 파티션 변경

| 변경 작업 | INSTANT | INPLACE | REBUILD TABLE | DML | METADATA ONLY |
|--|--|--|--|--|--|
| PARTITION BY | X | X | O | X | X |
| ADD PARTITION | X | O | O | O (LIST, RANGE) <br> X (KEY, HASH) | X |
| DROP PARTITION | X | O | O | O (LIST, RANGE) <br> X (KEY, HASH) | X |
| 파티션의 테이블스페이스 삭제 | X | X | X | X | X |
| 파티션의 테이블스페이스 IMPORT | X | X | X | X | X |
| 파티션 TRUNCATE | X | O | O | O | X |

<br>

모든 스키마 변경 작업에 대해 온라인 DDL 지원 여부를 확인하는 것은 불가능  
`ALGORITHM`과 `LOCK` 옵션을 명시해서 강제한 후 처리하지 못하면 단순히 에러만 발생  

```
mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=INSTANT;
ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported. Reason: Dropping a primary key is not
allowed without also adding a new primary key. Try ALGORITHM=COPY/INPLACE.

mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=INPLACE, LOCK=NONE;
ERROR 1846 (0A000): ALGORITHM=INSTANT is not supported. Reason: Dropping a primary key is not
allowed without also adding a new primary key. Try ALGORITHM=COPY.

mysql> ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM=COPY, LOCK=SHARED;
Query OK, 300024 rows affected (6.24 sec)
Records: 300024 Duplicates: 0 Warnings: 0

mysql> ALTER TABLE employees ADD PRIMARY KEY (emp_no), ALGORITHM=INPLACE, LOCK=NONE;
Query OK, 0 rows affected (1.48 sec)
Records: 0 Duplicates: 0 Warnings: 0 
```

<br>

다음 순서대로 `ALGORITHM`과 `LOCK` 옵션을 시도하면서 지원여부 판단  
1. `ALGORITHM=INSTANT` 옵션으로 스키마 변경 시도
2. `ALGORITHM=INPLACE, LOCK=NONE` 옵션으로 스키마 변경 시도
3. `ALGORITHM=INPLACE, LOCK=SHARED` 옵션으로 스키마 변경 시도
4. `ALGORITHM=COPY, LOCK=SHARED` 옵션으로 스키마 변경 시도
5. `ALGORITHM=COPY, LOCK=EXCLUSIVE` 옵션으로 스키마 변경 시도

<br>

### INPLACE 알고리즘
임시 테이블로 레코드를 복사하지 않더라도 내부적으로 테이블의 모든 레코드를 리빌드하는 경우 많음  

1. INPLACE 스키마 변경이 지원되는 스토리지 엔진 테이블인지 확인
2. INPLACE 스키마 변경 준비
3. 테이블 스키마 변경 및 새로운 DML 로깅(실제 스키마 변경 수행, 이 동안 다른 커넥션 DML 작업이 대기하지 않음)
4. 로그 적용
5. INPLACE 스키마 변경 완료

2번과 4번 단계에서는 잠깜의 배타적 잠금(`Exclusive lock`) 필요, 이 시점에서는 다른 커넥션의 DML 잠깐 대기  
하지만 실제 변경 작업이 실행되면서 많은 시간이 필요한 3번 단계는 다른 커넥션의 DML 작업이 대기 없이 즉시 처리  
해당 시점에 DML 쿼리들에 의해 변경되는 데이터를 온라인 변경 로그(`Online alter log`) 메모리 공간에 쌓아둠  
스키마 변경이 완료되면 해당 로그 내용을 실제 테이블로 일괄 적용  
해당 메모리 크기는 `innodb_online_alter_log_max_size` 시스템 변수로 설정  

<br>

### 온라인 DDL의 실패 케이스
INSTANT 알고리즘의 경우 시작과 동시에 작업이 완료되기 때문에 작업 도중 실패할 가능성 거의 없음  
IMPLACE 알고리즘의 경우 내부적으로 리빌드 과정이 필요하고 최종 로그 적용 과정이 필요해서 중간 실패 가능성 존재  

<br>

1. 장시간 동안 스키마 변경이 진행되고, 동시에 많은 DML 쿼리 대기로 인해 온라인 변경 로그 공간 부족한 경우  
```
ERROR 1799 (HY000): Creating index 'idx_col1' required more than 'innodb_online_alter_
log_max_size' bytes of modification log. Please try again.
```

<br>

2. 스키마 변경은 문제없지만, DML 쿼리가 해당 구조에 적합하지 않은 레코드를 삽입/수정한 경우
```
ERROR 1062 (23000): Duplicate entry 'd005-10001' for key 'PRIMARY'
```

<br>

3. 스키마 변경을 위해서 필요한 잠금 수준보다 낮은 잠금 옵션이 사용된 경우
```
ERROR 1846 (0A000): LOCK=NONE is not supported. Reason: Adding an auto-increment column
requires a lock. Try LOCK=SHARED
```

<br>

4. 스키마 변경은 `LOCK=NONE`으로 실행해도, 변경 작업의 처음과 마지막 과정에서 잠금이 필요한데 획득하지 못한 경우
```
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
```

<br>

5. 온라인으로 인덱스 생성시 정렬을 위한 tmpdir 시스템 변수에 설정된 임시 디렉토리 공간이 부족한 경우  

<br>

온라인 스키마 변경에서 필요한 잠금은 테이블 수준의 메타데이터 잠금  
메타데이터 잠금에 대한 타임 아웃은 `lock_wait_timeout` 시스템 변수로 설정  

```
mysql> SHOW GLOBAL VARIABLES LIKE 'lock_wait_timeout';
+-------------------+----------+
| Variable_name     | Value    |
+-------------------+----------+
| lock_wait_timeout | 31536000 |
+-------------------+----------+

mysql> SET SESSION lock_wait_timeout = 1800;
mysql> ALTER TABLE tab_test ADD fd2 VARCHAR(20), ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

### 온라인 DDL 진행 상황 모니터링
온라인 DDL 및 모든 ALTER TABLE 명령은 `performance_schema` 통해서 진행 상황 모니터링 가능  
우선 `Instrument`와 `Consumer` 옵션 활성화 필수  

```sql
## performance_schema 시스템 변수 활성화(서버 재시작 필요)
SET GLOBAL performance_schema=ON;

## "stage/innodb/alter%" instrument 활성화
UPDATE performance_schema.setup_instruments
SET ENABLED = 'YES', TIMED = 'YES'
WHERE NAME LIKE 'stage/innodb/alter%';

## "%stages%" consumer 활성화
UPDATE performance_schema.setup_consumers
SET ENABLED = 'YES'
WHERE NAME LIKE '%stages%';
```

<br>

스키마 변경 작업의 진행 상황은 `performance_schema.events_stages_current` 테이블을 통해 확인  

```
-- // COPY 알고리즘 스키마 변경
mysql_session1> ALTER TABLE salaries DROP PRIMARY KEY, ALGORITHM=COPY, LOCK=SHARED;

-- // performance_schema 진행 상황
mysql_session2> SELECT EVENT_NAME, WORK_COMPLETED, WORK_ESTIMATED
                FROM performance_schema.events_stages_current;
+-----------------------------+----------------+----------------+
| EVENT_NAME                  | WORK_COMPLETED | WORK_ESTIMATED |
+-----------------------------+----------------+----------------+
| stage/sql/copy to tmp table |        1562071 |        2838662 |
+-----------------------------+----------------+----------------+
```

```
-- // INPLACE 알고리즘 스키마 변경
mysql_session1> ALTER TABLE salaries
                ADD INDEX ix_todate (to_date),
                ALGORITHM=INPLACE, LOCK=NONE;

-- // performance_schema 진행 상황
mysql_session2> SELECT EVENT_NAME, WORK_COMPLETED, WORK_ESTIMATED
                FROM performance_schema.events_stages_current;
+------------------------------------------------------+----------------+----------------+
| EVENT_NAME                                           | WORK_COMPLETED | WORK_ESTIMATED |
+------------------------------------------------------+----------------+----------------+
| stage/innodb/alter table (read PK and internal sort) |           9776 |          25281 |
+------------------------------------------------------+----------------+----------------+

mysql_session2> SELECT EVENT_NAME, WORK_COMPLETED, WORK_ESTIMATED
                FROM performance_schema.events_stages_current;
+---------------------------------------+----------------+----------------+
| EVENT_NAME                            | WORK_COMPLETED | WORK_ESTIMATED |
+---------------------------------------+----------------+----------------+
| stage/innodb/alter table (merge sort) |          17641 |          27121 |
+---------------------------------------+----------------+----------------+

mysql_session2> SELECT EVENT_NAME, WORK_COMPLETED, WORK_ESTIMATED
                FROM performance_schema.events_stages_current;
+-----------------------------------+----------------+----------------+
| EVENT_NAME                        | WORK_COMPLETED | WORK_ESTIMATED |
+-----------------------------------+----------------+----------------+
| stage/innodb/alter table (insert) |          23460 |          27121 |
+-----------------------------------+----------------+----------------+

mysql_session2> SELECT EVENT_NAME, WORK_COMPLETED, WORK_ESTIMATED
                FROM performance_schema.events_stages_history;
+--------------------------------+----------------+----------------+
| EVENT_NAME                     | WORK_COMPLETED | WORK_ESTIMATED |
+--------------------------------+----------------+----------------+
| stage/innodb/alter table (end) |          25719 |          27351 |
+--------------------------------+----------------+----------------+
```

<br>

## 데이터베이스 변경
하나의 인스턴스는 한개 이상의 데이터베이스 보유 가능  
데이터베이스에 설정 가능한 옵션은 기본 문자 집합이나 콜레이션 정도로 간단  

<br>

### 데이터베이스 생성

```sql
CREATE DATABASE [IF NOT EXISTS] employees;
CREATE DATABASE [IF NOT EXISTS] employees CHARACTER SET utf8mb4;
CREATE DATABASE [IF NOT EXISTS] employees CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

<br>

### 데이터베이스 목록
```sql
SHOW DATABASES;
SHOW DATABASES LIKE '%emp%';
```

권한을 가지고 있는 데이터베이스 목록만 표시  

<br>

### 데이터베이스 선택
```sql
USE employees;
SELECT * FROM employees.departments;
```

기본 데이터베이스를 선택하는 명령  
별도로 데이터베이스를 명시하지 않고 테이블 이름이나 프로시저 이름만 명시하면, 현재 커넥션의 기본 데이터베이스에서 탐색  

<br>

### 데이터베이스 속성 변경
```sql
ALTER DATABASE employees CHARACTER SET=euckr;
ALTER DATABASE employees CHARACTER SET=euckr COLLATE=euckr_korean_ci;
```

<br>

### 데이터베이스 삭제
```sql
DROP DATABASE [IF EXISTS] employees;
```

<br>


## 테이블 스페이스 변경
전통적으로 테이블별로 전용의 테이블스페이스 사용  
InnoDB 스토리지 엔진의 시스템 테이블스페이스(`ibdata1` 파일)만 제너럴 테이블스페이스(`General Tablespace`) 사용  
제너럴 테이블스페이스는 여러 테이블의 데이터를 한꺼번에 저장하는 테이블스페이스를 의미  
8.0 버전부터 사용자 테이블을 제너럴 테이블스페이스로 저장 가능  
- 파티션 테이블을 제너럴 테이블스페이스로 사용 불가
- 복제 소스와 레플리카 서버가 동일 호스트에서 실행되는 경우 ADD DATAFILE 문장 사용 불가
- 테이블 암호화(`TDE`)는 테이블스페이스 단위로 설정
- 테이블 압축 가능 여부는 테이블스페이스의 블록 크기와 InnoDB 페이지 크기로 결정
- 특정 테이블을 삭제해도 디스크 공간이 운영체제로 반납되지 않음

<br>

그럼에도 사용자 테이블을 제너럴 테이블스페이스로 이용한 경우 아래 장점 존재  
- 파일 핸들러(`Open file descriptor`) 최소화
- 테이블스페이스 관리에 필요한 메모리 공간 최소화

<br>

제너럴 테이블스페이스의 장점은 테이블 갯수가 많은 경우 매우 유용  
하지만 아직 일반적인 환경에서 제너럴 테이블스페이스의 장점을 취하기 어려움  
제너럴 테이블스페이스 사용 여부는 `innodb_file_per_table` 시스템 변수로 설정  
기본값은 ON, 테이블을 자동으로 개별 테이블스페이스로 사용  

<br>

## 테이블 변경
사용자 데이터를 가지는 주체로서, 많은 옵션과 인덱스 등의 기능이 테이블에 종속  

<br>

### 테이블 생성
```sql
CREATE [TEMPORARY] TABLE [IF NOT EXISTS] tb_test
  member_id BIGINT [UNSIGNED] [AUTO_INCREMENT],
  nickname CHAR(20) [CHARACTER SET 'utf8'] [COLLATE 'utf8_general_ci'] [NOT NULL],
  home_url VARCHAR(200) [COLLATE 'latin1_general_cs'],
  birth_year SMALLINT [(4)] [UNSIGNED] [ZEROFILL],
  member_point INT [NOT NULL] [DEFAULT 0],
  registered_dttm DATETIME [NOT NULL],
  modified_ts TIMESTAMP [NOT NULL] [DEFAULT CURRENT_TIMESTAMP],
  gender ENUM('Female', 'Male') [NOT NULL],
  hobby SET('Reading', 'Game', 'Sports'),
  profile TEXT [NOT NULL],
  session_data BLOB,
  PRIMARY KEY (member_id),
  UNIQUE INDEX ux_nickname (nickname),
  INDEX ix_registereddttm (registered_dttm)
) ENGINE=INNODB;
```

<br>

`TEMPORARY` 키워드를 사용하면 해당 데이터베이스 커넥션에서만 사용 가능한 임시 테이블 생성  
각 칼럼은 `칼럼명 칼럼타입 [타입별 옵션] [NULL 허용 여부] [기본값]` 형태로 명시  

- 모든 칼럼은 공통적으로 칼럼 초기값과 NULL 허용 여부를 설정 가능
- 문자열 타입은 타입 뒤에 반드시 칼럼 최대 저장 문자수 명시
- CHARACTER SET 절은 칼럼에 저장될 문자열 값이 어떤 문자 집합인지 결정, COLLATE로 문자열 비교나 정렬 규칙 표현
- 숫자 타입은 선택적으로 길이 보유 가능, 하지만 이는 실제 칼럼값 길이가 아닌 단순히 값 표기를 위한 길이
- ZEROFILL 키뤄드로 숫자 값 왼쪽에 `0` 패딩 여부 결정
- 5.6 버전부터 DATE 또는 DATETIME 타입의 기본값을 현재 시각으로 설정 가능
- ENUM 또는 SET 타입은 이름 뒤에 해당 칼럼이 가질 수 있는 값을 괄호로 정의

<br>

### 테이블 구조 조회
`SHOW CREATE TABLE` 명렬과 `DESC` 명령으로 테이블 구조 조회 가능  

```
mysql> SHOW CREATE TABLE employees \G
*************************** 1. row ***************************
       Table: employees
Create Table: CREATE TABLE `employees` (
  `emp_no` int NOT NULL,
  `birth_date` date NOT NULL,
  `name` varchar(14) COLLATE utf8mb4_general_ci NOT NULL,
  `gender` enum('M', 'F') COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`emp_no`),
  KEY `ix_name` (`name`)
) ENGINE=INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci STATS_PERSISTENT=0

mysql> DESC employees;
+------------+----------------+------+-----+---------+-------+
| Field      | Type           | Null | Key | Default | Extra |
+------------+----------------+------+-----+---------+-------+
| emp_no     | int            | NO   | PRI | NULL    |       |
| birth_date | date           | NO   |     | NULL    |       |
| name       | varchar(14)    | NO   | MUL | NULL    |       |
| gender     | enum('M', 'F') | NO   |     | NULL    |       |
+------------+----------------+------+-----+---------+-------+
```

<br>

### 테이블 구조 변경
```sql
## 기본 문자 집합과 콜레이션 변경
ALTER TABLE employees
CONVERT TO CHARACTER SET UTF8MB4 COLLATE UTF8MB4_GENERAL_CI
ALGORITHM=INPLACE, LOCK=NONE;

## 스토리지 엔진 변경
## 변경 목적으로도 사용하지만 테이블 리빌드를 통해 디스크 프레그멘테이션 제거용으로도 사용
ALTER TABLE employees ENGINE=INNODB,
ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

### 테이블 명 변경
단순히 테이블 이름 변경뿐만 아니라 다른 데이터베이스로 테이블 이동할때도 사용  

```sql
RENAME TABLE table1 TO table2;
RENAME TABLE db1.table1 TO db2.table2;

## 중간에 갑자기 사라지는 테이블 예방
RENAME TABLE batch TO batch_old, batch_new TO batch;
```

<br>

### 테이블 상태 조회
모든 테이블은 만들어진 시간, 대략 레코드 건수, 데이터 파일 크기 등 정보를 보유  
해당 값들은 MySQL 서버가 예측하고 있는 값이기 때문에 테이블 크기에 따라 오차가 커질 가능성 존재  

```
mysql> SHOW TABLE STATUS LIKE 'employees' \G
*************************** 1. row ***************************
           Name: employees
         Engine: InnoDB
        Version: 10
     Row_format: Dynamic
           Rows: 300252
 Avg_row_length: 57
    Data_length: 17317888
Max_data_length: 0
   Index_length: 15253504
      Data_free: 5242880
 Auto_increment: NULL
    Create_time: 2020-08-31 18:04:33
    Update_time: NULL
     Check_time: NULL
      Collation: utf8mb4_general_ci
       Checksum: NULL
 Create_options: stats_persistent=0
        Comment:
1 row in set (0.08 sec)
```

<br>

`information_schema` 데이터베이스를 이용해 조회 가능
- 데이터베이스 객체에 대한 메타 정보
- 테이블과 칼럼에 대한 간략한 통계 정보
- 전문 검색 디버깅을 위한 뷰
- 압축 실행과 실패 횟수에 대한 집계

```
mysql> SELECT * FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = 'employees' AND TABLE_NAME = 'employees' \G
***************************** 1. row *****************************
  TABLE_CATALOG: def
   TABLE_SCHEMA: employees
     TABLE_NAME: employees
     TABLE_TYPE: BASE TABLE
         ENGINE: InnoDB
        VERSION: 10
     ROW_FORMAT: Dynamic
     TABLE_ROWS: 300252
 AVG_ROW_LENGTH: 57
    DATA_LENGTH: 17317888
MAX_DATA_LENGTH: 0
   INDEX_LENGTH: 15253504
      DATA_FREE: 5242880
 AUTO_INCREMENT: NULL
    CREATE_TIME: 2020-08-31 18:04:33
    UPDATE_TIME: NULL
     CHECK_TIME: NULL
TABLE_COLLATION: uft8mb4_feneral_ci
       CHECKSUM: NULL
 CREATE_OPTIONS: stats_persistent=0
   TABLE_COMMET:
1 row in set (0.00 sec)

mysql> SELECT TABLE_SCHEMA,
              SUM(DATA_LENGTH)/1024/1024 as data_size_mb,
              SUM(INDEX_LENGTH)/1024/1024 as index_size_mb
        FROM information_schema.TABLES
        GROUP BY TABLE_SCHEMA;
+--------------------+--------------+---------------+
| TABLE_SCHEMA       | data_size_mb | index_size_mb |
+--------------------+--------------+---------------+
| mysql              |   2.17187500 |    0.31250000 |
| sys                |   0.01562500 |    0.00000000 |
| information_schema |   0.00000000 |    0.00000000 |
| performance_schema |   0.00000000 |    0.00000000 |
| employees          | 190.33203125 |   93.01660156 |
+--------------------+--------------+---------------+
```

<br>

### 테이블 구조 복사
테이블 구조가 같지만 이름만 다른 테이블 생성시 `LIKE` 키워드 사용  
`SHOW CREATE TABLE` 명령을 이용한 DDL 조회 후 변경해서 생성 가능  
`CREATE TABLE ... AS SELECT ... LIMIT 0` 명령으로도 가능, 단 인덱스 생성 불가  

```sql
## 데이터 구조 복사
CREATE TABLE temp_employees LIKE employees;

## 데이터까지 복사
INSERT INTO temp_employees SELECT * FROM employees;
```

<br>

### 테이블 삭제
8.0 버전에서는 특정 테이블을 삭제하는 작업이 다른 테이블의 DML 또는 쿼리를 직접 방해하지 않음  
하지만 용량이 큰 테이블을 삭제하는 작업은 상당히 부하가 큰 작업, 서비스 도중 삭제 작업은 수행하지 않는 것 권장    
또한 테이블 삭제될때 같이 수행되는 어댑티브 해시 인덱스 삭제 작업도 서버 부하가 높음  

```sql
DROP TABLE [IF EXISTS] table1;
```

<br>

### 칼럼 추가
8.0 버전부터 테이블 칼럼 추가 작업은 대부분 INPLACE 알고리즘을 사용하는 온라인 DDL 처리 가능  
칼럼을 테이블의 제일 마지막 칼럼으로 추가하는 경우에는 INSTANT 알고리즘으로 즉시 추가 가능  

```sql
## 테이블의 제일 마지막에 칼럼 추가
ALTER TABLE employees ADD COLUMN emp_telno VARCHAR(20),
ALGORITHM=INSTANT;

## 테이블의 중간에 칼럼 추가
ALTER TABLE employees ADD COLIMN emp_telno VARCHAR(20) AFTER emp_no,
ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

### 칼럼 삭제
칼럼을 삭제하는 작업은 항상 테이블 리빌드  
INSTANT 알고리즘 사용 불가, 항상 INPLACE 알고리즘 사용  

```sql
ALTER TABLE employees DROP COLUMN emp_telno,
ALGORITHM=INPLACE, LOCK=NONE;
```

<br>

### 칼럼 이름 및 칼럼 타입 변경
```sql
## 칼럼의 이름 변경
## INPLACE 알고리즘을 사용하지만 실제 데이터 리빌드 작업은 필요치 않음
ALTER TABLE salaries CHANGE to_date end_date DATE NOT NULL,
ALGORITHM=INPLACE, LOCK=NONE;

## INT 칼럼을 VARCHAR 타입으로 변경
## COPY 알고리즘이 필요하며 온라인 DDL로 실행돼도 스키마 변경 중 테이블 쓰기 작업 불가
ALTER TABLE salaries MODIFY salary VARCHAR(20),
ALGORITHM=COPY, LOCK=SHARED;

## VARCHAR 타입의 길이 확장
## 타입 길이를 확장하는 경우는 현재 길이와 확장하는 길이의 관계에 따라 리빌드 발생 상이
ALTER TABLE employees MODIFY last_name VARCHAR(30) NOT NULL,
ALGORITHM=INPLACE, LOCK=NONE;

## VARCHAR 타입의 길이 축소
## 완전히 다른 타입으로 변경되는 경우와 같이 COPY 알고리즘 사용
ALTER TABLE employees MODIFY last_name VARCHAR(30) NOT NULL,
ALGORITHM=COPY, LOCK=SHARED;
```

<br>




























