# 옵티마이저와 힌트
MySQL 서버로 요청된 쿼리 결과가 동일해도 내부적으로 처리 과정은 매우 다양  
쿼리를 최적으로 실행하기 위해 각 테이블의 데이터가 어떤 분포로 저장돼 있는지 통계 정보를 참조  
이런 기본 데이터를 비교해 최적 실행 계획을 수립하는 작업 필수  

<br>

## DISTINCT 처리
특정 칼럼의 유니크한 값만 조회하는 경우 사용  
집합 함수와 함께 사용되는 경우와 아닌 경우 2가지로 구분  

<br>

### SELECT DISTINCT ...
`GROUP BY` 절과 동일한 방식으로 처리  

```sql
SELECT DISTINCT emp_no FROM salaries;
SELECT emp_no FROM salaries GROUP BY emp_no;
```

<br>

`DISTINCT`는 조회하는 레코드를 유니크하게 하는 것이지 특정 칼럼만 유니크하게 조회하는 것이 아님  
괄호로 묶어서 사용해도 의미없이 사용된 괄호로 해석하고 제거  

```sql
## 같은 결과 쿼리
SELECT DISTINCT first_name, last_name FROM employees;
SELECT DISTINCT(first_name), last_name FROM employees;
```

<br>

### 집합 함수와 함께 사용된 DISTINCT
`COUNT()`, `MIN()`, `MAX()` 같은 집함 함수와 함께 사용된 경우에는 일반적으로 다른 해석  
그 집합 함수의 인자로 전달된 칼럼값이 유니크한 것들을 조회  

```
mysql> EXPLAIN
         SELECT COUNT(DISTINCT s.salary)
         FROM employees e, salaries s
         WHERE e.emp_no = s.emp_no
         AND e.emp_no BETWEEN 100001 AND 100100;

+----+-------+-------+---------+------+--------------------------+
| id | table | type  | key     | rows | Extra                    |
+----+-------+-------+---------+------+--------------------------+
|  1 | e     | range | PRIMARY | 100  | Using where; Using index |
|  1 | s     | ref   | PRIMARY | 10   | NULL                     |
+----+-------+-------+---------+------+--------------------------+
```

```sql
SELECT COUNT(DISTINCT s.salary), COUNT(DISTINCT e.last_name)
FROM employees e, salaries s
WHERE e.emp_no = s.emp_no
AND e.emp_no BETWEEN 100001 AND 100100;
```

실행 계획에는 임시 테이블을 사용한다는 메시지 표시 안함  
위의 두 쿼리는 실행계획은 똑같지만 처리를 위한 임시 테이블 갯수가 1개, 2개로 차이 발생  

<br>

```
mysql> SELECT COUNT(DISTINCT emp_no) FROM employees;
mysql> EXPLAIN SELECT COUNT(DISTINCT emp_no) FROM dept_emp GROUP BY dept_no;

+----+----------+-------+---------+--------+-------------+
| id | table    | type  | key     | rows   | Extra       |
+----+----------+-------+---------+--------+-------------+
|  1 | dept_emp | index | PRIMARY | 331143 | Using index |
+----+----------+-------+---------+--------+-------------+
```

인덱스된 칼럼에 대해 `DISTINCT` 처리를 수행한 경우 인덱스를 풀 스캔하거나 레인지 스캔하면서 임시 테이블 없이 최적화  

<br>
