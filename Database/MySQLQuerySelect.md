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














