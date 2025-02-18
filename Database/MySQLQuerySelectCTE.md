# SELECT
상대적으로 INSERT, UPDATE 같은 작업은 거의 레코드 단위로 발생하기 때문에 성능상 문제가 되는 경우 적음  
하지만 SELECT 작업은 여러개의 테이블로부터 데이터를 조합해서 빠르게 가져와야 하기 때문에 주의 필수  

<br>

## CTE(Common Table Expression)
이름을 가지는 임시 테이블, SQL 문장 내에서 한번 이상 사용 가능하며 문장 종료시 임시 테이블 삭제  
재귀적 반복 실행 여부를 기준으로 `Non-recursive` 또는 `Recursive` 구분  
- SELECT, UPDATE, DELETE 문장 제일 앞
  ```sql
  WITH cte1 AS (SELECT ...) SELECT ...
  WITH cte1 AS (SELECT ...) UPDATE ...
  WITH cte1 AS (SELECT ...) DELETE ...
  ```

- 서브쿼리 제일 앞
  ```sql
  SELECT ... FROM ... WHERE id IN (WITH cte1 AS (SELECT ...) SELECT ...) ...
  SELECT ... FROM (WITH cte1 AS (SELECT ...) SELECT ...) ...
  ```

- SELECT 절 바로 앞
  ```sql
  INSERT ... WITH cte1 AS (SELECT ...) SELECT ...
  REPLACE ... WITH cte1 AS (SELECT ...) SELECT ...
  CREATE TABLE ... WITH cte1 AS (SELECT ...) SELECT ...
  CREATE VIEW ... WITH cte1 AS (SELECT ...) SELECT ...
  DECLARE CURSOR ... WITH cte1 AS (SELECT ...) SELECT ...
  EXPLAIN ... WITH cte1 AS (SELECT ...) SELECT ...
  ```

<br>

### 비 재귀적 CTE(Non-Recursive CTE)
MySQL 서버에서는 `ANSI` 표준을 그대로 이용해서 WITH 절을 이용해 CTE 정의  

```sql
WITH cte1 AS (SELECT * FROM departments)
SELECT * FROM cte1;
```

<br>

여러 개의 CTE 임시 테이블을 이용해서 파생 테이블 대체 가능  
파생 테이블은 똑같은 데이터도 FROM 절에 사용된 횟수만큼 임시 테이블을 생성  

```
-- // CTE 사용 쿼리
mysql> EXPLAIN
         WITH cte1 AS (SELECT emp_no, MIN(from_date) FROM salaries GROUP BY emp_no)
         SELECT * FROM employees e
           INNER JOIN cte1 t1 ON t1.emp_no = e.emp_no
           INNER JOIN cte1 t2 ON t2.emp_no = e.emp_no;
+----+-------------+------------+--------+-------------+--------+--------------------------+
| id | select_type | table      | type   | key         | rows   | Extra                    |
+----+-------------+------------+--------+-------------+--------+--------------------------+
|  1 | PRIMARY     | <derived2> | ALL    | NULL        | 273035 | NULL                     |
|  1 | PRIMARY     | e          | eq_ref | PRIMARY     |      1 | NULL                     |
|  1 | PRIMARY     | <derived2> | ref    | <auto_key0> |     10 | NULL                     |
|  2 | DERIVED     | salaries   | range  | PRIMARY     | 273035 | Using index for group-by |
+----+-------------+------------+--------+-------------+--------+--------------------------+

-- // 파생테이블 서브쿼리
mysql> EXPLAIN
         SELECT * FROM employees e
           INNER JOIN (SELECT emp_no, MIN(from_date) FROM salaries GROUP BY emp_no) t1
                 ON t1.emp_no = e.emp_no;
           INNER JOIN (SELECT emp_no, MIN(from_date) FROM salaries GROUP BY emp_no) t2
                 ON t2.emp_no = e.emp_no;
+----+-------------+------------+--------+-------------+--------+--------------------------+
| id | select_type | table      | type   | key         | rows   | Extra                    |
+----+-------------+------------+--------+-------------+--------+--------------------------+
|  1 | PRIMARY     | <derived2> | ALL    | NULL        | 273035 | NULL                     |
|  1 | PRIMARY     | e          | eq_ref | PRIMARY     |      1 | NULL                     |
|  1 | PRIMARY     | <derived3> | ref    | <auto_key0> |     10 | NULL                     |
|  3 | DERIVED     | salaries   | range  | PRIMARY     | 273035 | Using index for group-by |
|  2 | DERIVED     | salaries   | range  | PRIMARY     | 273035 | Using index for group-by |
+----+-------------+------------+--------+-------------+--------+--------------------------+
```

<br>

정의된 CTE 임시 테이블 순서대로 다음 임시 테이블에서 재사용 가능  
단, 이미 정의된 임시 테이블은 사용 가능하지만 이후에 정의된 임시 테이블은 사용 불가  

```sql
WITH
cte1 AS (SELECT emp_no, MIN(from_date) as saalary_from_date
         FROM salaries
         WHERE salary BETWEEN 50000 AND 51000
         GROUP BY emp_no),
cte2 AS (SELECT de.emp_no, MIN(from_date) as dept_from_date
         FROM cte1
           INNER JOIN dept_emp de ON de.emp_no = temp1.emp_no
         GROUP BY emp_no)
SELECT * FROM employees e
  INNER JOIN cte1 t1 ON t1.emp_no = e.emp_no
  INNER JOIN cte2 t2 ON t2.emp_no = e.emp_no;
```

재귀적으로 CTE 사용을 하지 않더라도 기존 FROM 절 파생 테이블에 비해 장점 존재  
- CTE 임시 테이블은 재사용 가능하므로 효율적
- CTE 선언된 임시 테이블은 다른 CTE 쿼리에서 참조 가능
- CTE 임시 테이블의 생성 부분과 사용 부분의 코드를 분리할 수 있어서 가독성 높음

<br>

### 재귀적 CTE(Recursive CTE)
재귀 쿼리는 많은 사용자를 다시 복귀하게 만든 윈백(`Win Back`) 프로젝트  

```
mysql> WITH RECURSIVE cte (no) AS (
         SELECT 1
         UNION ALL
         SELECT (no + 1) FROM cte WHERE no < 5;
       )
       SELECT * FROM cte;
+----+
| no |
+----+
|  1 |
|  2 |
|  3 |
|  4 |
|  5 |
+----+
5 rows in set (0.00 sec)
```

<br>

비재귀적 CTE 쿼리는 단순히 쿼리를 한번만 실행 후 그 결과를 임시 테이블로 저장  
재귀적 CTE 쿼리는 비재귀적 쿼리 파트와 재귀적 파트로 구분  
이 두 파트를 반드시 `UNION(UNION DISTINCT)` 또는 `UNION ALL`로 연결하는 형태로 작성  
비재귀적 쿼리 파트가 초기에 수행되며, 임시 테이블의 구조(칼럼 타입, 이름 등)는 해당 쿼리 결과에 따라 생성  
이후 재귀적 쿼리 파트는 실행할 때 지금까지의 모든 단계에서 만들어진 결과 셋이 아닌 직전 단계의 결과만 입력으로 사용  

|  | cte 실제 임시 테이블 | 쿼리 입력 레코드 | 쿼리 출력 레코드 |
|--|--|--|--|
| 비 재귀적 쿼리 파트 실행 | 없음 | 없음 | 1 |
| 재귀적 쿼리 파트 첫번째 실행 | 1 | 1 | 2 |
| 재귀적 쿼리 파트 두번째 실행 | 1, 2 | 2 | 3 |
| 재귀적 쿼리 파트 첫번째 실행 | 1, 2, 3 | 3 | 4 |
| 재귀적 쿼리 파트 첫번째 실행 | 1, 2, 3, 4 | 4 | 5 |

<br>

데이터 오류나 쿼리 실수로 종료 조건을 만족하지 못하고 무한 반복되는 경우 발생  
`cte_max_recursion_depth` 시스템 변수로 최대 반복 실행 횟수 설정 가능, 기본값 1000  
해당 값은 낮게 설정하고, 필요할때만 `SET_VAR` 힌트로 재설정 권장  

```sql
SET cte_max_recursion_depth = 10;
```

```
mysql > WITH RECURSIVE cte (no) AS (
          SELECT 1 AS no
          UNION ALL
          SELECT (no + 1) AS no FROM cte WHERE no < 1000
        )
        SELECT * FROM cte;

ERROR 3636 (HY000): Recursive query aborted after 11 iterations.
                    Try increasing @@cte_max_recursion_depth to a larger value.

mysql > WITH RECURSIVE cte (no) AS (
          SELECT 1 AS no
          UNION ALL
          SELECT (no + 1) AS no FROM cte WHERE no < 1000
        )
        SELECT /*+ SET_VAR(cte_max_recursion_depth=10000) */ * FROM cte;
+------+
| no   |
+------+
|    1 |
|    2 |
|  ... |
|  999 |
| 1000 |
+------+
```

<br>

### 재귀적 CTE(Recursive CTE) 활용
```sql
CREATE DATABASE test;
USE test;

CREATE TABLE test.employees (
  id         INT PRIMARY KEY NOT NULL,
  name       VARCHAR(100) NOT NULL,
  manager_id INT NULL,
  INDEX (manager_id),
  FOREIGN KEY (manager_id) REFERENCES employees (id)
);

INSERT INTO test.employees VALUES
  (333,  "Yasmina", NULL),
  (198,  "John",     333),
  (692,  "Tarek",    333),
  (29,   "Pedro",    198),
  (4610, "Sarah",     29),
  (72,   "Pierre",    29),
  (123,  "Adil",     692);
```

<br>

실제 테이블을 이용한 재귀적 CTE 쿼리는 단순히 숫자만 가져오던 예제와는 차이가 존재  

```
mysql> WITH RECURSIVE
         managers AS(
           SELECT *, 1 AS lv FROM employees WHERE id = 123
           UNION ALL
           SELECT e.*, lv + 1 FROM managers m
                      INNER JOIN employees e ON e.id = m.manager_id AND m.manager_id IS NOT NULL
         )
       SELECT * FROM managers
       ORDER BY lv DESC;
+-----+---------+------------+----+
|  id | name    | manager_id | lv |
+-----+---------+------------+----+
| 333 | Yasmina |       NULL |  3 |
| 692 | Tarek   |        333 |  2 |
| 123 | Adil    |        692 |  1 |
+-----+---------+------------+----+

mysql> WITH RECURSIVE
         managers AS (
           SELECT *,
                  CAST(id AS CHAR(100)) AS manager_path,
                  1 AS lv
           FROM employees WHERE manager_id IS NULL
         UNION ALL
         SELECT e.*,
                CONCAT(e.id, ' -> ', m.manager_path) AS manager_path,
                lv + 1
           FROM managers m
           INNER JOIN employees e ON e.manager_id = m.id
         )
       SELECT * FROM managers
       ORDER BY lv ASC;
+------+---------+------------+--------------------------+----+
| id   | name    | manager_id | manager_path             | lv |
+------+---------+------------+--------------------------+----+
|  333 | Yasmina |       NULL | 333                      |  1 |
|  198 | John    |        333 | 198 -> 333               |  2 |
|  692 | Tarek   |        333 | 692 -> 333               |  2 |
|   29 | Pedro   |        198 | 29 -> 198 -> 333         |  3 |
|  123 | Adil    |        692 | 123 -> 692 -> 333        |  3 |
|   72 | Pierre  |         29 | 72 -> 29 -> 198 -> 333   |  4 |
| 4610 | Sarah   |         29 | 4610 -> 29 -> 198 -> 333 |  4 |
+------+---------+------------+--------------------------+----+
```

<br>
