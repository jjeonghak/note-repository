# SELECT
상대적으로 INSERT, UPDATE 같은 작업은 거의 레코드 단위로 발생하기 때문에 성능상 문제가 되는 경우 적음  
하지만 SELECT 작업은 여러개의 테이블로부터 데이터를 조합해서 빠르게 가져와야 하기 때문에 주의 필수  

<br>

## SELECT 절의 처리 순서

```sql
SELECT s.emp_no, COUNT(DISTINCT e.first_name) AS cnt
FROM salaries s
  INNER JOIN employees e ON e.emp_no = s.emp_no
WHERE s.emp_no IN (100001, 100002)
GROUP BY s.emp_no
HAVING AVG(s.salary) > 1000
ORDER BY AVG(s.salary)
LIMIT 10;
```

<br>

<img width="600" alt="queryexecutionorder" src="https://github.com/user-attachments/assets/804e624a-445d-49d6-a918-51a0040406cc" />

<img width="600" alt="queryexecutionorder2" src="https://github.com/user-attachments/assets/0734c322-4436-4cdd-bb3c-2bdf5d965a4a" />

각 요소가 없는 경우는 가능하지만, 이 순서가 바뀌는 경우는 거의 없음  
인덱스를 이용해 처리할 때는 어떤 단계 자체가 불필요한 경우 생략  

<br>

```sql
SELECT emp_no, cnt
FROM (
      SELECT s.emp_no, COUNT(DISTINCT e.first_name) AS cnt, MAX(s.salary) AS max_salary
      FROM salaries s
        INNER JOIN employees e ON e.emp_no = s.emp_no
      WHERE s.emp_no IN (100001, 100002)
      GROUP BY s.emp_no
      HAVING MAX(s.salary) > 1000
      LIMIT 10
    ) temp_view
ORDER BY max_dalary;
```

만약 위의 실행 순서를 벗어나는 쿼리가 필요한 경우 서브쿼리로 작성된 인라인 뷰(`Inline View`) 사용  
LIMIT을 GROUP BY 전에 실행하고자 할때도 마찬가지로 서브쿼리 인라인 뷰로 먼저 적용  
인라인 뷰가 사용되면 임시 테이블이 사용되기 때문에 주의 필요  

<br>

## WHERE 절과 GROUP BY 절, ORDER BY 절의 인덱스 사용
WHERE 절의 조건뿐만 아니라 GROUP BY, ORDER BY 절도 인덱스를 이용한 빠른 처리 가능  

<br>

### 인덱스를 사용하기 위한 기본 규칙
기본적으로 인덱스를 사용하려면 인덱싱 칼럼값 자체를 변환하지 않고 그대로 사용한다는 조건 필요  
인덱싱 칼럼값을 가공한 후 조건을 사용하면 인덱스를 적절히 이용하지 못함  

```sql
SELECT * FROM salaries WHERE salary * 10 > 150000;
SELECT * FROM salaries WHERE salary > 15000;
```

<br>

만약 복잡한 연산을 수행하고 비교해야하는 경우 미리 계산된 값을 저장하도록 가상 칼럼 추가  
그 칼럼에 인덱스를 생성하거나 함수 기반 인덱스를 사용  
또한 비교 조건에서 연산자 양쪽의 두 비교 대상값은 데이터 타입이 일치해야함  

<br>

### WHERE 절의 인덱스 사용
작업 범위 결정 조건과 체크 조건 두가지 방식으로 구분  
8.0 이전 버전까지는 하나의 인덱스를 구성하는 복합 칼럼의 정렬 순서 혼합 불가  

```sql
ALTER TABLE ... ADD INDEX ix_col1234 (col_1 ASC, col_2 DESC, col_3 ASC, col_4 ASC);
```

<br>

OR 연산자를 사용한 경우 AND 연산자와 다른 처리  
각각의 조건이 인덱스 사용 가능 여부가 상이한 경우 옵티마이저는 풀 테이블 스캔을 선택  
만약 모두 인덱스 사용 가능하다면 `index_merge` 접근 방식 실행  

```sql
SELECT * FROM employees WHERE first_name = 'Kebin' OR last_name = 'Poly';
```

<br>

### GROUP BY 절의 인덱스 사용
GROUP BY 절의 각 칼럼은 비교 연산자를 가지지 않으므로 작업 범위 조건이나 체크 조건과 같이 구분할 필요 없음  
GROUP BY 절에 명시된 칼럼 순서가 인덱스를 구성하는 칼럼의 순서와 같다면 인덱스 사용 가능  

<br>

<img width="500" alt="groupbyindexrule" src="https://github.com/user-attachments/assets/b6f44e9f-b9b7-4a83-80e6-3289e71e480b" />

- GROUP BY 절에 명시된 칼럼이 인덱스 칼럼의 순서와 위치가 같아야함
- 인덱스를 구성하는 칼럼 중 뒤쪽에 있는 칼럼은 GROUP BY 절에 명시되지 않아도 되지만 앞쪽 칼럼을 필수
- GROUP BY 절에 명시된 칼럼이 하나라도 인덱스에 없으면 인덱스 사용 불가

<br>

만약 GROUP BY 절에 명시되지 않은 앞쪽 칼럼이 조건절의 동등 비교 조건으로 사용된 경우는 인덱스 사용 가능  

```sql
... WHERE col_1 = 'cost' ... GROUP BY col_2, col_3;
... WHERE col_1 = 'cost' AND col_2 = 'const' ... GROUP BY col_3, col_4;
... WHERE col_1 = 'cost' AND col_2 = 'const' AND col_3 = 'const' ... GROUP BY col_4;
```

<br>

WHERE 절과 GROUP BY 절이 혼용된 쿼리가 인덱스 처리가 가능한지는 조건절에서 동등 조건으로 사용된 칼럼을 보고 판단  

```sql
## 원본 쿼리
... WHERE col_1 = 'const' ... GROUP BY col_2, col_3;

## 조건절 동등 조건 칼럼을 그룹핑에 포함시켜본 쿼리
... WHERE col_1 = 'const' ... GROUP BY col_1, col_2, col_3;
```

<br>

### ORDER BY 절의 인덱스 사용

<img width="450" alt="orderbyindexrule" src="https://github.com/user-attachments/assets/c3216cb0-f7fc-4d4c-a51f-633966574377" />

GROUP BY 절의 요건과 거의 흡사  
추가로 정렬되는 각 칼럼의 오름차순/내림차순 옵션이 인덱스와 같거나 아예 반대인 경우에만 사용 가능  

<br>

아래 인덱스에서는 ORDER BY 절이 인덱스 사용 불가  

```sql
... ORDER BY col_2, col_3;
... ORDER BY col_1, col_3, col_2;
... ORDER BY col_1, col_2 DESC, col_3;
... ORDER BY col_1, col_3;
... ORDER BY col_1, col_2, col_3, col_4, col_5;
```

- 첫번째는 인덱스 제일 앞쪽 칼럼이 명시되지 않음
- 두번째는 칼럼 순서가 일치하지 않음
- 세번째는 다른 칼럼은 모두 인덱스와 같은 정렬이지만 두번째 칼럼이 반대 정렬
- 네번째는 앞쪽 칼럼이 모두 명시되지 않고 뒤쪽 칼럼이 명시
- 다섯번째는 인덱스에 존재하지 않는 칼럼 사용

<br>

### WHERE 조건과 ORDER BY(또는 GROUP BY) 절의 인덱스 사용
SQL 문장이 WHERE, ORDER BY 절을 모두 가지고 있어도 여러 인덱스를 사용 불가  
- WHERE 절과 ORDER BY 절이 동시에 같은 인젣스 이용  
조건절 칼럼과 정렬 대상 칼럼이 모두 하나의 인덱스에 연속해서 포함된 경우  

- WHERE 절만 인덱스 이용  
ORDER BY 절은 인덱스를 이용한 정렬이 불가능한 경우  
인덱스를 통해 검색된 결과 레코드를 별도의 정렬 처리 과정(`Using Filesort`)을 거쳐 정렬 수행  

- ORDER BY 절만 인덱스 이용  
조건절이 인덱스를 이용하지 못하는 경우  
인덱스를 하나씩 읽으먄서 한 건씩 조건 일치 비교  

<br>

### GROUP BY 절과 ORDER BY 절의 인덱스 사용
5.7 버전까지는 GROUP BY 절은 정렬까지 함께 수행하는 것이 기본 동작 방식  
8.0 버전부터 정렬을 보장하지 않는 형태로 변경  
GROUP BY, ORDER BY 절이 동시에 사용된 쿼리에서 하나의 인덱스를 사용하려면 명시된 칼럼의 순서와 내용이 모두 같아야 가능  
만약 둘 중 하나라도 인덱스를 사용할 수 없다면, 결과적으로 아예 인덱스를 사용 불가  

<br>

### WHERE 조건과 ORDER BY 절, GROUP BY 절의 인덱스 사용

<img width="550" alt="index" src="https://github.com/user-attachments/assets/b0e82e1a-d1dd-4f08-9c83-c31798b35d7c" />

WHERE, GROUP BY, ORDER BY 절이 모두 포함된 쿼리가 인덱스를 판단하는 방법  

<br>

## WHERE 절의 비교 조건 사용 시 주의사항

### NULL 비교
다른 DBMS와는 다르게 NULL 값이 포함된 레코드도 인덱스로 관리  
이는 인덱스에서는 NULL을 하나의 값으로 인정해서 관리한다는 것을 의미  
NULL 비교 방식이 조금 상이한 부분 존재  

```
mysql> SELECT NULL = NULL;
+-----------+
|      NULL |
+-----------+

mysql> SELECT NULL <=> NULL;
+-----------+
|         1 |
+-----------+

mysql> SELECT CASE WHEN NULL = NULL THEN 1 ELSE 0 END;
+-----------+
|         0 |
+-----------+

mysql> SELECT CASE WHEN NULL IS NULL THEN 1 ELSE 0 END;
+-----------+
|         1 |
+-----------+
```

<br>

NULL 값이 인덱스로 관리되기 때문에 NULL 비교도 인덱스 사용 가능  
ISNULL() 함수보다는 IS NULL 연산자 사용 권장  

```
mysql> EXPLAIN SELECT * FROM titles WHERE to_date IS NULL;
+----+--------+------+-----------+--------------------------+
| id | table  | type | key       | Extra                    |
+----+--------+------+-----------+--------------------------+
|  1 | titles | ref  | ix_todate | Using where; Using index |
+----+--------+------+-----------+--------------------------+

-- // 인덱스 레인지 스캔
mysql> SELECT * FROM titles WHERE to_date IS NULL;
mysql> SELECT * FROM titles WHERE ISNULL(to_date);

-- // 인덱스 또는 테이블 풀 스캔
mysql> SELECT * FROM titles WHERE ISNULL(to_date) = 1;
mysql> SELECT * FROM titles WHERE ISNULL(to_date) = true;
```

<br>

### 문자열이나 숫자 비교
칼럼 비교를 할때는 반드시 그 타입에 맞는 상수값을 사용 권장  
문자열과 숫자 비교에는 숫자가 우선순위를 가짐(문자열을 숫자로 변환)  

```
mysql> EXPLAIN SELECT * FROM employees WHERE first_name = 10001;
+----+-----------+------+------+--------+-------------+
| id | table     | type | key  | rows   | Extra       |
+----+-----------+------+------+--------+-------------+
|  1 | employees | ALL  | NULL | 299920 | Using where |
+----+-----------+------+------+--------+-------------+
```

<br>

### 날짜 비교
날짜만 저장하는 DATE, 시간만 저장하는 TIME, 모두 저장하는 DATETIME, TIMESTAMP 타입 존재  

<br>

### DATE 또는 DATETIME과 문자열 비교
문자열과 날짜 비교를 하는 경우 DATETIME 타입의 값으로 변환해서 비교 수행  

```sql
## 인덱스 사용 가능
SELECT COUNT(*) FROM employees WHERE hire_date > STR_TO_DATE('2011-07-23', '%Y-%m-%d');
SELECT COUNT(*) FROM employees WHERE hire_date > '2011-07-23';
SELECT COUNT(*) FROM employees WHERE hire_date > DATE_SUB('2011-07-23', INTERVAL 1 YEAR);

## 인덱스 사용 불가
SELECT COUNT(*) FROM employees WHERE DATE_FORMAT(hire_date, '%Y-%m-%d') > '2011-07-23';
SELECT COUNT(*) FROM employees WHERE DATE_ADD(hire_date, INTERVAL 1 YEAR) > '2011-07-23';
```

<br>

### DATE와 DATETIME의 비교
DATETIME 값에서 시간 부분만 버리고 비교하려면 DATE() 함수 사용  
DATE와 DATETIME 비교시 DATETIME 타입의 우선순위가 더 높아서 DATE를 DATETIME으로 변환  
해당 변환은 인덱스 사용 여부에 영향을 미치지 않음  

```sql
SELECT COUNT(*) FROM employees WHERE hire_daate > DATE(NOW());
SELECT STR_TO_DATE('2011-06-30', '%Y-%m-%d') < STR_TO_DATE('2011-06-30 00:00:01', '%Y-%m-%d %H:%i:%s');
```

<br>

### DATETIME과 TIMESTAMP의 비교
타입 변환 없이 비교하면 문제없이 작동하고 실제 실행계획에도 인덱스 레인지 스캔을 사용하는 것처럼 보이지만 사실은 그렇지 않음  
TIMESTAMP 비교를 원한다면 UNIX_TIMESTAMP() 함수, DATETIME 비교를 원한다면 FROM_UNIXTIME() 함수 사용  

```
mysql> SELECT COUNT(*) FROM employees WHERE hire_date < '2011-07-23 11:10:12';
+----------+
| COUNT(*) |
+----------+
|   300024 |
+----------+

mysql> SELECT COUNT(*) FROM employees WHERE hire_date > UNIX_TIMESTAMP('1986-01-01 00:00:00');
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
1 row in set, 2 warnings (0.04 sec)

mysql> SHOW WARNINGS;
+---------+------+-------------------------------------------------------------------+
| Level   | Code | Message                                                           |
+---------+------+-------------------------------------------------------------------+
| Warning | 1292 | Incorrect date value: '504889200' for column 'hire_date' at row 1 |
| Warning | 1292 | Incorrect date value: '504889200' for column 'hire_date' at row 1 |
+---------+------+-------------------------------------------------------------------+
```

```sql
SELECT COUNT(*) FROM employees WHERE hire_date < FROM_UNIXTIME(UNIX_TIMESTTAMP());
SELECT COUNT(*) FROM employees WHERE hire_date < NOW();
```

<br>

### Short-Circuit Evaluation
여러 표현식이 논리 연산자로 연결된 경우 선행 표현식의 결과에 따라 후행 표현식을 평가할지 말지 결정하는 최적화  

```
-- // 1번 조건
mysql> SELECT COUNT(*) FROM salaries
       WHERE CONVERT_TZ(from_date, '+00:00', '+09:00') > '1991-01-01';
+----------+
| COUNT(*) |
+----------+
|  2442943 |
+----------+

-- // 2번 조건
mysql> SELECT COUNT(*) FROM salaries
       WHERE to_date < '1985-01-01';
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+

mysql> SELECT * FROM salaries
       WHERE CONVERT_TZ(from_date, '+00:00', '+09:00') > '1991-01-01'   /* 1번 조건 */
         AND to_date < '1985-01-1';                                     /* 2번 조건 */
==> (0.73 sec)

mysql> SELECT * FROM salaries
       WHERE to_date < '1985-01-1'                                      /* 2번 조건 */
         AND CONVERT_TZ(from_date, '+00:00', '+09:00') > '1991-01-01';  /* 1번 조건 */
==> (0.52 sec)
```

<br>

만약 조건 중에 인덱스를 사용할 수 있는 조건이 있다면 해당 최적화와 무관하게 그 조건을 최우선으로 사용  

```
mysql> FLUSH STATUS;
mysql> SELECT *
       FROM employees e
       WHERE e.first_name = 'Matt'
         AND e.last_name = 'Aamodt'
         AND EXISTS (SELECT 1 FROM salaries s
                     WHERE s.emp_no = e.emp_no AND s.to_date > '1995-01-01'
                     GROUP BY s.salary HAVING COUNT(*) > 1);

mysql> SHOW STATUS LIKE 'Handler%';
+-----------------------+-------+
| Variable_name         | Value |
+-----------------------+-------+
| Handler_read_key      | 9     |
| Handler_read_next     | 247   |
| Handler_read_rnd_next | 8     |
| Handler_write         | 7     |
+-----------------------+-------+

mysql> FLUSH STATUS;
mysql> SELECT *
       FROM employees e
       WHERE e.first_name = 'Matt'
         AND EXISTS (SELECT 1 FROM salaries s
                     WHERE s.emp_no = e.emp_no AND s.to_date > '1995-01-01'
                     GROUP BY s.salary HAVING COUNT(*) > 1)
         AND e.last_name = 'Aamodt';

mysql> SHOW STATUS LIKE 'Handler%';
+-----------------------+-------+
| Variable_name         | Value |
+-----------------------+-------+
| Handler_read_key      | 1807  |
| Handler_read_next     | 2454  |
| Handler_read_rnd_next | 1806  |
| Handler_write         | 1573  |
+-----------------------+-------+
```

<br>

## LIMIT n
LIMIT 절은 쿼리 결과에서 지정된 순서에 위치한 레코드만 가져오고자 할때 사용  

```sql
SELECT * FROM employees
WHERE emp_no BETWEEN 10001 AND 10010
ORDER BY first_name
LIMIT 0, 5;
```

1. 테이블에서 조건절의 검색 조건에 일치하는 레코드를 전부 조회
2. 1번 과정에서 일어온 레코드를 ORDER BY 절의 칼럼에 따라 정렬
3. 정렬된 결과에서 LIMIT 절의 offset과 n에 따라 사용자에게 결과 반환

<br>

LIMIT은 조건절이 아니기 때문에 항상 쿼리 마지막에 실행  
필요한 레코드 건수만 준비되면 즉시 쿼리를 종료  

```sql
## 풀 테이블 스캔이지만 10개의 레코드 조회 후 바로 쿼리 종료
SELECT * FROM employees LIMIT 0, 10;

## 그루핑 작업 후 LIMIT 처리
SELECT first_name FROM employees GROUP BY first_name LIMIT 0, 10;

## 풀 테이블 스캔으로 중복 제거 작업 진행, 10개의 유니크한 레코드 조회 후 바로 쿼리 종료
SELECT DISTINCT first_name FROM employees LIMIT 0, 10;

## 조건절에 일치하는 레코드를 읽은 후 정렬 수행, 정렬 수행하면서 10개의 레코드 조회 후 바로 쿼리 종료
SELECT * FROM employees WHERE emp_no BETWEEN 10001 AND 11000 ORDER BY first_name LIMIT 0, 10;
```

<br>

제한 사항으로 인자는 표현식이나 별도의 서브쿼리 사용 불가  
실제 쿼리 성능은 사용자 화면에 레코드가 얼마나 출력되느냐보단 그 결과를 만들기 위해 어떠한 작업을 했는지가 더 중요  

```
mysql> SELECT * FROM employees LIMIT(100 - 10);
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to
your MySQL server version for the right syntax to use near '(100 - 10)' at line 1

mysql> SELECT * FROM salaries ORDER BY salary LIMIT 0, 10;
10 rows in set (0.00 sec)

mysql> SELECT * FROM salaries ORDER BY salary LIMIT 2000000, 10;
10 rows in set (1.57 sec)
```

<br>

LIMIT 조건의 페이징이 처음 몇개 페이지 조회가 아니라면 조건절로 읽어야할 위치를 탐색하는 것이 효율적  

```
mysql> SELECT * FROM salaries ORDER BY salary LIMIT 0, 10;
10 rows in set (0.01 sec)

mysql> SELECT * FROM salaries
       WHERE salary >= 38864 AND NOT (salary = 38864 AND emp_no <= 274049)
       ORDER BY salary LIMIT 0, 10;
10 rows in set (0.01 sec)

mysql> SELECT * FROM salaries
       WHERE salary >= 154888 AND NOT (salary = 154888 AND emp_no <= 109334)
       ORDER BY salary LIMIT 0, 10;
7 rows in set (0.01 sec)
```

<br>

## COUNT()
결과 레코드의 건수를 반환하는 함수  
MyISAM 스토리지 엔진은 항상 테이블의 메타 정보에 전체 레코드 건수를 관리  
조건절 없는 `COUNT(*)` 쿼리는 실제 레코드를 확인하지 않고 반환  
InnoDB 스토리지 엔진은 조건절 없는 `COUNT(*)` 쿼리도 직접 데이터나 인덱스 조회  
대략적인 레코드 건수로 충분하다면 `SHOW TABLE STATUS` 명령으로 통계 정보를 참조하는 것 권장  
만약 실제 테이블과 많은 차이가 난다면 `ANALYZE TABLE` 명령을 통해 갱신  

```
mysql> SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_ROWS,
              (DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024 / 1024 AS TABLE_SIZE_GB
       FROM information_schema.TABLES
       WHERE TABLE_SCHEMA = 'employees' AND TABLE_NAME = 'employees';
+--------------+------------+------------+----------------+
| TABLE_SCHEMA | TABLE_NAME | TABLE_ROWS | TABLE_SIZE_GB  |
+--------------+------------+------------+----------------+
| employees    | employees  |     299960 | 0.030334472656 |
+--------------+------------+------------+----------------+
```

<br>

COUNT 쿼리에서 가장 많이 하는 실수는 ORDER BY 절이나 LEFT JOIN 같은 레코드 건수와 무관한 작업을 포함시키는 것  
거의 페이징을 위해 사용할때 쿼리를 그대로 복사해서 칼럼이 명시된 부분만 삭제하고 그 부분만 COUNT 함수로 대체  
8.0 버전부터는 COUNT 쿼리에 사용된 ORDER BY 절은 옵티마이저가 무시하도록 개선  

<br>

## JOIN

### JOIN 순서와 인덱스
인덱스 레인지 스캔은 인덱스를 탐색하는 단계(`Index Seek`)와 인덱스를 스캔(`Index Scan`)하는 과정으로 구분  
일반적으로 인덱스를 이용하는 쿼리는 가져오는 레코드 건수가 소량이라 스캔 작업은 부하가 적지만 탐색 작업은 상대적으로 높음  

조인 작업에서 드라이빙 테이블을 읽을 때는 인덱스 탐색 작업을 단 한번 수행하고, 이후는 스캔만 실행  
하지만 드리븐 테이블에서는 인덱스 탐색 작업과 스캔 작업을 드라이빙 테이블에서 읽은 레코드 건수만큼 반복  
옵티마이저는 항상 드라이빙 테이블이 아니라 드리븐 테이블을 최적으로 읽을 수 있게 실행 계획을 수립  

<br>

```sql
SELECT *
FROM employees e, dept_emp de
WHERE e.emp_no = de.emp_no;
```

- 두 칼럼 모두 인덱스가 있는 경우  
어느 테이블을 드라이빙으로 선택하든 빠른 검색 작업 가능  
보통 통계 정보에 있는 레코드 건수에 따라 옵티마이저가 최적 선택  

- 한 칼럼만 인덱스가 있는 경우  
인덱스가 없는 테이블을 드라이빙 테이블로 선택  
만약 인덱스가 없는 테이블이 드리븐 테이블이 된다면, 드라이빙 테이블 레코드 건수만큼 드리븐 테이블 풀 스캔 발생  

- 두 칼럼 모두 인덱스가 없는 경우  
어떤 테이블을 선택해도 드리븐 테이블의 풀 스캔 발생
레코드 건수가 적은 테이블을 드라이빙 테이블로 선택하는 것이 효율적  

<br>

### JOIN 칼럼의 데이터 타입
테이블 조인 조건도 WHERE 절과 마찬가지로 비교 대상 칼럼과 표현식 데이터 타입이 반드시 동일  

```
mysql> CREATE TABLE tb_test1 (user_id INT, user_type INT, PRIMARY KEY(user_id));
mysql> CREATE TABLE tb_test2 (user_type CHAR(1), type_desc VARCHAR(10), PRIMARY KEY(user_type));
mysql> EXPLAIN
         SELECT *
         FROM tb_test1 tb1, tb_test2 tb2
         WHERE tb1.user_type = tb2.user_type;
+----+-------+------+------+--------------------------------------------+
| id | table | type | key  | Extra                                      |
+----+-------+------+------+--------------------------------------------+
|  1 | tb1   | ALL  | NULL | NULL                                       |
|  1 | tb2   | ALL  | NULL | Using where; Using join buffer (hash join) |
+----+-------+------+------+--------------------------------------------+
```

- CHAR 타입과 INT 타입의 비교와 같이 데이터 타입의 종류가 완전히 다른 경우
- 같은 CHAR 타입이더라도 문자 집합이나 콜레이션이 다른 경우
- 같은 INT 타입이더라도 부호의 존재 여부가 다른 경우

<br>

### OUTER JOIN의 성능과 주의사항
이너 조인은 조인 대상 테이블에 모두 존재하는 레코드만 결과 집합으로 반환  
그렇기 때문에 이너 조인으로 처리 가능하지만, 아우터 조인 실행 쿼리들을 자주 사용  
옵티마이저는 절대 아우터 조인 테이블을 드라이빙 테이블로 선택하지 못함  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
           LEFT JOIN dept_emp de ON de.emp_no = e.emp_no
           LEFT JOIN departments d ON d.dept_no = de.dept_no AND d.dept_name = 'Development';
+----+-------+--------+-------------------+--------+-------------+
| id | table | type   | key               | rows   | Extra       |
+----+-------+--------+-------------------+--------+-------------+
|  1 | e     | ALL    | NULL              | 299920 | NULL        |
|  1 | de    | ref    | ix_empno_fromdate |      1 | NULL        |
|  1 | d     | eq_ref | PRIMARY           |      1 | Using where |
+----+-------+--------+-------------------+--------+-------------+

mysql> EXPLAIN
         SELECT *
         FROM employees e
           INNER JOIN dept_emp de ON de.emp_no = e.emp_no
           INNER JOIN departments d ON d.dept_no = de.dept_no AND d.dept_name = 'Development';
+----+-------+--------+-------------+-------+-------------+
| id | table | type   | key         | rows  | Extra       |
+----+-------+--------+-------------+-------+-------------+
|  1 | d     | ref    | ux_deptname |     1 | Using index |
|  1 | de    | ref    | PRIMARY     | 41392 | NULL        |
|  1 | e     | eq_ref | PRIMARY     |     1 | NULL        |
+----+-------+--------+-------------+-------+-------------+
```

<br>

또한 아우터 조인 테이블에 대한 조건을 WHERE 절에 명시하는 것도 잘못된 방법  
내부적으로 해당 경우 LEFT JOIN을 INNER JOIN으로 자동 변환  
아우터로 조인된 칼럼이 NULL인 레코드들만 조회하는 안티 조인 형식이 아니라면 사용하지 않는 것 권장  

```sql
## 기존 아우터 조인 쿼리
SELECT *
FROM employees e
  LEFT JOIN dept_manager mgr ON mgr.emp_no = e.emp_no
WHERE mgr.dept_no = 'd001';

## WHERE 절 조건으로 인해 내부적으로 이너 조인으로 변환
SELECT *
FROM employees e
  INNER JOIN dept_manager mgr ON mgr.emp_no = e.emp_no
WHERE mgr.dept_no = 'd001';

## 정상적인 아우터 조인 쿼리
SELECT *
FROM employees e
  LEFT JOIN dept_manager mgr ON mgr.emp_no = e.emp_no AND mgr.dept_no = 'd001';

## 안티 조인 효과를 기대하기 위한 WHERE 절 조건 사용 쿼리
SELECT *
FROM employees e
  LEFT JOIN dept_manager dm ON dm.emp_no = e.emp_no
WHERE dm.emp_no IS NULL
LIMIT 10;
```

<br>

### JOIN과 외래키(FOREIGN KEY)
외래키는 조인과 아무런 연관이 없고, 외래키의 주목적은 데이터의 무결성을 보장하기 위함  
테이블 간의 조인을 수행하는 것은 전혀 문관한 칼럼을 조인 조건으로 사용해도 문법적으로 문제 없음  

<br>

### 지연된 조인(Delayed Join)
조인 쿼리에 GROUP BY 또는 ORDER BY를 사용할 때 각 처리방법에서 인덱스를 사용한다면 이미 최적으로 처리되고 있을 가능성 높음  
아니라면 우선 모든 조인을 수행하고 난 후 정렬, 그루핑 처리  

```
mysql> EXPLAIN
         SELECT e.*
         FROM salaries s, employees e
         WHERE e.emp_no = s.emp_no
           AND s.emp_no BETWEEB 10001 AND 13000
         GROUP BY s.emp_no
         ORDER BY SUM(s.salary) DESC
         LIMIT 10;
+----+-------+-------+---------+------+----------------------------------------------+
| id | table | type  | key     | rows | Extra                                        |
+----+-------+-------+---------+------+----------------------------------------------+
|  1 | e     | range | PRIMARY | 3000 | Using where; Using temporary; Using filesort |
|  1 | s     | ref   | PRIMARY |   10 | NULL                                         |
+----+-------+-------+---------+------+----------------------------------------------+
```

<br>

지연된 조인이란 조인 실행전에 정렬, 그루핑 처리하는 방식을 의미  
- LEFT (OUTER) JOIN인 경우 드라이빙 테이블과 드리븐 테이블은 1:1 또는 M:1 관계
- INNER JOIN인 경우 드라이빙 테이블과 드리븐 테이블은 1:1 또는 M:1 관계인 동시에 두 테이블에 모두 레코드 존재

```
mysql> EXPLAIN
         SELECT e.*
         FROM
           (SELECT s.emp_no
            FROM salaries s
            WHERE s.emp_no BETWEEN 10001 AND 13000
            GROUP BY s.emo_no
            ORDER BY SUM(s.salary) DESC
            LIMIT 10) x,
           employees e
         WHERE e.emp_no = x.emp_no;
+----+------------+--------+---------+-------+----------------------------------------------+
| id | table      | type   | key     | rows  | Extra                                        |
+----+------------+--------+---------+-------+----------------------------------------------+
|  1 | <derived2> | ALL    | NULL    |    10 | NULL                                         |
|  1 | e          | eq_ref | PRIMARY |     1 | NULL                                         |
|  2 | s          | range  | PRIMARY | 56844 | Using where; Using temporary; Using filesort |
+----+------------+--------+---------+-------+----------------------------------------------+
```

<br>

### 래터럴 조인(Lateral Join)
8.0 이전 버전까지는 그룹별로 몇 건씩만 가져오는 쿼리 불가능  
래터럴 조인은 특정 그룹별로 서브쿼리를 실행해서 그 결과와 조인하는 기능  
래터럴 조인을 사용하면 해당 FROM 절 서브쿼리 내부에서 외부쿼리 참조 가능  
래터럴 조인은 내부적으로 임시 테이블을 생성  

```sql
SELECT *
FROM employees e
LEFT JOIN LATERAL (SELECT *
                   FROM salaries s
                   WHERE s.emp_no = e.emp_no
                   ORDER BY s.from_date DESC LIMIT 2) s2 ON s2.emp_no = e.emp_no
WHERE e.first_name = 'Matt';
```

<br>

만약 래터럴 조인을 사용하지 않는다면 오류 발생  
FROM 절에 사용된 서브쿼리가 외부쿼리의 칼럼을 참조하기 위해서는 `LATERAL` 키워드 명시 필수  

```
mysql> SELECT *
       FROM employees e
         LEFT JOIN (SELECT *
                    FROM salaries s
                    WHERE s.emp_no = e.emp_no
                    ORDER BY s.from_date DESC LIMIT 2) s2 ON s2.emp_no = e.emp_no
       WHERE e.first_name = 'Matt';
ERROR 1054 (42S22): Unknown column 'e.emp_no' in 'where clause'
```

<br>

### 실행 계획으로 인한 정렬 흐트러짐
네스티드 루프 조인은 드라이빙 테이블에서 읽은 레코드의 순서가 다른 테이블이 모두 조인돼도 그대로 유지  
하지만 쿼리의 실행 계획에서 네스티드 루프 조인 대신 해시 조인이 사용되면서 레코드 정렬 순서가 상이  
정렬이 필요하다면 꼭 ORDER BY 절 명시 필수  

```
mysql> SELECT e.emp_no, e.first_name, e.last_name, de.from_date
       FROM dept_emp de, employees e
       WHERE de.from_date > '2001-10-01' AND e.emp_no < 10005;
+----+-------+-------+-------------+---------------------------------------------------------+
| id | table | type  | key         | Extra                                                   |
+----+-------+-------+-------------+---------------------------------------------------------+
|  1 | e     | range | PRIMARY     | Using where                                             |
|  1 | de    | range | ix_fromdate | Using where; Using index; Using join buffer (hash join) |
+----+-------+-------+-------------+---------------------------------------------------------+
```

<br>

## GROUP BY

### WITH ROLLUP
그루핑된 그룹별로 소계를 가져오는 기능  
출력되는 소계는 단순히 최종 합이 아닌 그루핑된 칼럼의 개수에 따라 소계 레벨이 상이  
항상 그룹 맨 마지막에 전체 총계가 출력되는데 이때 칼럼값은 모두 NULL로 채워져 있음  

```
mysql> SELECT dept_no, COUNT(*)
       FROM dept_emp
       GROUP BY dept_no WITH ROLLUP;
+---------+----------+
| dept_no | COUNT(*) |
+---------+----------+
| d001    | 20211    |
| d002    | 17346    |
| ...     | ...      |
| d009    | 23580    |
| NULL    | 331603   |
+---------+----------+

mysql> SELECT first_name, last_name, COUNT(*)
       FROM employees
       GROUP BY first_name, last_name WITH ROLLUP;
+------------+-----------+----------+
| first_name | last_name | COUNT(*) |
+------------+-----------+----------+
| Aamer      | Anger     | 1        |
| Aamer      | ...       | ...      |
| Aamer      | NULL      | 228      |
| Aamod      | Andreotta | 2        |
| Aamod      | ...       | ...      |
| Aamod      | NULL      | 216      |
| ...        | ...       | ...      |
| NULL       | NULL      | 300024   |
+------------+-----------+----------+
```

<br>

8.0 버전부터 그룹 레코드에 표시되는 NULL 대신 사용자가 변경할 수 있도록 `GROUPING()` 함수 지원  

```
mysql> SELECT
         IF(GROUPING(dept_no), 'All dept_no', dept_no) AS dept_no, COUNT(*)
       FROM dept_emp
       GROUP BY dept_no WITH ROLLUP;
+-------------+----------+
| dept_no     | COUNT(*) |
+-------------+----------+
| d001        | 20211    |
| d002        | 17346    |
| ...         | ...      |
| d009        | 23580    |
| All dept_no | 331603   |
+-------------+----------+
```

<br>

### 레코드를 칼럼으로 변환해서 조회
GROUP BY 또는 집합 함수를 통해 레코드를 그루핑 가능하지만, 하나의 레코드를 여러 개의 칼럼으로 분리하는 SQL 문법은 없음  
다만 집합 함수와 CASE 구문을 이용해 레코드를 칼럼으로 변환하거나 하나의 칼럼을 조건으로 2개 이상의 칼럼으로 변환 가능  

<br>

### 레코드를 칼럼으로 변환
레포팅 도구나 OLAP 같은 도구에서는 기존 그루핑 집합 쿼리 결과를 반대로 만들어야 하는 상황 빈번  

```
mysql> SELECT dept_no, COUNT(*) AS emp_count
       FROM dept_emp
       GROUP BY dept_no;
+---------+-----------+
| dept_no | emp_count |
+---------+-----------+
| d001    | 20211     |
| d002    | 17346     |
| ...     | ...       |
+---------+-----------+

mysql> SELECT
         SUM(CASE WHEN dept_no = 'd001' THEN emp_count ELSE 0 END) AS count_d001,
         SUM(CASE WHEN dept_no = 'd002' THEN emp_count ELSE 0 END) AS count_d002,
         ...
         SUM(CASE WHEN dept_no = 'd008' THEN emp_count ELSE 0 END) AS count_d008,
         SUM(CASE WHEN dept_no = 'd009' THEN emp_count ELSE 0 END) AS count_d009,
         SUM(emp_count) AS count_total
       FROM (
         SELECT dept_no, COUNT(*) AS emp_count FROM dept_emp GROUP BY dept_no
       ) tb_derived;
+------------+------------+------------+------------+-----+-------------+
| count_d001 | count_d001 | count_d001 | count_d001 | ... | count_total |
+------------+------------+------------+------------+-----+-------------+
| 20211      | 17346      | 17786      | 73485      | ... | 331603      |
+------------+------------+------------+------------+-----+-------------+
```

<br>

### 하나의 칼럼을 여러 칼럼으로 분리
소그룹을 특정 조건으로 분리해서 칼럼 지정 가능  

```
mysql> SELECT de.dept_no,
         SUM(CASE WHEN e.hire_date BETWEEN '1980-01-01' AND '1989-12-31' THEN 1 ELSE 0 END) AS cnt_1980,
         SUM(CASE WHEN e.hire_date BETWEEN '1990-01-01' AND '1989-12-31' THEN 1 ELSE 0 END) AS cnt_1990,
         SUM(CASE WHEN e.hire_date BETWEEN '2000-01-01' AND '1989-12-31' THEN 1 ELSE 0 END) AS cnt_2000,
         COUNT(*) AS cnt_total
       FROM dept_emp de, employees e
       WHERE e.emp_no = de.emp_no
       GROUP BY de.dept_no;
+---------+----------+----------+----------+-----------+
| dept_no | cnt_1980 | cnt_1990 | cnt_2000 | cnt_total |
+---------+----------+----------+----------+-----------+
| d001    | 11038    | 8171     | 0        | 20211     |
| d002    | 9580     | 7765     | 1        | 17346     |
| d003    | 9714     | 8068     | 4        | 17786     |
| ...     | ...      | ...      | ...      | ...       |
+---------+----------+----------+----------+-----------+
```

<br>

## ORDER BY
만약 ORDER BY 절이 조회 쿼리에 없다면 어떠한 정렬도 보장하기 어려움  
- 인덱스를 사용한 경우 인덱스에 정렬된 순서대로 레코드 가져옴
- 풀 테이블 스캔인 경우 프라이머리 키 순으로 레코드 가져옴
- 조회 쿼리가 임시 테이블을 사용한 경우 레코드 순서 예측 불가능

<br>

정렬을 할때 인덱스를 사용하지 못하는 경우 추가 정렬 작업이 수행  
`filesort` 메시지가 표시된 경우 쿼리 도중 추가적인 정렬 작업이 수행된 것을 의미  

<br>

### ORDER BY 사용법 및 주의사항
조회되는 칼럼의 순번으로 정렬 가능  
하지만 숫자 값이 아닌 문자열 상수를 사용하는 경우 ORDER BY 절 무시  

```sql
## 동일한 정렬 결과
SELECT first_name, last_name FROM employees ORDER BY last_name;
SELECT first_name, last_name FROM employees ORDER BY 2;

## 모든 ORDER BY 절 무시
SELECT first_name, last_name FROM employees ORDER BY "last_name";
```

<br>

### 여러 방향으로 동시 정렬
8.0 버전부터 여러 개의 칼럼을 조합해서 정렬할 때 각 칼럼의 정렬 순서를 혼용해서 인덱스 사용 가능  

```sql
ALTER TABLE salaries ADD INDEX ix_salary_fromdate (salary DESC, from_date ASC);
```

<br>

## 서브쿼리

### SELECT 절에 사용된 서브쿼리
서브쿼리는 내부적으로 임시 테이블을 만들거나 쿼리를 비효율적으로 실행하지 않기 때문에 인덱스 사용 가능하다면 문제없음  
SELECT 절에 서브쿼리를 사용하려면 해당 서브쿼리는 항상 칼럼과 레코드가 하나인 결과 반환 필수(로우 서브쿼리가 아닌 스칼라 서브쿼리)  

```
-- // 서브쿼리 결과가 항상 0건, NULL로 채워서 반환
mysql> SELECT emp_no, (SELECT dept_name FROM departments WHERE dept_name = 'Sales1')
       FROM dept_emp LIMIT 10;
+--------+------+
| 100001 | NULL |
| 100002 | NULL |
| ...    | ...  |
+--------+------+

-- // 서브쿼리가 2건 이상의 레코드 반환
mysql> SELECT emp_no, (SELECT dept_name FROM departments)
       FROM dept_emp LIMIT 10;
ERROR 1242 (21000): Subquery returns more than 1 row

-- // 서브쿼리가 2개 이상의 칼럼을 반환
mysql> SELECT emp_no, (SELECT dept_no, dept_name FROM departments WHERE dept_name = 'Sales1')
       FROM dept_emp LIMIT 10;
ERROR 1241 (21000): Operand should contain 1 column(s)
```

<br>

### FROM 절에 사용된 서브쿼리
5.7 버전부터 옵티마이저는 FROM 절의 서브쿼리를 임시 테이블이 아닌 외부 쿼리로 병합하는 최적화 수행  

```
mysql> EXPLAIN SELECT * FROM (SELECT * FROM employees) y;
+----+-------------+-----------+------+------+--------+-------+
| id | select_type | table     | type | key  | rows   | Extra |
+----+-------------+-----------+------+------+--------+-------+
|  1 | SIMPLE      | employees | ALL  | NULL | 299920 | NULL  |
+----+-------------+-----------+------+------+--------+-------+

-- // MySQL 서버가 서브쿼리를 병합해서 재작성한 쿼리
mysql> SHOW WARNINGS \G
*************************** 1. row ***************************
  Level: Note
   Code: 1003
Message: /* select#1 */ select
  `employees`.`employees`.`emp_no` AS `emp_no`,
  `employees`.`employees`.`birth_date` AS `birth_date`,
  `employees`.`employees`.`first_name` AS `first_name`,
  `employees`.`employees`.`last_name` AS `last_name`,
  `employees`.`employees`.`gender` AS `gender`,
  `employees`.`employees`.`hire_date` AS `hire_date`
from `employees`.`employees`
```

<br>

FROM 절의 서브쿼리가 아래 기능을 포함하면 외부 쿼리로 병합 불가  
- 집합함수 사용
- DISTINCT
- GROUP BY 또는 HAVING
- LIMIT
- UNION, UNION ALL
- SELECT 절 서브쿼리 사용
- 사용자 변수 사용

<br>

### WHERE 절에 사용된 서브쿼리
- 동등 또는 대소비교(`= (subquery)`)
- IN 비교(`IN (subquery)`)
- NOT IN 비교(`NOT IN (subquery)`)

<br>

### 동등 또는 대소비교
5.5 버전까지는 서브쿼리 외부 조건으로 쿼리를 실행, 최종적으로 서브쿼리를 체크 조건으로 사용  
이러한 처리 방식은 풀 테이블 스캔이 필요한 경우가 대다수  
5.5 버전부터는 서브쿼리를 먼저 실행한 후 상수로 변환  

```
mysql> EXPLAIN
         SELECT * FROM dept_emp de
         WHERE de.emp_no = (SELECT e.emp_no
                            FROM employees e
                            WHERE e.first_name = 'Georgi' AND e.last_name = 'Facello' LIMIT 1);
+----+-------------+-------+------+-------------------+------+-------------+
| id | select_type | table | type | key               | rows | Extra       |
+----+-------------+-------+------+-------------------+------+-------------+
|  1 | PRIMARY     | de    | ref  | ix_empno_fromdate |    1 | Using where |
|  2 | SUBQUERY    | e     | ref  | ix_firstname      |  253 | Using where |
+----+-------------+-------+------+-------------------+------+-------------+

mysql> EXPLAIN FORMAT=TREE
         SELECT * FROM dept_emp de
         WHERE de.emp_no = (SELECT e.emp_no
                            FROM employees e
                            WHERE e.first_name = 'Georgi' AND e.last_name = 'Facello' LIMIT 1);

-> Filter: (de.emp_no = (select #2))  (cost=1.10 rows=1)
  -> Index lookup on de using ix_empno_fromdate (emp_no=(select #2))  (cost=1.10 rows=1)
  -> Select #2 (subquery in condition; run only once)
      -> Limit: 1 row(s)
          -> Filter: (e.last_name = 'Facello')  (cost=70.49 rows=25)
              -> Index lookup on e using ix_firstname (first_name='Georgi')  (cost=70.49 rows=253)
```

<br>

만일 튜플 비교 방식이라면 서브쿼리가 먼저 처리되어 상수화되긴하지만 외부 쿼리는 풀 테이블 스캔  
8.0 버전에서도 아직 튜플 형태의 비교는 주의 필요  

```
mysql> EXPLAIN
         SELECT *
         FROM dept_emp de WHERE (emp_no, from_date) = (
           SELECT emp_no, from_date
           FROM salaries
           WHERE emp_no = 100001 LIMIT 1);
+----+-------------+----------+------+---------+--------+-------------+
| id | select_type | table    | type | key     | rows   | Extra       |
+----+-------------+----------+------+---------+--------+-------------+
|  1 | PRIMARY     | de       | ALL  | NULL    | 331143 | Using where |
|  2 | SUQEURY     | salaries | ref  | PRIMARY |      4 | Using index |
+----+-------------+----------+------+---------+--------+-------------+
```

<br>

### IN 비교(IN (subquery))
실제 조인은 아니지만 테이블의 레코드가 다른 테이블의 레코드를 이용한 표현식과 일치하는지 체크하는 형태를 세미 조인  
5.5 버전까지는 세미 조인 최적화가 부족해서 대부분 풀 테이블 스캔 사용  
- 테이블 풀-아웃
- 퍼스트 매치
- 루스 스캔
- 구체화
- 중복 제거

<br>

### NOT IN 비교(NOT IN (subquery))
해당 경우를 안티 세미 조인이라고 표현  
해당 방법은 성능 향상에 도움이 되지 않기때문에 최대한 다른 조건을 활용해서 데이터 검색 범위를 좁히는게 효율적  
- NOT EXISTS
- 구체화

<br>
