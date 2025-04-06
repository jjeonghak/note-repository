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



























