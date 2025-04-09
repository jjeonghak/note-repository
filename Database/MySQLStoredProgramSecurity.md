# 스토어드 프로그램
MySQL에서는 절차적인 처리를 위해 스토어드 프로그램 사용 가능  
스토어드 루틴이라도고 표현하며, 스토어드 프로시저와 스토어드 함수, 트리거와 이벤트 등을 모두 아우르는 명칭  

<br>

## 스토어드 프로그램의 보안 옵션
8.0 버전부터 스토어드 프로그램의 생성 및 변경 권한이 `CREATE ROUTINE`, `ALTER ROUTINE`, `EXECUTE` 권한으로 분리  
트리거나 이벤트의 경우 `TRIGGER`, `EVENT` 권한으로 분리  

<br>

### DEFINER와 SQL SECURITY 옵션
- `DEFINER`  
스토어드 프로그램이 기본적으로 가지는 옵션, 소유권과 같은 의미  
스토어드 프로그램이 실행될 때의 권한으로 사용되기도 함  

- `SQL SECURITY`  
스토어드 프로그램을 누구의 권한으로 실행할지 결정하는 옵션  
`INVOKER` 또는 `DEFINER` 둘 중 하나로 선택 가능  
스토어드 프로시저, 스토어드 함수, 뷰만 가질수 있는 옵션  

<br>

|  | SQL SECURITY=DEFINER | SQL SECURITY=INVOKER |
|--|--|--|
| 기준 권한 | 정의자 | 호출자 |
| 용도 | 권한이 부족한 사용자가 특정 작업을 가능하게 하고 싶은 경우 | 호출자 권한 검사가 필요한 경우 |
| 위험 요소 | 권한 상승 가능 | 접근 제어 엄격 |
| 보안 제어 | 프로시저 외부에서 제어 필요 | 자연스럽게 권한 기반 제어 |

<br>

### DETERMINISTIC과 NOT DETERMINISTIC 옵션
스토어드 프로그램의 보안이 아닌 성능과 관련된 옵션  
두 옵션은 배타적이라서 둘 중 하나를 반드시 선택 필수  

- `DETERMINISTIC`  
입력이 같다면 시점이나 상황에 관계없이 결과가 항상 같은 순수 함수  

- `NOT DETERMINISTIC`  
입력이 같아도 시점에 따라 결과가 상이  

<br>

일반적으로 일회성으로 실행되는 스토어드 프로시저는 해당 옵션의 영향을 거의 받지 않음  
하지만 반복적으로 호출 가능한 스토어드 함수는 쿼리 성능에도 영향을 받음  
기본값인 `NOT DETERMINISTIC` 옵션은 호출되는 시점에 따라 값이 달라지기 때문에 조건절에 사용시 지속적으로 호출  


```
mysql> CREATE FUNCTION sf_getdate1()
  RETURNS DATETIME
  NOT DETERMINISTIC
BEGIN
  RETURN NOW();
END ;;

mysql> CREATE FUNCTION sf_getdate2()
  RETURNS DATETIME
  DETERMINISTIC
BEGIN
  RETURN NOW();
END ;;

mysql> EXPLAIN SELECT * FROM dept_emp WHERE from_date > sf_getdate1();
+----+-------------+----------+------+------+---------+--------+-------------+
| id | select_type | table    | type | key  | key_len | rows   | Extra       |
+----+-------------+----------+------+------+---------+--------+-------------+
|  1 | SIMPLE      | dept_emp | ALL  | NULL | NULL    | 331143 | Using where |
+----+-------------+----------+------+------+---------+--------+-------------+

mysql> EXPLAIN SELECT * FROM dept_emp WHERE from_date > sf_getdate2();
+----+-------------+----------+-------+-------------+---------+------+-------------+
| id | select_type | table    | type  | key         | key_len | rows | Extra       |
+----+-------------+----------+-------+-------------+---------+------+-------------+
|  1 | SIMPLE      | dept_emp | range | ix_fromdate |       3 |    1 | Using where |
+----+-------------+----------+-------+-------------+---------+------+-------------+
```

<br>

## 스토어드 프로그램의 참고 및 주의사항

### 한글 처리
스토어드 프로그램 소스코드 자체에 한글 문자열 값이 사용되지 않는다면 상관없음  
소스코드 내부에 한글 문자열 값을 사용하는 경우 클라이언트 프로그램이 어떤 문자 집합으로 접속되어 있는지가 중요  
기본적으로 `client`, `connection` 시스템 변수값은 `latin1`으로 설정, 영어권 알파벳을 위한 문자 집합이라 한글 미포함  

```
mysql> SHOW VARIABLES LIKE 'character%';
+--------------------------+---------+
| Variable_name            | Value   |
+--------------------------+---------+
| character_set_client     | latin1  |
| character_set_connection | latin1  |
| character_set_database   | utf8mb4 |
| character_set_filesystem | binary  |
| character_set_results    | latin1  |
| character_set_server     | utf8mb4 |
| character_set_system     | utf8mb4 |
+--------------------------+---------+

-- // 직접 하나씩 변경
mysql> SET character_set_client = 'utf8mb4';
mysql> SET character_set_results = 'utf8mb4';
mysql> SET character_set_connection = 'utf8mb4';

-- // 한번에 변경
mysql> SET NAMES utf8mb4;
```

<br>

일반적인 클라언트 도구는 한동안 사용하지 않으면 커넥션이 끊어진 상태로 대기, 쿼리 실행시 재생성  
`SET NAMES utf8mb4` 명령은 재접속하는 경우 효과가 없음  
`CHARSET utf8mb4` 명령을 사용하는 것 권장, 이 명령도 서버 종료시 초기화  
또한 파라미터로 넘겨받는 값에 대해서도 문자 집합을 별도로 지정  

```sql
CREATE FUNCTION sf_getstring()
  RETURNS VARCHAR(20) CHARACTER SET utf8mb4
BEGIN
  RETURN '한글 테스트';
END ;;
```

<br>

### 스토어드 프로그램과 세션 변수
스토어드 프로그램 내에서 `@`로 시작하는 사용자 변수 사용 가능  
로컬 변수를 정의할 때는 정확한 타입과 길이 명시가 필수 이지만 사용자 변수는 이런 제약 없음  
사용자 변수는 데이터 타입에 대해 안전하지 않고, 영향을 미치는 범위가 넓음  
커넥션에서 계속 그 값이 유지한 채 남아 있기 때문에 사용하기 전에 적절한 값으로 초기화 필수  

```
mysql> CREATE FUNCTION sf_getsum(p_arg1 INT, p_arg2 INT)
         RETURNS INT
       BEGIN
         DECLARE v_sum INT DEFAULT 0;
         SET v_sum = p_arg1 + p_arg2;
         SET @v_sum = v_sum;
         RETURN v_sum;
       END ;;

mysql> SELECT sf_getsum(1, 2);;
+------+
|    3 |
+------+

mysql> SELECT @v_sum;;
+------+
|    3 |
+------+
```

<br>

### 스토어드 프로시저와 재귀 호출
스토어드 프로시저에서만 재귀 호출 사용 가능  
`max_sp_recursion_depth` 시스템 변수값의 기본값이 0이기 때문에 이 값을 설정해야 사용 가능  

```
ERROR 1456 (HY000): Recursive limit 0 (as set by the max_sp_recursion_depth variable) was
exceeded for routine decreaseAndSum
```

<br>

```sql
mysql> CREATE PROCEDURE sp_getfactorial(IN p_max INT, OUT p_sum INT)
       BEGIN
         SET max_sp_recursion_depth = 50;
         SET p_sum = 1;

         IF p_max > 1 THEN
           CALL sp_decreaseandmultiply(p_max, p_sum);
         END IF;
       END ;;

mysql> CREATE PROCEDURE sp_decreaseandmultiply(IN p_current INT, INOUT p_sum INT)
       BEGIN
         SET p_sum = p_sum * p_current;
         IF p_current > 1 THEN
           CALL sp_decreaseandmultiply(p_current - 1, p_sum);
         END IF;
       END ;;

mysql> CALL sp_getfactorial(10, @factorial);;
mysql> SELECT @factorial;;
+------------+
| @factorial |
+------------+
|        120 |
+------------+
```

<br>

### 중첩된 커서 사용
일반적으로 하나의 커서를 열고 사용한 후 닫고 다시 새로운 커서를 열어서 사용하는 형태도 많이 사용  
중첩된 루프 안에서 두개의 커서를 동시에 열어서 사용해야 하는 경우도 발생  
스토어드 프로시저 코드의 처리 중 발생한 에러나 예외는 항상 가장 가까운 블룩에 정의된 핸들러 사용  

```sql
CREATE PROCEDURE sp_updateemployeehiredate()
BEGIN
  DECLARE v_dept_no CHAR(4);
  DECLARE v_no_more_depts BOOLEAN DEFAULT FALSE;
  DECLARE v_dept_list CURSOR FOR SELECT dept_no FROM departments;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_depts := TRUE;

  OPEN v_dept_list;
  LOOP_OUTER: LOOP
    FETCH v_dept_list INTO v_dept_no;
    IF v_no_more_depts THEN
      CLOSE v_dept_list;
      LEAVE loop_outer;
    END IF;

    BLOCK_INNER: BEGIN
      DECLARE v_emp_no INT;
      DECLARE v_no_more_employees BOOLEAN DEFAULT FALSE;
      DECLARE v_emp_list CURSOR FOR SELECT emp_no FROM dept_emp WHERE dept_no = v_dept_no LIMIT 1;
      DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_employees := TRUE;

      OPEN v_emp_list;
      LOOP_INNER: LOOP
        FETCH v_emp_list INTO v_emp_no;
        IF v_no_more_employees THEN
          CLOSE v_emp_list;
          LEAVE loop_inner;
        END IF;
      END LOOP loop_inner;
    END block_inner;
  END LOOP loop_outer;
END ;;
```

<br>
