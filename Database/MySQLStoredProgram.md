# 스토어드 프로그램
MySQL에서는 절차적인 처리를 위해 스토어드 프로그램 사용 가능  
스토어드 루틴이라도고 표현하며, 스토어드 프로시저와 스토어드 함수, 트리거와 이벤트 등을 모두 아우르는 명칭  

<br>

## 스토어드 프로그램의 장단점
절차적인 처리를 제공하지만 애플리케이션을 대체할 수 있을지 고려 필요  

<br>

### 스토어드 프로그램의 장점
- 데이터베이스 보안 향상  
자체적인 보안 설정 기능 보유, 스토어드 프로그램 단위로 실행 권한 부여  

- 기능 추상화  
자바나 C/C++ 같은 객체지향 언어의 추상화와 유사  

- 네트워크 소요 시간 절감  
일반적으로 애플리케이션과 데이터베이스 서버는 같은 네트워크 구간에 존재하기 때문에 경유 시간이 크게 중요하지 않음  
하지만 쿼리가 아주 가볍고 빠르게 처리되는 경우 네트워크 경유 시간이 문제가 될 가능성 존재  
여러 쿼리를 하나의 스토어드 프로그램으로 호출한다면 네트워크 경유 시간 감소  

- 절차적 기능 구현  
DBMS 서버에서 사용하는 SQL 쿼리는 절차적인 기능을 제공하지 않음  
하지만 스토어드 프로그램은 복잡한 제어 기능 제공  

- 개발 업무 구분  
애플리케이션 개발 조직과 SQL 개발 조직이 구분 가능  
스토어드 프로그램을 만들어 API처럼 제공  

<br>

### 스토어드 프로그램의 단점
- 낮은 처리 성능  
MySQL 서버는 절차적 코드 처리를 주목적으로 하지 않아서 다른 언어에 비해 상대적으로 성능 낮음  

- 애플리케이션 코드 조각화  
각 기능을 담당하는 프로그램 코드가 분산된다면 애플리케이션 설치나 배포가 복잡  

<br>

## 스토어드 프로그램의 문법
스토어드 프로그램은 헤더 부분과 본문 부분으로 구분  
헤더 부분은 정의부라고 하며, 주로 스토어드 프로그램의 이름과 입출력 값을 명시  
본문 부분은 바디라고도 하며, 스토어드 프로그램이 호출됐을때 실행하는 내용 작성하는 부분  

<br>

## 스토어드 프로시저
데이터를 주고받아야 하는 여러 쿼리를 하나의 그룹으로 묶어서 독립적으로 실행하기 위해 사용  
대표적으로 배치 프로그램에서 첫번째 쿼리 결과를 이용해 두번째 쿼리를 실행해야하는 것  
MySQL 서버와 클라이언트 간의 네트워크 전송 작업을 최소화하고 수행 시간 감소 가능  

<br>

### 스토어드 프로시저 생성 및 삭제
```sql
DELIMITER ;;

CREATE PROCEDURE sp_sum (IN param1 INTEGER, IN param2 INTEGER, OUT param3 INTEGER)
BEGIN
  SET param3 = param1 + param2;
END ;;

DELIMITER ;
```

- 스토어드 프로시저는 기본 반환값 없음
- 스토어드 프로시저의 각 파라미터는 3가지 특성 중 하나를 지님
  - IN 타입으로 정의된 파라미터는 입력 전용 파라미터를 의미
  - OUT 타입으로 정의된 파라미터는 출력 전용 파라미터를 의미
  - INOUT 타입으로 정의된 파라미터는 입력 및 출력 용도로 모두 사용 가능

<br>

스토어드 프로시저를 포함한 스토어드 프로그램을 사용할 때는 SQL 구분자 변경 필수  
스토어드 본문 내부에 무수히 많은 `;` 문자를 포함하기 때문에 명령의 끝을 정확히 찾기 불가능  
명령의 끝을 알려주는 종료 문자를 변경하는 명령어는 `DELIMITER`  

<br>

```sql
## 보안 및 작동 방식과 관련된 특성을 변경
ALTER PROCEDURE sp_sum SQL SECURITY DEFINER;

## 프로시저 삭제
DROP PROCEDURE sp_sum;;
```

<br>

### 스토어드 프로시저 실행
스토어드 프로시저와 스토어드 함수의 큰 차이점 중 하나가 바로 실행하는 방법  
스토어드 프로시저는 조회 쿼리에 사용 불가, 반드시 `CALL` 명령어로 실행  

```
mysql> SET @result:=0;
mysql> SELECT @result;
+---------+
| @result |
+---------+
|       0 |
+---------+

mysql> CALL sp_sum(1,2,@result);
mysql> SELECT @result;
+---------+
| @result |
+---------+
|       3 |
+---------+
```

<br>

### 스토어드 프로시저의 커서 반환
스토어드 프로그램은 명시적으로 커서를 파라미터로 전달받거나 반환 불가  
하지만 스토어드 프로시저 내에서 커서를 오픈하지 않거나, 조회 쿼리의 결과 셋을 Fetch하지 않으면 해당 쿼리 결과 셋은 바로 전송  

```
mysql> CREATE PROCEDURE sp_selectEmployees (IN in_empno INTEGER)
       BEGIN
         SELECT * FROM employees WHERE emp_no = in_empno;
       END ;;
mysql> CALL sp_selectEmployees(10001);;
+--------+------------+------------+-----------+--------+------------+
| emp_no | birth_date | first_name | last_name | gender | hire_date  |
+--------+------------+------------+-----------+--------+------------+
|  10001 | 1953-09-02 |     Georgi |   Facello |      M | 1986-06-26 |
+--------+------------+------------+-----------+--------+------------+
```

<br>

스토어드 프로시저에서 쿼리 결과 셋을 클라이언트로 전송하는 기능은 프로시저 디버깅 용도로 자주 사용  

```
mysql> CREATE PROCEDURE sp_sum (IN param1 INTEGER, IN param2 INTEGER, OUT param3 INTEGER)
       BEGIN
         SELECT '> Stored procedure started.' AS debug_message;
         SELECT CONCAT('> param1 : ', param1) AS debug_message;
         SELECT CONCAT('> param2 : ', param2) AS debug_message;

         SET param3 = param1 + param2;
         SELECT '> Stored procedure completed.' AS debug_message;
       END ;;

mysql> CALL sp_sum(1,2,@result);;
+-----------------------------+
| debug_message               |
+-----------------------------+
| > Stored procedure started. |
+-----------------------------+
+---------------+
| debug_message |
+---------------+
|  > param1 : 1 |
+---------------+
+---------------+
| debug_message |
+---------------+
|  > param2 : 2 |
+---------------+
+-------------------------------+
| debug_message                 |
+-------------------------------+
| > Stored procedure completed. |
+-------------------------------+
```

<br>

### 스토어드 프로시저 딕셔너리
8.0 이전 버전까지는 스토어드 프로시저가 `proc` 테이블에 저장  
8.0 버전부터 사용자에게 보이지 않는 시스템 테이블로 저장  
단지 `information_schema` 데이터베이스의 `ROUTINES` 뷰를 통해 스토어드 프로시저 정보 조회 가능  

```
mysql> SELECT routine_schema, routine_name, routine_type
       FROM information_schema.ROUTINES
       WHERE routine_schema = 'test';
+----------------+----------------+--------------+
| ROUTINE_SCHEMA | ROUTINE_NAME   | ROUTINE_TYPE |
+----------------+----------------+--------------+
| test           | func_clean     | FUNCTION     |
| test           | func_dirty     | FUNCTION     |
| test           | getDistanceMBR | FUNCTION     |
| test           | sp_sum         | PROCEDURE    |
+----------------+----------------+--------------+

mysql> SELECT routine_schema, routine_name, routine_definition, routine_body
       FROM information_schema.ROUTINES
       WHERE routine_schema = 'test'
         AND routine_type = 'PROCEDURE' \G
***************************** 1. row *****************************
    ROUTINE_SCHEMA: test
      ROUTINE_NAME: sp_sum
ROUTINE_DEFINITION: BEGIN
         SELECT '> Stored procedure started.' AS debug_message;
         SELECT CONCAT(' > param1 : ', param1) AS debug_message;
         SELECT CONCAT(' > param2 : ', param2) AS debug_message;

         SET param3 = param1 + param2;
         SELECT '> Stored procedure completed.' AS debug_message;
       END
      ROUTINE_BODY: SQL
```

<br>

## 스토어드 함수
하나의 SQL 문장으로 작성이 불가능한 기능을 하나의 SQL 문장으로 구현해야 할 때 사용  
SQL 문장과 관계없이 별도로 실행되는 기능이라면 굳이 스토어드 함수를 개발할 필요 없음  
스토어드 프로시저와 비교했을때 유일한 장점은 SQL 문장의 일부로 사용 가능하다는 것  

<br>

### 스토어드 함수 생성 및 삭제
모든 입력 파라미터가 읽기 전용이라 IN, OUT, INOUT 같은 형식 지정 불가  

```sql
CREATE FUNCTION sf_sum(param1 INTEGER, param2 INTEGER)
  RETURNS INTEGER
BEGIN
  DECLARE param3 INTEGER DEFAULT 0;
  SET param3 = param1 + param2;
  RETURN param3;
END ;;
```

스토어드 함수가 스토어드 프로시저와 다른 부분은 아래와 같음  
- 함수 정의부에 `RETURNS`로 반환되는 값의 타입 명시 필수
- 함수 본문 마지막에 정의부에 지정된 타입과 동일한 타입의 값을 `RETURN` 명령으로 반환

<br>

스토어드 프로시저와 달리 함수 본문에 아래 사항을 사용하지 못함  
- `PREPARE`와 `EXECUTE` 명령을 이용한 프리페어 스테이트먼트 사용 불가
- 명시적 또는 묵시적 `ROLLBACK`/`COMMIT` 유발 SQL 사용 불가
- 재귀 호출 사용 불가
- 스토어드 함수 내에서 프로시저 호출 불가
- 결과 셋을 반환하는 SQL 문장 사용 불가

<br>

결과 셋을 페치하지 않아서 결과 셋이 클라이언트로 전소오디는 스토어드 함수를 생성하는 경우 에러 발생  

```
mysql> CREATE FUNCTION sf_resultset_test()
         RETURNS INTEGER
       BEGIN
         DECLARE param3 INTEGER DEFAULT 0;
         SELECT 'Start stored function' AS debug_message;
         RETURN param3;
       END ;;
ERROR 1415 (0A000): Not allowed to return a result set from a function
```

<br>

스토어드 프로시저와 마찬가지로 스토어드 함수도 단지 특성만 변경 가능  

```sql
ALTER FUNCTION sf_sum SQL SECURITY DEFINER;

DROP FUNCTION sf_sum;;
```

<br>

### 스토어드 함수 실행
스토어드 함수는 스토어드 프로시저와 달리 `CALL` 명령 불가  

```
mysql> SELECT sf_sum(1,2) AS sum;
+-----+
| sum |
+-----+
|   3 |
+-----+

mysql> CALL sf_sum(1,2);
ERROR 1305 (42000): PROCEDURE sf_sum does not exist
```

<br>

## 트리거
테이블의 레코드가 저장되거나 변경될때 미리 정의해둔 작업을 자동으로 실행해주는 스토어드 프로그램  
MySQL 트리거는 INSERT, UPDATE, DELETE 쿼리 실행시 시작되도록 설정 가능  
대표적으로 칼럼 유효성 체크, 복사 및 백업, 계산된 결과를 다른 테이블에 함께 업데이트하는 등의 작업을 위해 사용  
스토어드 함수나 프로시저보다는 필요성이 떨어지는 편  
트리거는 테이블에 대해서만 생성 가능  
5.7 이전 버전에서는 테이블당 하나의 이벤트에 대해 2개 이상 트리거 등록이 불가능  

<br>

### 트리거 생성
`BEFORE`, `AFTER` 키워드를 사용해서 트리거가 언제 실행될지 명시  
`OLD` 키워드는 테이블의 변경되기 전 레코드, `NEW` 키워드는 변경될 레코드를 지칭  

```sql
CREATE TRIGGER on_delete BEFORE DELETE ON employees
  FOR EACH ROW
BEGIN
  DELETE FROM salaries WHERE emp_no = OLD.emp_no;
END ;;
```

<br>

| SQL 종류 | 이벤트 순서 |
|--|--|
| INSERT | BEFORE INSERT ==> AFTER INSERT |
| LOAD DATA | BEFORE INSERT ==> AFTER INSERT |
| REPLACE | 중복 레코드 존재하는 경우: <br> &emsp;BEFORE INSERT ==> AFTER INSERT <br> 중복 레코드 존재하지 않는 경우: <br> &emsp;BEFORE DELETE ==> AFTER DELETE ==> BEFORE INSERT ==> AFTER INSERT |
| INSERT INTO ... <br> ON DUPLICATE SET | 중복 레코드 존재하는 경우: <br> &emsp;BEFORE INSERT ==> AFTER INSERT <br> 중복 레코드 존재하지 않는 경우: <br> &emsp;BEFORE UPDATE ==> AFTER UPDATE |
| UPDATE | BEFORE UPDATE ==> AFTER UPDATE |
| DELETE | BEFORE DELETE ==> AFTER DELETE |
| TRUNCATE | 이벤트 발생하지 않음 |
| DROP TABLE | 이벤트 발생하지 않음 |

<br>

트리거의 `BEGIN ... END` 코드 블록에서 아래 유형은 사용 불가  
- 트리거는 외래키 관계에 의해 자동으로 변경되는 경우 호출 불가
- 레코드 기반 복제에서는 레플리카 서버의 트리거를 기동시키지 않지만, 문장 기반 복제는 기동시킴
- 명시적 또는 묵시적인 `ROLLBACK`/`COMMIT`을 유발하는 SQL 문장 사용 불가
- `RETURN` 문장 사용 불가, 트리거 종료시 `LEAVE` 명령 사용
- `information_schema`, `performance_schema` 데이터베이스에 존재하는 테이블에는 트리거 생성 불가

<br>

### 트리거 실행
트리거는 스토어드 프로시저나 함수와 같이 작동 확인을 위해 명시적으로 실행하는 방법이 없음  
직접 레코드 이벤트를 수행해서 작동 확인  

<br>

### 트리거 딕셔너리
8.0 이전 버전까지 트리거는 해당 데이터베이스 딕셔너리의 `*.TRG` 파일로 기록  
8.0 버전부터 보이지 않는 시스템 테이블로 저장, `information_schema` 데이터베이스의 `TRIGGERS` 뷰를 통해 조회  

```
mysql> SELECT trigger_schema, trigger_name, event_manipulation, action_timing
       FROM information_schema.TRIGGERS
       WHERE trigger_schema = 'employees';
+----------------+--------------+--------------------+---------------+
| TRIGGER_SCHEMA | TRIGGER_NAME | EVENT_MANIPULATION | ACTION_TIMING |
+----------------+--------------+--------------------+---------------+
| employees      | on_delete    | DELETE             | BEFORE        |
+----------------+--------------+--------------------+---------------+

mysql> SELECT trigger_schema, trigger_name, event_manipulation, action_timing, action_statement
       FROM information_schema.TRIGGERS
       WHERE trigger_schema = 'employees' \G;
*************************** 1. row ***************************
    TRIGGER_SCHEMA: employees
      TRIGGER_NAME: on_delete
EVENT_MANIPULATION: DELETE
     ACTION_TIMING: BEFORE
  ACTION_STATEMENT: BEGIN
         DELETE FROM salaries WHERE emp_no = OLD.emp_no;
       END
```

<br>

## 이벤트
주어진 특정한 시간에 스토어드 프로그램을 실행할 수 있는 스케줄러 기능  
MySQL 서버의 이벤트는 스케줄링을 전담하는 스레드 존재, 이 스레드가 활성화된 경우에만 이벤트 실행  
`event_scheduler` 시스템 변수값을 1로 설정해서 활성화 가능  
실행 이력은 별도로 저장되지 않고 가장 최근 실행된 정보만 조회 가능하기 때문에 이벤트 처리 로직에서 사용자 테이블로 직접 기록하는 것 권장  

```
mysql> SHOW GLOBAL VARIABLES LIKE 'event_scheduler';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| event_scheduler | ON    |
+-----------------+-------+

mysql> SHOW PROCESSLIST;
+----+-----------------+-----------+------+---------+--------+------------------------+------+
| Id | User            | Host      | db   | Command | Time   | State                  | Info |
+----+-----------------+-----------+------+---------+--------+------------------------+------+
|  5 | event_schesuler | localhost | NULL | Daemon  | 429360 | Waiting on empty queue | NULL |
+----+-----------------+-----------+------+---------+--------+------------------------+------+
```

<br>

### 이벤트 생성
이벤트는 반복 실행 여부에 따라 일회성 이벤트와 반복성 이벤트로 구분  
`DAY`, `QUARTER`, `MONTH`, `HOUR`, `MINUTE`, `WEEK`, `SECOUND` 등 반복 주기 사용 가능  

```sql
## 일회성 이벤트
CREATE EVENT onetime_job
  ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR
DO
  INSERT INTO daily_rank_log VALUES (NOW(), 'Donw');

## 반복성 이벤트
CREATE EVENT daily_ranking
  ON SCHEDULE EVERY 1 DAY STARTS '2020-09-07 01:00:00' ENDS '2021-01-01 00:00:00'
DO
  INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
```

<br>

반복 여부에 상관없이 DO 절은 단순히 하나의 쿼리나 스토어드 프로시저 호출 또는 `BEGIN ... END` 복합절 사용 가능  

```sql
## 프로시저 호출
CREATE EVENT daily_ranking
  ON SCHEDULE EVERY 1 DAY STARTS '2020-09-16 01:00:00' ENDS '2021-01-01 00:00:00'
DO
  CALL SP_INSERT_BATCH_LOG(NOW(), 'Done');

## 복합절 사용
CRETAE EVENT daily_ranking
  ON SCHEDULE EVERY 1 DAY STARTS '2020-09-16 01:00:00' ENDS '2021-01-01 00:00:00'
DO BEGIN
  INSERT INTO daily_rank_log VALUES (NOW(), 'Strat');
  ## 랭킹 정보 수집 & 처리
  INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
END ;;
```

<br>

`ON COMPLETION PRESERVE` 절을 이용해서 완전히 종료된 이벤트를 유지 가능, 기본적으로 완전히 종료된 이벤트는 자동으로 삭제  
이벤트를 생성할때 `ENABLE`, `DISABLE`, `DISABLE ON SLAVE` 3가지 상태로 생성 가능  
이벤트는 기본적으로 생성되면서 복제 소스 서버에서 `ENABLE`  
복제된 레플리카 서버에서는 `SLAVESIDE_DISABLED`로 생성  
복제 소스 서버에서 실행된 이벤트가 만들어낸 데이터 변경 사항은 자동으로 레플리카 서버로 복제  
다만 레플리카 서버가 소스 서버로 승격되면 수동으로 이벤트 상태를 `ENABLE` 상태로 변경 필수  

```
mysql> SELECT event_schema, event_name
       FROM information_schema.EVENTS
       WHERE STATUS = 'SLAVESIDE_DISABLED'
+--------------+------------+
| EVENT_SCHEMA | EVENT_NAME |
+--------------+------------+
| testdb       | myevent    |
+--------------+------------+

-- // 수동으로 
mysql> ALTER EVENT myevent ENABLE;
```

<br>

### 이벤트 실행 및 결과 확인
이벤트 또한 트리거와 같이 특정한 사건이 발생헤야 실행  

```
mysql> DELIMITER ;;
mysql> CREATE TABLE daily_tank_log (exec_dttm DATETIME, exec_msg VARCHAR(50));
mysql> CREATE EVENT daily_ranking
         ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
         ON COMPLETION PRESERVE
       DO BEGIN
         INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
       END ;;

mysql> SELECT * FROM information_schema.EVENTs \G
************************** 1. row **************************
   EVENT_CATALOG: def
    EVENT_SCHEMA: test
      EVENT_NAME: daily_ranking
         DEFINER: root@localhost
       TIME_ZONE: SYSTEM
      EVENT_BODY: SQL
EVENT_DEFINITION: BEGIN
     INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
   END
      EVENT_TYPE: ONE TIME
      EXECUTE_AT: 2020-09-08 09:09:46
  INTERVAL_VALUE: NULL
  INTERVAL_FIELD: NULL
        SQL_MODE: STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,...
          STARTS: NULL
            ENDS: NULL
          STATUS: DISABLED
   ON_COMPLETION: PRESERVE
         CREATED: 2020-09-08 09:08:46
    LAST_ALTERED: 2020-09-08 09:08:46
   LAST_EXECUTED: 2020-09-08 09:09:46
   EVENT_COMMENT:
      ORIGINATOR: 1

mysql> SELECT * FROM test.daily_rank_log;
+---------------------+----------+
| exec_dttm           | exec_msg |
+---------------------+----------+
| 2020-09-08 09:09:46 | Done     |
+---------------------+----------+
```

<br>

### 이벤트 딕셔너리
8.0 이전 버전까지 이벤트 딕셔너리 정보는 `events` 테이블에 관리  
8.0 버전부터 보이지 않는 시스템 테이블로 관리  
단지 `information_schema` 데이터베이스 `EVENTS` 뷰를 통해 조회 가능  

```
mysql> SELECT * FROM information_schema.EVENTS \G
*************************** 1. row ***************************
   EVENT_CATALOG: def
    EVENT_SCHEMA: test
      EVENT_NAME: daily_ranking
         DEFINER: root@localhost
       TIME_ZONE: SYSTEM
      EVENT_BODY: SQL
EVENT_DEFINITION: BEGIN
     INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
   END
      EVENT_TYPE: ONE TIME
      EXECUTE_AT: 2020-09-08 09:09:46
  INTERVAL_VALUE: NULL
  INTERVAL_FIELD: NULL
        SQL_MODE: STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,...
          STARTS: NULL
            ENDS: NULL
          STATUS: DISABLED
   ON_COMPLETION: PRESERVE
         CREATED: 2020-09-08 09:08:46
    LAST_ALTERED: 2020-09-08 09:08:46
   LAST_EXECUTED: 2020-09-08 09:09:46
   EVENT_COMMENT:
      ORIGINATOR: 1
```

<br>

## 스토어드 프로그램 본문(Body) 작성

### BEGIN ... END 블록과 트랜잭션
하나의 `BEGIN ... END` 블록은 또 다른 여러 개의 블록을 중첩해서 포함 가능  
블록 내에서 트랜잭션을 시작하는 명령은 `BEGIN`, `START TRANSACTION`  
하지만 블록 내에서 `BEGIN` 명령은 모두 블록의 시작으로 해석하기 때문에 결국 스토어드 프로그램 본문은 `START TRANSACTION` 사용  
스토어드 함수나 트리거에서는 트랜잭션 사용 불가  
스토어드 프로시저 내부에서 트랜잭션을 완료하면 호출하는 애플리케이션에서 트랜잭션 조절 불가  

```sql
CREATE PROCEDURE sp_hello (IN name VARCHAR(50))
BEGIN
  START TRANSACTION;
  INSERT INTO tb_hello VALUES (name, CONCAT('Hello ', name));
  COMMIT;
END ;;
```

<br>

### 변수
스토어드 프로그램의 블록 사이에서 사용하는 로컬 변수는 사용자 변수와 다름  
스토어드 프로그램에서 사용자 변수와 로컬 변수는 거의 혼용해서 제한 없이 사용 가능  
하지만 프로시저 내부에서 프리페어 스테이트먼트를 사용하려면 반드시 사용자 변수를 사용  
로컬 변수는 `DECLARE` 명령으로 정의되고 반드시 타입 명시 필수  
값 할당은 `SET` 또는 `SELECT ... INTO ...` 문장으로 가능  

```
## 로컬 변수 정의
DECLARE v_name VARCHAR(50) DEFAULT 'Matt';
DECLARE v_email VARCHAR(50) DEFAULT 'matt@email.com';

## 로컬 변수에 값 할당
SET v_name = 'Kim', v_email = 'kim@email.com';

## 결과 레코드가 정확히 1건인 쿼리만 가능
SELECT emp_no, first_name, last_name INTO v_empno, v_firstname, v_lastname
FROM employees
WHERE emp_no = 10001
LIMIT 1;
```

<br>

블록 내에서 변수명이 겹치는 경우 아래와 같은 우선순위로 탐색  
1. DECLARE 정의 로컬 변수
2. 스토어드 프로그램 입력 파라미터
3. 테이블 칼럼

```
mysql> CREATE PROCEDURE sp_hello (IN first_name VARCHAR(50))
       BEGIN
         DECLARE first_name VARCHAR(50) DEFAULT 'Kim';
         SELECT CONCAT('Hello ', first_name) FROM employees LIMIT 1;
       END ;;

mysql> CALL sp_hello('Lee');;
+-----------+
| Hello Kim |
+-----------+
```

<br>

변수가 많아 혼란스러운 경우 접두사를 사용하는 것 권장  

```sql
CREATE PROCEDURE sp_hello (IN p_first_name VARCHAR(50))
BEGIN
 DECLARE v_first_name VARCHAR(50) DEFAULT 'Kim';
 SELECT CONCAT('Hello ', first_name) FROM employees LIMIT 1;
END ;;
```

<br>

### 제어문
절차적인 처리를 위해 여러 가지 제어 문장 사용 가능  
스토어드 프로그램의 블록 내부에서만 사용 가능한 문법  

<br>

### IF ... ELSEIF ... ELSE ... END IF

```sql
CREATE FUNCTION sf_greatest(p_value1 INT, p_value2 INT)
RETURNS INT
BEGIN
  IF p_value1 IS NULL THEN
    RETURN p_value2;
  ELSEIF p_value2 IS NULL THEN
    RETURN p_value1;
  ELSEIF p_value1 >= p_value2 THEN
    RETURN p_value1;
  ELSE
    RETURN p_value2;
  END IF;
END ;;
```

<br>

### CASE WHEN ... THEN ... ELSE ... END CASE
프로그래밍 언어와 달리 `BREAK` 같은 별도의 멈춤 명령은 필요하지 않음  

```sql
CASE 변수
  WHEN 비교대상값1 THEN 처리내용1
  WHEN 비교대상값2 THEN 처리내용2
  ELSE 처리내용3
END CASE;

CASE
  WHEN 비교조건식1 THEN 처리내용1
  WHEN 비교조건식2 THEN 처리내용2
  ELSE 처리내용3
END CASE;
```

<br>

### 반복 루프
반복 루프 처리를 위해 `LOOP`, `REPEAT`, `WHILE` 구문 사용 가능  
`LOOP` 문은 반복 조건 명시 불가, `LEAVE` 명령으로 반복 종료  

```sql
## LOOP 구문
CREATE FUNCTION sf_factorial1 (p_max INT)
  RETURNS INT
BEGIN
  DECLARE v_factorial INT DEFAULT 1;

  factorial_loop : LOOP
    SET v_factorial = v_factorial * p_max;
    SET p_max = p_max - 1;
    IF p_max <= 1 THEN
      LEAVE factorial_loop;
    END IF;
  END LOOP;

  RETURN v_factorial;
END ;;

## REPEAT 구문
CREATE FUNCTION sf_factorial2 (p_max INT)
  RETURNS INT
BEGIN
  DECLARE v_factorial INT DEFAULT 1;

  REPEAT
    SET v_factorial = v_factorial * p_max;
    SET p_max = p_max - 1;
  UNTIL p_max <= 1 END REPEAT;

  RETURN v_factorial;
END ;;

## WHILE 구문
CREATE FUNCTION sf_factorial3 (p_max INT)
  RETURNS INT
BEGIN
  DECLARE v_factorial INT DEFAULT 1;

  WHILE p_max > 1 DO
    SET v_factorial = v_factorial * p_max;
    SET p_max = p_max - 1;
  END WHILE;

  RETURN v_factorial;
END ;;
```

<br>

### 핸들러와 컨디션을 이용한 에러 핸들링
이미 정의한 컨디션 또는 사용자 정의 컨디션을 어떤식으로 처리할지 정의하는 기능  
핸들러는 예외 상황뿐만 아니라 거의 모든 SQL 문장의 처리 상태에 대해 핸들러를 등록 가능  

<br>

### SQLSTATE와 에러 번호(Error No)

```
ERROR ERROR-NO (SQL-STATE): ERROR-MESSAGE
```

- `ERROR-NO`  
4자리 숫자 값으로 구성된 에러 코드, MySQL에서만 유효한 에러 식별 번호  

- `SQL-STATE`  
다섯 글자의 알파벳과 숫자로 구성, 에러뿐만 아니라 여러 가지 상태를 의미하는 코드  
이 값은 DBMS 종류가 다르더라도 ANSI SQL 표준을 준수한다면 모두 똑같은 값과 의미  
앞 2글자는 아래와 같은 의미  
  - `00`: 정상 처리됨(에러 아님)
  - `01`: 경고 메시지
  - `02`: Not found(SELECT, CURSOR 결과가 없는 경우)

- `ERROR-MESSAGE`  
포매팅된 텍스트 문장, 사람이 읽을 수 있는 형태의 에러 메시지  

<br>

| ERROR NO | SQL STATE | ERROR NAME |  DESCRIPTION |
|--|--|--|--|
| 1242 | 21000 | ER_SUBQUERY_NO_1_ROW | 레코드 1건만 반환해야하는 서브쿼리가 2건 이상 반환 |
| 1406 | 22001 | ER_DATA_TOO_LONG | sql_mode 시스템 변수에 STRIC_ALL_TABLES 설정이 있고, 칼럼의 지정된 크기보다 큰 값이 저장 |
| 1022 | 23000 | ER_DUP_KEY | 프라이머리 키 또는 유니크 키 중복(NDB 클러스터) |
| 1062 | 23000 | ER_DUP_ENTRY | 프라이머리 키 또는 유니크 키 중복(InnoDB, MyISAM) |
| 1169 | 23000 | ER_DUP_UNIQUE | 유니크 키 중복(NDB 클러스터) |
| 1061 | 42000 | ER_DUP_KEYNAME | 테이블 생성이나 변경에서 중복된 이름의 인덱스 발생 |
| 1149 | 42000 | ER_SYNTAX_ERROR | SQL 명령 문법 에러 |
| 1166 | 42000 | ER_WRONG_COLUMN_NAME | SQL 명령 문법 에러(칼럼명) |
| 1172 | 42000 | ER_TOO_MANY_ROWS | 스토어드 프로그램의 SELECT INTO 문장에서 2건 이상 레코드 반환 |
| 1203 | 42000 | RE_TOO_MANY_USER_ <br> CONNECTIONS | 접속된 커넥션이 지정된 개수보다 많은 경우 |
| 1235 | 42000 | ER_NOT_SUPPORTED_YET | 현재 버전에서 지원하지 않는 기능 사용 |
| 1046 | 42000 | ER_PARSE_ERROR | SQL 명령 문법 에러 |
| 1265 | 01000 | WARN_DATA_TRUNCATED | sql_mode 시스템 변수에 `STRIC_ALL_TABLES` 설정이 없고, 지정된 크기보다 큰 값을 저장한 경우 경고 메시지만 반환 |
| 1152 | 08S01 | ER_ABORTING_CONNECTION | 네트워크 문제로 커넥션이 비정상 종료 |
| 1058 | 21S01 | ER_WRONG_VALUE_COUNT | 칼럼의 개수와 값의 개수가 일치하지 않는 경우 |
| 1050 | 42S01 | ER_TABLE_EXISTS_ERROR | 이미 동일한 이름의 테이블이 존재하는 경우 |
| 1051 | 42S02 | ER_BAD_TABLE_ERROR | 테이블이 없는 경우(DROP 명령) |
| 1146 | 42S02 | ER_NO_SUCH_TABLE | 테이블이 없는 경우(INSERT, UPDATE, DELETE 등 명령) |
| 1109 | 42S02 | ET_UNKNOWN_TABLE | 테이블이 없는 경우(잘못된 mysqldump 명령) |
| 1060 | 42S21 | ER_DUP_FIELDNAME | 테이블 생성이나 변경에서 중복된 칼럼 발생 |
| 1028 | HY000 | ER_FILESORT_ABORT | 정렬 작업 실패 |
| 1205 | HY000 | ER_LOCK_WAIT_TIMEOUT | 레코드 잠금 대기 제한 시간 초과 |

<br>

### 핸들러
스토어드 프로그램에서는 `DECLARE ... HANDLER` 구문으로 예외 핸들링  

```sql
DECLARE handler_type HANDLER
  FOR condition_value [, condition_value] ... handler_statements
```

<br>

핸들러 타입에 따라 동작 방식 상이  
- `CONTINUE`: `handler_statements`를 실행하고 스토어드 프로그램의 마지막 실행 지점으로 돌아가 나머지 코드 처리  
- `EXIT`: `handler_statements`를 실행하고 이 핸들러가 정의된 블록을 종료  

<br>

핸들러 정의 문장의 컨디션 값(`condition_value`)에는 아래와 같이 여러 형태의 값 사용 가능  
- `SQLSTATE`  
스토어드 프로그램이 실행되는 도중 어떤 이벤트가 발생했고 해당 이벤트 상태값이 일치할때 실행되는 핸들러

- `SQLWARNING`  
스토어드 프로그램에서 코드를 실행하던 중 경고가 발생했을때 실행되는 핸들러(`SQLSTATE` 값이 `01` 시작)

- `NOT FOUUND`  
조회 쿼리 건수가 1건도 없거나 커서의 레코드를 마지막까지 일고 실행하는 핸들러(`SQLSTATE` 값이 `02` 시작)

- `SQLEXCEPTION`  
`SQLSTATE` 값이 `00`, `01`, `02`로 시작하지 않는 모든 이벤트

<br>

`handler_statements`에는 단순 명령문 또는 블록 명령문 작석 가능  

```sql
## 단순 명령문
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error_flag = 1;

## 블록 명령문
DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error occurred - terminating';
  END;

## 특정 에러 번호 핸들러
DECLARE CONTINUE HANDLER FOR 1022, 1062 SELECT 'Duplicate key in index';

## 특정 상태 핸들러
DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SELECT 'Duplicate key in index';

DECLARE CONTINUE HANDLER FOR NOT FOUND SET process_done=1;

DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET process_done=1;

DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Process terminated, Because error';
    SHOW ERRORS;
    SHOW WARNINGS;
  END;
```

<br>

### 컨디션
단순히 에러 번호나 상태 숫자값만으로 어떤 조건을 의미하는지 이해하기 어려움, 조건의 이름을 등록하는 것이 컨디션  

```sql
DECLARE condition_name CONDITION FOR condition_value
```

`condition_value`는 아래 2가지 방법으로 정의 가능
- 1개 이상의 MySQL 에러 코드
- 상태값을 사용할 때는 `SQLSTATE` 키워드 명시후 상태값 입력

<br>

### 컨디션을 사용하는 핸들러 정의
```sql
CREATE FUNCTION sf_testfunc()
  RETURNS BIGINT
BEGIN
  DECLARE dup_key CONDITION FOR 1062;
  DECLARE EXIT HANDLER FOR dup_key
    BEGIN
      RETURN -1;
    END;

  INSERT INTO tb_test VALUES (1);
  RETURN 1;
END ;;
```

<br>

### 시그널을 이용한 예외 발생
스토어드 프로그램에서 사용자가 직접 예외나 에러를 발생시키려면 시그널 명령 사용  
5.5 버전부터 시그널 기능 지원  

<br>

### 스토어드 프로그램의 BEGIN ... END 블록에서 SIGNAL 사용
시그널 명령은 에러와 경고를 모두 발생 가능, 문법상 아무런 차이 없음  

```sql
CREATE FUNCTION sf_divide (p_dividend INT, p_divisor INT)
  RETURNS INT
BEGIN
  DECLARE null_divisor CONDITION FOR SQLSTATE '45000';

  IF p_divisor IS NULL THEN
    ## null_divisor 컨디션은 반드시 SQLSTATE로 정의
    SIGNAL null_divisor
      SET MESSAGE_TEXT = 'Divisor can not be null', MYSQL_ERRNO = 9999;
  ELSEIF p_divisor = 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Divisor can not be 0', MYSQL_ERRNO = 9998;
  ELSEIF p_dividend IS NULL THEN
    SIGNAL SQLSTATE '01000'
      SET MESSAGE_TEXT = 'Dividend is null, so regarding divided as 0', MYSQL_ERRNO = 9997;
    RETURN 0;
  END IF;

  RETURN FLOOR(p_dividend / p_divisor);
END;;
```

```
mysql> SELECT sf_divide(1, NULL);
ERROR 9999 (45000): Divisor can not be null

myusql> SELECT sf_divide(1, 0);
ERROR 9998 (45000): Divisor can not be null

mysql> SELECT sf_divide(NULL, 1);
+-----------------+
| divide(NULL, 1) |
+-----------------+
|               0 |
+-----------------+
1 row in set, 1 warning (0.00 sec)

mysql> SHOW WARNINGS;
+---------+------+----------------------------------------------+
| Level   | Code | Message                                      |
+---------+------+----------------------------------------------+
| Warning | 9997 | Dividend is null, so regarding dividend as 0 |
+---------+------+----------------------------------------------+

mysql> SELECT sf_divide(0, 1);
+--------------+
| divide(0, 1) |
+--------------+
|            0 |
+--------------+
```

<br>

### 핸들러 코드에서 SIGNAL 사용
핸들러 코드에서 시그널 명령을 사용해 발생된 에러나 예외를 다른 사용자 정의 예외로 변환해서 다시 던지는 것 가능  

```sql
CREATE PROCEDURE sp_remove_user (IN p_userid INT)
BEGIN
  DECLARE v_affectedrowcount INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Can not remove user information', MYSQL_ERRNO = 9999;
    END;

  DELETE FROM tb_user WHERE user_id = p_userid;
  SELECT ROW_COUNT() INTO v_affectedrowcount;
  IF v_affectedrowcount <> 1 THEN
    SIGNAL SQLSTATE '45000';
  END IF;
END;;
```

<br>

### 커서
JDBC 프로그램에서 자주 사용하는 결과셋(`ResultSet`)  
- 스토어드 프로그램의 커서는 전방향(전진) 읽기만 가능
- 스토어드 프로그램에서는 커서의 칼럼을 바로 업데이트 불가

<br>

커서는 아래와 같이 구분 가능  
- 센서티브(`Sensitive`) 커서  
일치하는 레코드에 대한 정보를 실제 레코드의 포인터만 유지하는 형태  
칼럼의 데이터를 변경하거나 삭제하는 것 가능  
별도로 임시 테이블로 레코드를 복사하지 않기 때문에 커서 오픈이 빠름  

- 인센서티브(`Insensitive`) 커서  
일치하는 레코드를 별도의 임시 테이블로 복사해서 가지고 있는 형태  
임시 테이블로 복사하기 때문에 느리고, 칼럼의 데이터를 변경하거나 삭제하는 것 불가  

- 어센서티브(`Asensitive`) 커서  
MySQL 스토어드 프로그램에서 정의되는 커서 형식  
센서티브 커서와 인센서티브 커서를 혼용해서 사용하는 방식  

<br>

커서는 일반적인 프로그래밍 언어에서 조회 쿼리 결과를 사용하는 방법과 거의 유사  
스토어드 프로그램에서도 조회 쿼리 문장으로 커서를 정의하고 정의된 커서를 오픈하면 실제로 쿼리가 실행되고 결과를 불러옴  

```sql
CREATE FUNCTION sf_emp_count(p_dept_no VARCHAR(10))
  RETURNS BIGINT
BEGIN
  DECLARE v_total_count INT DEFAULT 0;
  DECLARE v_no_more_data TINYINT DEFAULT 0;
  DECLARE v_emp_no INTEGER;
  DECLARE v_from_date DATE;
  DECLARE v_emp_list CURSOR FOR SELECT emp_no, from_date FROM dept_emp WHERE dept_no = p_dept_no;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_data = 1;

  OPEN v_emp_list;
  REPEAT
    FETCH v_emp_list INTO v_emp_no, v_from_date;
    IF v_emp_no > 20000 THEN
      SET v_total_count = v_total_count + 1;
    END IF;
  UNTIL v_no_more_data END REPEAT;

  CLOSE v_emp_list;
  RETURN v_total_count;
END;;
```

<br>

`DECLARE` 명령으로 정의하는 순서는 반드시 아래 순서로 정의  
1. 로컬 변수와 컨디션
2. 커서
3. 핸들러

<br>
