# 실행 계획 분석
실행 계획 표의 각 라인은 쿼리 문장에서 사용된 테이블의 개수만큼 출력  
실행 순서는 위에서 아래로 순서대로 표시(유니온이나 상관 서브쿼리는 예외)  
위쪽에 출력된 결과일수록 쿼리의 바깥 부분이거나 먼저 접근한 테이블  

<br>

## id 칼럼
id 칼럼은 단위 SELECT 쿼리별로 부여되는 식별자  
여러 개의 테이블을 조인하면 조인되는 테이블 개수만큼 실행 계획 레코드가 출력되지만 같은 id 값 부여  
반대로 여러 단위 SELECT 쿼리로 구성된 경우 각기 다른 id 값 부여

```
mysql> EXPLAIN
         SELECT e.emp_no, e.first_name, s.from_date, s.salary
         FORM employees e, salaries s
         WHERE e.emp_no = s.emp_no LIMIT 10;

+----+-------------+-------+-------+--------------+--------------------+--------+-------------+
| id | select_type | table | type  | key          | ref                | rows   | Extra       |
+----+-------------+-------+-------+--------------+--------------------+--------+-------------+
|  1 | SIMPLE      | e     | index | ix_firstname | NULL               | 300252 | Using index |
|  1 | SIMPLE      | s     | ref   | PRIMARY      | employees.e.emp_no |     10 | NULL        |
+----+-------------+-------+-------+--------------+--------------------+--------+-------------+

mysql> EXPLAIN
         SELECT
         ( (SELECT COUNT(*) FROM employees) + (SELECT COUNT(*) FROM departments) ) AS total_count;

+----+-------------+-------------+-------+-------------+------+--------+----------------+
| id | select_type | table       | type  | key         | ref  | rows   | Extra          |
+----+-------------+-------------+-------+-------------+------+--------+----------------+
|  1 | PRIMARY     | NULL        | NULL  | NULL        | NULL |   NULL | No tables used |
|  2 | SUBQUERY    | departments | index | ux_deptname | NULL |      9 | Using index    |
|  3 | SUBQUERY    | employees   | index | ix_hiredate | NULL | 300252 | Using index    |
+----+-------------+-------------+-------+-------------+------+--------+----------------+
```

<br>

## selecct_type 칼럼
각 단위 SELECT 쿼리가 어떤 타입의 쿼리인지 표시  

<br>

### SIMPLE
단순한 조회 쿼리인 경우  
쿼리 문장이 복잡하더라도 실행 계획에서 SIMPLE인 단위 쿼리는 하나만 존재  
일반적으로 제일 바깥 조회 쿼리가 SIMPLE로 표시  


<br>

### PRIMARY
UNION이나 서브쿼리를 가지는 조회 쿼리의 실행 계획에서 가장 바깥쪽에 있는 단위 쿼리가 PRIMARY로 표시  
SIMPLE과 마찬가지로 PRIMARY 단위 조회 쿼리는 하나만 존재  

<br>

### UNION
UNION으로 결합하는 단위 조회 쿼리 가운데 첫 번째를 제외한 두번째 이후 단위 조회 쿼리는 UNION으로 표시  
첫번째 단위 조회는 UNION되는 쿼리 결과를 모아서 저장하는 임시 테이블(DERIVED)로 표시  

```
mysql> EXPLAIN
         SELECT * FROM
           (SELECT emp_no FROM employees e1 LIMIT 10) UNION ALL
           (SELECT emp_no FROM employees e2 LIMIT 10) UNION ALL
           (SELECT emp_no FROM employees e3 LIMIT 10) tb;

+----+-------------+------------+-------+-------------+------+--------+-------------+
| id | select_type | table      | type  | key         | rdf  | rows   | Extra       |
+----+-------------+------------+-------+-------------+------+--------+-------------+
|  1 | PRIMARY     | <derived2> | ALL   | NULL        | NULL |     30 | NULL        |
|  2 | DERIVED     | e1         | index | ix_hiredate | NULL | 300252 | Using index |
|  3 | UNION       | e2         | index | ix_hiredate | NULL | 300252 | Using index |
|  4 | UNION       | e3         | index | ix_hiredate | NULL | 300252 | Using index |
+----+-------------+------------+-------+-------------+------+--------+-------------+
```

<br>

### DEPENDENT UNION
UNION ALL로 집합을 결합하는 쿼리에서 표시  
결합된 단위 쿼리가 외부 쿼리에 의해 영향을 받는 것을 의미  
내부 쿼리가 외부의 값을 참조해서 처리되는 경우  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e1
         WHERE e1.emp_no IN (
           SELECT e2.emp_no FROM employees e2 WHERE e2.first_name = 'Matt'
           UNION
           SELECT e3.emp_no FROM employees e3 WHERE e3.last_name = 'Matt'
         );

+----+--------------------+------------+--------+---------+------+--------+-----------------+
| id | select_type        | table      | type   | key     | ref  | rows   | Extra           |
+----+--------------------+------------+--------+---------+------+--------+-----------------+
|  1 | PRIMARY            | e1         | ALL    | NULL    | NULL | 300252 | Using where     |
|  2 | DEPENDENT SUBQUERY | e2         | eq_ref | PRIMARY | func |      1 | Using where     |
|  3 | DEPENDENT UNION    | e3         | eq_ref | PRIMARY | func |      1 | Using where     |
|NULL| UNION RESULT       | <union2,3> | ALL    | NULL    | NULL |   NULL | Using tempoaray |
+----+--------------------+------------+--------+---------+------+--------+-----------------+
```

<br>

### UNION RESULT
UNION 결과를 담아두는 테이블을 의미  
8.0 버전부터 UNION ALL의 경우 임시 테이블을 사용하지 않도록 기능 개선  
하지만 UNION은 여전히 임시 테이블에 결과를 버퍼링  
실제 쿼리에서 단위 쿼리가 아니기 때문에 별도의 id 값은 부여되지 않음  

```
mysql> EXPLAIN
         SELECT emp_no FROM salaries WHERE salary > 100000
         UNION DISTINT
         SELECT emp_no FROM dept_emp WHERE from_date > '2001-01-01';

+----+--------------+------------+-------+-------------+--------+--------------------------+
| id | select_type  | table      | type  | key         | rows   | Extra                    |
+----+--------------+------------+-------+-------------+--------+--------------------------+
|  1 | PRIMARY      | salaries   | range | ix_salary   | 191348 | Using where; Using index |
|  2 | UNION        | dept_emp   | range | ix_fromdate |   5325 | Using where; Using index |
|NULL| UNION RESULT | <union1,2> | ALL   | NULL        |   NULL | Using temporary          |
+----+--------------+------------+-------+-------------+--------+--------------------------+

mysql> EXPLAIN
         SELECT emp_no FROM salaries WHERE salary > 100000
         UNION ALL
         SELECT emp_no FROM dept_emp WHERE from_date > '2001-01-01';

+----+-------------+----------+-------+-------------+--------+--------------------------+
| id | select_type | table    | type  | key         | rows   | Extra                    |
+----+-------------+----------+-------+-------------+--------+--------------------------+
|  1 | PRIMARY     | salaries | range | ix_salary   | 191348 | Using where; Using index |
|  2 | UNION       | dept_emp | range | ix_fromdate |   5325 | Using where; Using index |
+----+-------------+----------+-------+-------------+--------+--------------------------+
```

<br>

### SUBQUERY
FROM 절 이외에서 사용되는 서브쿼리만을 의미  
FROM 절에 사용되는 서브쿼리는 DERIVE로 표시  

서브쿼리는 사용하는 위치에 따라 각각 다른 이름 보유  
- 중첩된 쿼리(`nested query`): SELECT되는 칼럼에 사용된 경우
- 서브쿼리(`subquery`): WHERE 절에 사용된 경우
- 파생 테이블(`derived table`): FROM 절에 사용된 경우

서브쿼리가 반환하는 값의 특성에 따라서도 구분 가능
- 스칼라 서브쿼리(`scalar subquery`): 하나의 값만 반환하는 쿼리
- 로우 서브쿼리(`row subquery`): 칼럼의 개수와 관계없이 하나의 레코드만 반환하는 쿼리

<br>

### DEPENDENT SUBQUERY
서브쿼리가 바깥쪽 조회 쿼리에서 정의된 칼럼을 사용하는 경우  
안쪽 서브쿼리 결과가 바깥쪽 조회 쿼리 칼럼에 의존적  

```
mysql> EXPLAIN
         SELECT e.first_name,
           (SELECT COUNT(*)
           FROM dept_emp de, dept_manager dm
           WHERE dm.dept_no = dept_no AND dde.emp_no = e.emp_no) AS cnt
         FROM employees e
         WHERE e.first_name = 'Matt';

+----+--------------------+-------+------+-------------------+------+-------------+
| id | select_type        | table | type | key               | rows | Extra       |
+----+--------------------+-------+------+-------------------+------+-------------+
|  1 | PRIMARY            | e     | ref  | ix_firstname      |  233 | Using index |
|  2 | DEPENDNET SUBQUERY | de    | ref  | ix_empno_fromdate |    1 | Using index |
|  2 | DEPENDNET SUBQUERY | dm    | ref  | PRIMARY           |    2 | Using index |
+----+--------------------+-------+------+-------------------+------+-------------+
```

<br>

### DERIVED
단위 조회 쿼리의 실행 결과로 메모리나 디스크에 임시 테이블을 생성하는 것 의미  
5.5 버전까지는 서브쿼리가 FROM 절에 사용된 경우 항상 DERIVED인 실행 계획 수립  
5.6 버전부터 옵티마이저 옵션에 따라 외부 쿼리와 통합하는 형태의 최적화 수행 가능  
가능하다면 DERIVED 형태의 실행 계획을 조인으로 해결하는 것 권장  

```
mysql> EXPLAIN
         SELECT *
         FROM (SELECT de.emp_no FROM dept_emp de GROUP BY de.emp_no) tb,
           employees e
         WHERE e.emp_no = tb.emp_no;

+----+-------------+------------+--------+-------------------+--------+-------------+
| id | select_type | table      | type   | key               | rows   | Extra       |
+----+-------------+------------+--------+-------------------+--------+-------------+
|  1 | PRIMARY     | <derived2> | ALL    | NULL              | 331143 | NULL        |
|  1 | PRIMARY     | e          | eq_ref | PRIMARY           |      1 | NULL        |
|  2 | DERIVED     | de         | index  | ix_empno_fromdate | 331143 | Using index |
+----+-------------+------------+--------+-------------------+--------+-------------+
```

<br>

### DEPENDENT DERIVED
8.0 버전 이전에서 FROM 절의 서브쿼리는 외부 칼럼 사용 불가  
래터럴 조인(`LATERAL JOIN`) 기능이 추가되면서 FROM 절의 서브쿼리에서도 외부 칼럼 참조 가능  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
         LEFT JOIN LATERAL
           (SELECT *
           FROM salaries s
           WHERE s.emp_no = e.emp_no
           ORDER BY s.from_date DESC LIMIT 2) AS s2 ON s2.emp_no = e.emp_no;

+----+-------------------+------------+------+-------------+----------------------------+
| id | select_type       | table      | type | key         | Extra                      |
+----+-------------------+------------+------+-------------+----------------------------+
|  1 | PRIMARY           | e          | ALL  | NULL        | Rematerialize (<derived2>) |
|  1 | PRIMARY           | <derived2> | ref  | <auto_key0> | NULL                       |
|  2 | DEPENDENT DERIVED | s          | ref  | PRIMARY     | Using filesort             |
+----+-------------------+------------+------+-------------+----------------------------+
```

<br>

### UNCACHEABLE SUBQUERY
하나의 쿼리 문장에 서브쿼리가 하나만 있더라도 실제 한번만 실행되는 것은 아님  
조건이 똑같은 서브쿼리 실행될 때는 다시 실행하지 않고, 내부적인 캐시 공간에 저장된 결과를 사용  


<br>

SUBQUERY인 경우 캐시가 처음 한 번만 생성  

<img width="600" alt="subquerycache" src="https://github.com/user-attachments/assets/b641ed0b-2545-46df-bc25-f116f8bcd2dc" />


- SUBQUERY는 바깥쪽의 영향을 받지 않으므로 한번만 실행한 후 결과를 캐시
- DEPENDENT SUBQUERY는 의존하는 바깥쪽 쿼리의 칼럼 값 단위로 캐시

<br>

DEPENDENT SUBQUERY는 서브쿼리 결과가 딱 한번만 캐시되는 것이 아닌, 외부 쿼리의 값 단위로 캐시 생성  
서브쿼리에 포함된 요소에 따라 캐시 자체가 불가능한 경우 UNCACHEABLE SUBQUERY로 표시  
- 사용자 변수가 서브쿼리에 사용된 경우
- `NOT-DETERMINISTIC` 속성의 스토어드 루틴이 서브쿼리에 사용된 경우
- `UUID()` 또는 `RAND()` 같이 결과값이 호출할 때마다 상이한 함수가 서브쿼리에 사용된 경우

```
mysql> EXPLAIN
         SELECT *
         FROM employees e WHERE e.emp_no = (
           SELECT @status FROM dept_emp de WHERE de.dept_no = 'd005');

+----+----------------------+-------+------+---------+--------+-------------+
| id | select_type          | table | type | key     | rows   | Extra       |
+----+----------------------+-------+------+---------+--------+-------------+
|  1 | PRIMARY              | e     | ALL  | NULL    | 300252 | Using where |
|  2 | UNCACHEABLE SUBQUERY | de    | ref  | PRIMARY | 165571 | Using index |
+----+----------------------+-------+------+---------+--------+-------------+
```

<br>

### UNCACHEABLE UNION
UNION과 UNCACHEABLE 두 개의 속성이 혼합  

<br>

### MATERIALIZED
주로 FROM 절이나 IN(subquery) 형태의 쿼리에 사용된 서브쿼리 최적화  
서브쿼리 내용을 임시 테이블로 구체화한 후 임시 테이블과 조인하는 형태의 최적화  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
         WHERE e.emp_no IN (SELECT emp_no FROM salaries WHERE salary BETWEEN 100 AND 1000);

+----+--------------+-------------+--------+-----------+------+--------------------------+
| id | select_type  | table       | type   | key       | rows | Extra                    |
+----+--------------+-------------+--------+-----------+------+--------------------------+
|  1 | SIMPLE       | <subquery2> | ALL    | NULL      | NULL | NULL                     |
|  1 | SIMPLE       | e           | eq_ref | PRIMARY   |    1 | NULL                     |
|  2 | MATERIALIZED | salaries    | range  | ix_salary |    1 | Using where; Using index |
+----+--------------+-------------+--------+-----------+------+--------------------------+
```

<br>

## table 칼럼
실행 계획은 단위 조회 쿼리 기준이 아닌 테이블 기준으로 표시  
테이블에 별칭이 부여된 경우 별칭 표시  

```
mysql> EXPLAIN SELECT NOW();
mysql> EXPLAIN SELECT NOW() FROM DUAL;
+----+-------------+-------+------+---------+----------------+
| id | select_type | table | key  | key_len | Extra          |
+----+-------------+-------+------+---------+----------------+
|  1 | SIMPLE      | NULL  | NULL | NULL    | No tables used |
+----+-------------+-------+------+---------+----------------+
```

<br>

table 칼럼에 `<derived N>` 또는 `<union M,N>` 같이 `<>`로 둘러싸인 이름은 임시 테이블을 의미  

```
+----+-------------+------------+--------+-------------------+--------+-------------+
| id | select_type | table      | type   | key               | rows   | Extra       |
+----+-------------+------------+--------+-------------------+--------+-------------+
|  1 | PRIMARY     | <derived2> | ALL    | NULL              | 331143 | NULL        |
|  1 | PRIMARY     | e          | eq_ref | PRIMARY           |      1 | NULL        |
|  2 | DERIVED     | de         | index  | ix_empno_fromdate | 331143 | Using index |
+----+-------------+------------+--------+-------------------+--------+-------------+
```

1. 첫번째 라인의 테이블이 `<derived2>`로 표기, id 값이 2인 라인이 먼저 실행된 후 그 결과가 파생 테이블로 준비
2. 세번째 라인에 DERIVED로 표기, 해당 테이블이 파생 테이블을 생성
3. 첫번째 라인과 두번째 라인은 같은 id, 2개의 테이블이 조인된 쿼리
4. `<derived2>` 테이블이 `e` 테이블보다 먼저 표기되어 있기 떄문에 `<derived2>` 테이블이 드라이빙, `e` 테이블이 드리븐

<br>

## partitions 칼럼
5.7 버전까지는 옵티마이저가 사용하는 파티션들의 목록은 `EXPLAIN PARTITION` 명령을 통해 확인 가능  
8.0 버전부터 `EXPLAIN` 명령으로 파티션 관련 실행 계획까지 모두 확인 가능  

```sql
## 파티션 키로 사용되는 칼럼은 프라이머리 키를 포함한 모든 유니크 인덱스의 일부
CREATE TABLE employees_2 (
  emp_no int NOT NULL,
  hire_date DATE NOT NULL,
  ...
  PRIMARY KEY (emp_no, hire_date)
) PARTITION BY RANGE COLUMNS(hire_date)
(PARTITION p1986_1990 VALUES LESS THAN ('1991-01-01'),
 PARTITION p1991_1995 VALUES LESS THAN ('1996-01-01'),
 PARTITION p1996_2000 VALUES LESS THAN ('2001-01-01'),
 PARTITION p2001_2005 VALUES LESS THAN ('2006-01-01'));

## employees 테이블의 모든 레코드를 복사
INSERT INTO employees_2 SELECT * FROM employees;
```

<br>

```
mysql> EXPLAIN
         SELECT *
         FROM employees_2
         WHERE hire_date BETWEEN '1999-11-15' AND '2000-01-15';

+----+-------------+-------------+-----------------------+------+-------+
| id | select_type | table       | partitions            | type | rows  |
+----+-------------+-------------+-----------------------+------+-------+
|  1 | SIMPLE      | employees_2 | p1996_2000,p2001_2005 | ALL  | 21743 |
+----+-------------+-------------+-----------------------+------+-------+
```

옵티마이저는 조건을 보고 파티션 키 칼럼 조건이 있다면, 데이터 분포를 분석하지 않고도 파티션 접근 가능  
파티션 프루닝(`partition pruning`)은 불필요한 파티션을 제외하고 쿼리를 수행하기 위해 접근해야 할 것으로 판단된 테이블만 골라내는 과정   
파티션 별로 개별 테이블처럼 별도의 저장 공간을 가지기 때문에 풀 스캔 실행  

<br>

## type 칼럼
type 이후 칼럼은 각 테이블의 레코드를 어떤 방식으로 읽었는지 표시  
MySQL 메뉴얼에서는 `조인 타입`으로 소개  
하나의 단위 조회 쿼리는 접근 방법 중 단 하나만 사용 가능  

<br>

### system
레코드가 1건만 존재하는 테이블 또는 레코드가 없는 테이블을 참조하는 접근 방식  
InnoDB 스토리지 엔진에서는 나타나지 않고, MyISAM 또는 MEMORY 테이블에서만 사용  

```
mysql> CREATE TABLE tb_dual_myisam (fd1 int NOT NULL) ENGINE=MyISAM;
mysql> CREATE TABLE tb_dual_innodb (fd1 int NOT NULL) ENGINE=InnoDB;
mysql> INSERT INTO tb_dual_myisam VALUES (1);
mysql> INSERT INTO tb_dual_innodb VALUES (1);

mysql> EXPLAIN SELECT * FROM tb_dual_myisam;
+----+-------------+----------------+--------+------+-------+
| id | select_type | table          | type   | rows | Extra |
+----+-------------+----------------+--------+------+-------+
|  1 | SIMPLE      | tb_dual_myisam | system |    1 | NULL  |
+----+-------------+----------------+--------+------+-------+

mysql> EXPLAIN SELECT * FROM tb_dual_innodb;
+----+-------------+----------------+------+------+-------+
| id | select_type | table          | type | rows | Extra |
+----+-------------+----------------+------+------+-------+
|  1 | SIMPLE      | tb_dual_innodb | ALL  |    1 | NULL  |
+----+-------------+----------------+------+------+-------+
```

<br>

### const
다른 DBMS에서는 유니크 인덱스 스캔(`UNIQUE INDEX SCAN`)이라고도 표현  
옵티마이저가 쿼리를 최적화하는 단계에서 쿼리를 먼저 실행한 후 통째로 상수화  
아래 조건을 만족하는 경우 const 표시  
- 테이블의 레코드 건수와 관계없이 쿼리가 프라이머리 키나 유니크 키 칼럼을 이용한 조건절 보유
- 반드시 1건을 반환하는 쿼리

```
-- // emp_no 단일 프라이머리키
mysql> EXPLAIN
         SELECT * FROM employees WHERE emp_no = 10001;
+----+-------------+-----------+--------+---------+---------+
| id | select_type | table     | type   | key     | key_len |
+----+-------------+-----------+--------+---------+---------+
|  1 | SIMPLE      | employees | const  | PRIMARY | 4       |
+----+-------------+-----------+--------+---------+---------+

mysql> EXPLAIN
         SELECT COUNT(*)
         FROM employees e1
         WHERE first_name = (SELECT first_name FROM employees e2 WHERE emp_no = 100001);
+----+-------------+-------+-------+--------------+---------+------+
| id | select_type | table | type  | key          | key_len | rows |
+----+-------------+-------+-------+--------------+---------+------+
|  1 | PRIMARY     | e1    | ref   | ix_firstname | 58      |  248 |
|  2 | SUBQUERY    | e2    | const | PRIMARY      | 4       |    1 |
+----+-------------+-------+-------+--------------+---------+------+

-- // (dept_no, emp_no) 복합키
mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE dept_no = 'd005';
+----+-------------+----------+------+---------+--------+
| id | select_type | table    | type | key     | rows   |
+----+-------------+----------+------+---------+--------+
|  1 | SIMPLE      | dept_emp | ref  | PRIMARY | 165571 |
+----+-------------+----------+------+---------+--------+

mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE dept_no = 'd005' AND emp_no = 10001;
+----+-------------+----------+--------+---------+---------+------+
| id | select_type | table    | type   | key     | key_len | rows |
+----+-------------+----------+--------+---------+---------+------+
|  1 | SIMPLE      | dept_emp | const  | PRIMARY | 20      |    1 |
+----+-------------+----------+--------+---------+---------+------+
```

<br>

### eq_ref
여러 테이블이 조인되는 쿼리의 실행 계획에서만 표시  
조인에서 처음 읽은 테이블의 칼럼값을 다음 테이블의 프라이머리 키나 유니크 키 검색 조건에 사용할 때 표시  
다중 칼럼으로 만들어진 프라이머리 키나 유니크 인덱스라면 모든 칼럼이 비교 조건에 사용되어야만 표시  
즉, 조인에서 두번쨰 이후 테이블에서 반드시 1건만 존재한다는 보장이 있어야 사용 가능한 접근 방식  

```
mysql> EXPLAIN
         SELECT * FROM dept_emp de, employees e
         WHERE e.emp_no = de.emp_no AND de.dept_no = 'd005';
+----+-------------+-------+--------+---------+---------+--------+
| id | select_type | table | type   | key     | key_len | rows   |
+----+-------------+-------+--------+---------+---------+--------+
|  1 | SIMPLE      | de    | ref    | PRIMARY | 16      | 165571 |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY | 4       |      1 |
+----+-------------+-------+--------+---------+---------+--------+
```

<br>

### ref
eq_ref 접근 방식과 달리 조인 순서와 관계없이 사용  
프라이머리 키나 유니크 키 등의 제약 조건 없음  
인덱스의 종류와 관계없이 동등 조건으로 검색한 경우 해당 접근 방법 사용  
반환되는 레코드가 반드시 1건이라는 보장이 없으므로 const 또는 eq_ref 접근보다는 느림  
하지만 동등 조건으로만 비교되므로 매우 빠른 레코드 조회 방법  

```
-- // (dept_no, emp_no) 복합키
mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE dept_no = 'd005';
+----+-------------+----------+------+---------+---------+-------+
| id | select_type | table    | type | key     | key_len | ref   |
+----+-------------+----------+------+---------+---------+-------+
|  1 | SIMPLE      | dept_emp | ref  | PRIMARY | 16      | const |
+----+-------------+----------+------+---------+---------+-------+
```

<br>

### fulltext
전문 검색 인덱스를 사용해 레코드를 읽는 접근 방식  
전문 검색 조건은 우선순위가 상당히 높아서 const, eq_ref, ref 접근 방식이 아니라면 일반적으로 전문 인덱스를 사용  
전문 검색은 `MATCH (...) AGAINST (...)` 구문으로 실행, 이때 반드시 테이블에 전문 검색 인덱스 필수  

```sql
CREATE TABLE employee_name (
  emp_no int NOT NULL,
  first_name varchar(14) NOT NULL,
  last_name varchar(16) NOT NULL,
  PRIMARY KEY (emp_no),
  FULLTEXT KEY fx_name (first_name, last_name) WITH PARSER ngram
) ENGINE=InnoDB;
```

```
mysql> EXPLAIN
         SELECT *
         FROM employee_name
         WHERE emp_no = 10001
           AND emp_no BETWEEN 10001 AND 10005
           AND MATCH(first_name, last_name) AGAINST('Facello' IN BOOLEAN MODE);
+----+-------------+---------------+-------+---------+---------+
| id | select_type | table         | type  | key     | key_len |
+----+-------------+---------------+-------+---------+---------+
|  1 | SIMPLE      | employee_name | const | PRIMARY | 4       |
+----+-------------+---------------+-------+---------+---------+

mysql> EXPLAIN
         SELECT *
         FROM employee_name
         WHERE emp_no BETWEEN 10001 AND 10005
           AND MATCH(first_name, last_name) AGAINST('Facello' IN BOOLEAN MODE);
+----+-------------+---------------+----------+---------+-----------------------------------+
| id | select_type | table         | type     | key     | Extra                             |
+----+-------------+---------------+----------+---------+-----------------------------------+
|  1 | SIMPLE      | employee_name | fulltext | fx_name | Using where; Ft_hints: no_ranking |
+----+-------------+---------------+----------+---------+-----------------------------------+
```

<br>

### ref_or_null
ref 접근 방식과 유사하지만 NULL 비교가 추가된 방식  
실무에서 많이 활용되지 않지만 나쁘지 않은 접근 방식  

```
mysql> EXPLAIN
         SELECT * FROM titles
         WHERE to_date = '1985-03-01' OR to_date IS NULL;
+----+-------------+--------+-------------+-----------+---------+-------+------+
| id | select_type | table  | type        | key       | key_len | ref   | rows |
+----+-------------+--------+-------------+-----------+---------+-------+------+
|  1 | SIMPLE      | titles | ref_or_null | ix_todate | 4       | const | 2    |
+----+-------------+--------+-------------+-----------+---------+-------+------+
```

<br>

### unique_subquery
조건절에서 사용될 수 있는 IN(subquery) 형태의 쿼리를 위한 접근 방식  
서브쿼리에서 중복되지 않는 유니크한 값만 반환하는 경우  

```
mysql> SET optimizer_switch = 'semijoin=off';
mysql> EXPLAIN
         SELECT * FROM departments
         WHERE dept_no IN (SELECT dept_no FROM dept_emp WHERE emp_no = 10001);
+----+--------------------+-------------+-----------------+-------------+---------+
| id | select_type        | table       | type            | key         | key_len |
+----+--------------------+-------------+-----------------+-------------+---------+
|  1 | PRIMARY            | departments | index           | ux_deptname | 162     |
|  2 | DEPENDENT SUBQUERY | dept_emp    | unique_subquery | PRIMARY     | 20      |
+----+--------------------+-------------+-----------------+-------------+---------+
```

<br>

### index_subquery
조건절에서 사용될 수 있는 IN(subquery) 형태의 쿼리를 위한 접근 방식  
서브쿼리에서 중복된 값을 반환하는 경우  

<br>

### range
인덱스 레인지 스캔 형태의 접근 방식  
위의 접근 방식들보단 우선순위가 낮지만, 해당 접근 방식만 사용해도 최적의 성능 보장  

```
mysql> EXPLAIN
         SELECT * FROM employees WHERE emp_no BETWEEN 10002 AND 10004;
+----+-------------+-----------+-------+---------+---------+------+
| id | select_type | table     | type  | key     | key_len | rows |
+----+-------------+-----------+-------+---------+---------+------+
|  1 | SIMPLE      | employees | range | PRIMARY | 4       |    3 |
+----+-------------+-----------+-------+---------+---------+------+
```

<br>

### index_merge
2개 이상의 인덱스를 이용해 각각의 검색 결과를 만들고 병합해서 처리하는 방식  
- 여러 인덱스를 읽기 때문에 range 접근 방식보다 효율성 낮음
- 전문 검색 인덱스를 사용하는 쿼리는 적용 불가
- 처리된 결과는 항상 2개 이상 집합이므로 합/교집합 또는 중복 제거와 같은 부가적인 작업 필수

```
mysql> EXPLAIN
         SELECT * FROM employees
         WHERE emp_no BETWEEN 10001 AND 11000
           OR first_name = 'Smith';
+----+-------------+----------------------+---------+------------------------------------------------+
| id | type        | key                  | key_len | Extra                                          |
+----+-------------+----------------------+---------+------------------------------------------------+
|  1 | index_merge | PRIMARY,ix_firstname | 4,58    | Using union(PRIMARY,ix_firstname); Using where |
+----+-------------+----------------------+---------+------------------------------------------------+
```

<br>

### index
인덱스 풀 스캔 접근 방식  
풀 테이블 스캔 방식과 비교하는 레코드 건수는 동일  
일반적으로 인덱스 크기가 데이터 파일 전체보다 작으므로 인덱스 풀 스캔이 풀 테이블 스캔보다 효율적  
- range, const, ref 같은 접근 방식으로 인덱스를 사용하지 못하는 경우
- 인덱스에 포함된 칼럼만으로 처리할 수 있는 걍우(커버링 인덱스)
- 인덱스를 이용해 정렬 또는 그루핑 작업이 가능한 경우

```
mysql> EXPLAIN
         SELECT * FROM departments ORDER BY dept_name DESC LIMIT 10;
+----+-------------+-------------+-------+-------------+---------+------+
| id | select_type | table       | type  | key         | key_len | rows |
+----+-------------+-------------+-------+-------------+---------+------+
|  1 | SIMPLE      | departments | index | ux_deptname | 162     |    9 |
+----+-------------+-------------+-------+-------------+---------+------+
```

<br>

### ALL
풀 테이블 스캔 접근 방식  
지금까지 접근 방식으로는 처리할 수 없을 때 가장 마지막에 선택하는 비효율적인 방식  

<br>

## possible_keys 칼럼
옵티마이저가 최적의 실행 계획을 수립하기 위한 후보로 선정했던 접근 방식의 인덱스 목록  
사용될 가능성이 조금이라도 있었던 인덱스의 목록  
특별한 경우가 아니라면 그냥 무시해도 되는 칼럼  

<br>

## key 칼럼
possible_keys 칼럼과는 다르게 최종 선택된 실행 계획에서 사용하는 인덱스  
만약 인덱스를 전혀 사용하지 못하는 경우 NULL 표시  
프라이머리 키는 별도의 이름을 부여할 수 없으며 기본적으로 `PRIMARY`로 표시  

<br>

## key_len 칼럼
인덱스의 각 레코드에서 몇 바이트까지 키로 사용했는지 표시  
다중 칼럼 인덱스를 사용했다면 몇 개의 칼럼까지 사용했는지 표시  

```
-- // (dept_no, emp_no) 복합키
mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE dept_no = 'd005';
+----+-------------+----------+------+---------+---------+
| id | select_type | table    | type | key     | key_len |
+----+-------------+----------+------+---------+---------+
|  1 | SIMPLE      | dept_emp | ref  | PRIMARY | 16      |
+----+-------------+----------+------+---------+---------+

mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE dept_no = 'd005' AND emp_no = 10001;
+----+-------------+----------+--------+---------+---------+
| id | select_type | table    | type   | key     | key_len |
+----+-------------+----------+--------+---------+---------+
|  1 | SIMPLE      | dept_emp | const  | PRIMARY | 20      |
+----+-------------+----------+--------+---------+---------+
```

<br>

## ref 칼럼
접근 방식이 ref인 경우 동등 참조 조건으로 어떤 값이 제공됐는지 표시  
상수값인 경우 const 표시  
콜레이션 변환이나 값 자체가 아닌 연산을 거친 참조하면 func 표시  

```
mysql> EXPLAIN
         SELECT *
         FROM employee e, dept_emp de
         WHERE e.emp_no = de.emp_no;
+----+-------------+-------+--------+---------+---------------------+
| id | select_type | table | type   | key     | ref                 |
+----+-------------+-------+--------+---------+---------------------+
|  1 | SIMPLE      | de    | ALL    | NULL    | NULL                |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY | employees.de.emp_no |
+----+-------------+-------+--------+---------+---------------------+

mysql> EXPLAIN
         SELECT *
         FROM employees e, dept_emp de
         WHERE e.emp_no = (de.emp_no - 1);
+----+-------------+-------+--------+---------+------+
| id | select_type | table | type   | key     | ref  |
+----+-------------+-------+--------+---------+------+
|  1 | SIMPLE      | de    | ALL    | NULL    | NULL |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY | func |
+----+-------------+-------+--------+---------+------+
```

<br>

## rows 칼럼
옵티마이저는 실행 계획을 수립할때 얼마나 많은 레코드 읽기/비교가 필요한지 예측  
실행 계획의 효율성 판단을 위해 예측했던 레코드 건수 표시  
반환하는 레코드 예측치가 아닌 쿼리를 처리하기 위해 확인한 레코드 예측치를 의미  

```
mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE from_date >= '1985-01-01';
+----+-------------+----------+------+------+---------+--------+
| id | select_type | table    | type | key  | key_len | rows   |
+----+-------------+----------+------+------+---------+--------+
|  1 | SIMPLE      | dept_emp | ALL  | NULL | NULL    | 331143 |
+----+-------------+----------+------+------+---------+--------+

mysql> EXPLAIN
         SELECT * FROM dept_emp WHERE from_date >= '2002-07-01';
+----+-------------+----------+-------+-------------+---------+------+
| id | select_type | table    | type  | key         | key_len | rows |
+----+-------------+----------+-------+-------------+---------+------+
|  1 | SIMPLE      | dept_emp | range | ix_fromdate | 3       |  292 |
+----+-------------+----------+-------+-------------+---------+------+
```

<br>

## filtered 칼럼
조건에 맞는 레코드 건수를 예측해서 표시  
해당 값을 얼마나 정확히 예측하는지에 따라 조인의 성능 차이 발생  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e, salaries s
         WHERE e.first_name = 'Matt'
           AND e.hire_date BETWEEN '1990-01-01' AND '1991-01-01'
           AND s.emp_no = e.emp_no
           AND s.from_date BETWEEN '1990-01-01' AND '1991-01-01'
           AND s.salary BETWEEN 50000 AND 60000;
+----+-------------+-------+------+--------------+------+----------+
| id | select_type | table | type | key          | rows | filtered |
+----+-------------+-------+------+--------------+------+----------+
|  1 | SIMPLE      | e     | ref  | ix_firstname |  233 |    16.03 |
|  1 | SIMPLE      | s     | ref  | PRIMARY      |   10 |     0.48 |
+----+-------------+-------+------+--------------+------+----------+

mysql> EXPLAIN
         SELECT /*+ JOIN_ORDER(s, e) */ *
         FROM employees e, salaries s
         WHERE e.first_name = 'Matt'
           AND e.hire_date BETWEEN '1990-01-01' AND '1991-01-01'
           AND s.emp_no = e.emp_no
           AND s.from_date BETWEEN '1990-01-01' AND '1991-01-01'
           AND s.salary BETWEEN 50000 AND 60000;
+----+-------------+-------+--------+-----------+------+----------+
| id | select_type | table | type   | key       | rows | filtered |
+----+-------------+-------+--------+-----------+------+----------+
|  1 | SIMPLE      | s     | range  | ix_salary | 3314 |    11.11 |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY   |    1 |     5.00 |
+----+-------------+-------+--------+-----------+------+----------+
```

<br>

## Extra 칼럼
주로 내부적인 처리 알고리즘에 대해 깊이있는 내용을 표시  
MySQL 서버 버전이 업그레이드되고 최적화 기능이 도일될수록 새로운 내용 추가 예정  

<br>

### const row not found
쿼리 실행 계획에서 const 접근 방식으로 테이블을 읽었지만 레코드가 1건도 존재하지 않는 경우  

<br>

### Deleting all rows
MyISAM 스토리지 엔진과 같이 스토리지 엔진 핸들러 차원에서 테이블의 모든 레코드를 삭제하는 기능을 제공하는 경우  
8.0 버전부터 InnoDB, MyISAM 모두 더 이상 표시되지 않음  
조건절 없는 DELETE 쿼리보단 `TRUNCATE TABLE` 명령 권장  

<br>

### Distinct
중복처리를 위해 조인하지 않아도 되는 항목은 모두 무시  

<img width="650" alt="distinct" src="https://github.com/user-attachments/assets/2ecd40e5-3a31-4b21-9e89-503993ecedb1" />

```
mysql> EXPLAIN
         SELECT DISTINCT d.dept_no
         FROM departments d, dept_emp de
         WHERE de.dept_no = d.dept_no;
+----+-------------+-------+-------+-------------+------------------------------+
| id | select_type | table | type  | key         | Extra                        |
+----+-------------+-------+-------+-------------+------------------------------+
|  1 | SIMPLE      | d     | index | ux_deptname | Using index; Using temporary |
|  1 | SIMPLE      | de    | ref   | PRIMARY     | Using index; Distinct        |
+----+-------------+-------+-------+-------------+------------------------------+
```

<br>

### FirstMatch
세미 조인 최적화 중 FirstMatch 전략이 사용된 경우  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
         WHERE e.first_name = 'Matt'
           AND e.emp_no IN (
             SELECT t.emp_no FROM titles t
             WHERE t.from_date BETWEEN '1995-01-01' AND '1995-01-30'
           );
+----+-------+------+--------------+------+-----------------------------------------+
| id | table | type | key          | rows | Extra                                   |
+----+-------+------+--------------+------+-----------------------------------------+
|  1 | e     | ref  | ix_firstname |  233 | NULL                                    |
|  1 | t     | ref  | PRIMARY      |    1 | Using where; Using index; FirstMatch(e) |
+----+-------+------+--------------+------+-----------------------------------------+
```

<br>

### Full scan on NULL key
`col1 IN (SELECT col2 FROM ...)` 같은 조건을 가진 쿼리에서 자주 발생  
`col1` 값이 NULL인 경우 `NULL IN (SELECT col2 FROM ,,,)` 형태로 변경  
- 서브쿼리가 1건이라도 결과 레코드를 가진다면 최종 비교 결과는 NULL
- 서브쿼리가 1건도 결과 레코드를 가지지 않는다면 최종 비교 결과는 FALSE

해당 비교 과정에서 `col1` 값이 NULL인 경우 서브쿼리에 사용된 테이블에 대한 풀 테이블 스캔 필수  
만약 `col1` 칼럼이 NOT NULL 조건이 정의된 경우 이러한 차선책을 사용하지 않음  

```
mysql> EXPLAIN
         SELECT d.dept_no, NULL IN (SELECT id.dept_name FROM departments d2) FROM departments d1;
+----+-------------+-------+----------------+-------------------------------------------------+
| id | select_type | table | type           | Extra                                           |
+----+-------------+-------+----------------+-------------------------------------------------+
|  1 | PRIMARY     | d1    | index          | Using index                                     |
|  2 | SUBQUERY    | d2    | index_subquery | Using where; Using index; Full scan on NULL key |
+----+-------------+-------+----------------+-------------------------------------------------+
```

<br>

### Impossible HAVING
쿼리에 사용된 HAVING 조건에 만족하는 레코드가 없는 경우  
해당 메시지가 출력됐다면 쿼리가 제대로 작성되지 못한 경우가 대부분  

```
mysql> EXPLAIN
         SELECT e.emp_no, COUNT(*) AS cnt
         FROM employees e
         WHERE e.emp_no = 10001
         GROUP BY e.emp_no
         HAVING e.emp_no IS NULL;
+----+-------------+-------+------+------+-------------------+
| id | select_type | table | type | key  | Extra             |
+----+-------------+-------+------+------+-------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL | Impossible HAVING |
+----+-------------+-------+------+------+-------------------+
```

<br>

### Impossible WHERE
WHERE 조건절이 항상 FALSE가 될 수 밖에 없는 경우  

```
mysql> EXPLAIN
         SELECT * FROM employees WHERE emp_no IS NULL;
+----+-------------+-------+------+------------------+
| id | select_type | table | type | Extra            |
+----+-------------+-------+------+------------------+
|  1 | SIMPLE      | NULL  | NULL | Impossible WHERE |
+----+-------------+-------+------+------------------+
```

<br>

### LooseScan
세미 조인 최적화 중에서 LooseScan 최적화 전략 사용시 표시  

```
mysql> EXPLAIN
         SELECT * FROM departments d WHERE d.dept_no IN (
           SELECT de.dept_no FROM dept_emp de);
+----+-------+--------+---------+--------+------------------------+
| id | table | type   | key     | rows   | Extra                  |
+----+-------+--------+---------+--------+------------------------+
|  1 | de    | index  | PRIMARY | 331143 | Using index; LooseScan |
|  1 | d     | eq_ref | PRIMARY |      1 | NULL                   |
+----+-------+--------+---------+--------+------------------------+
```

<br>

### No matching min/max row
`MIN()` 또는 `MAX()` 같은 집합 함수가 있는 쿼리의 조건절에 일치하는 레코드가 한 건도 없는 경우  

```
mysql> EXPLAIN
         SELECT MIN(dept_no), MAX(dept_no)
         FROM dept_emp WHERE dept_no = '';
+----+-------------+-------+------+------+-------------------------+
| id | select_type | table | type | key  | Extra                   |
+----+-------------+-------+------+------+-------------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL | No matching min/max row |
+----+-------------+-------+------+------+-------------------------+
```

<br>

### no matching row in const table
const 방식으로 접근할 때 일치하는 레코드가 없는 경우  

```
mysql> EXPLAIN
         SELECT *
         FROM dept_emp de,
           (SELECT emp_no FROM employees WHERE emp_no = 0) tb1
         WHERE tb1.emp_no = de.emp_no AND de.dept_no = 'd005';
+----+-------------+-------+------+------+--------------------------------+
| id | select_type | table | type | key  | Extra                          |
+----+-------------+-------+------+------+--------------------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL | no matching row in const table |
+----+-------------+-------+------+------+--------------------------------+
```

<br>

### No matching rows after partition pruning
파티션된 테이블에 대한 UPDATE, DELETE 명령 실행 계획에서 대상 파티션이 없는 경우 표시  

```
mysql> EXPLAIN DELETE FROM employees_parted WHERE hire_date >= '2020-01-01';
+----+-------------+-------+------------+------+------------------------------------------+
| id | select_type | table | partitions | type | Extra                                    |
+----+-------------+-------+------------+------+------------------------------------------+
|  1 | DELETE      | NULL  | NULL       | NULL | No matching rows after partition pruning |
+----+-------------+-------+------------+------+------------------------------------------+
```

<br>

### No tables used
FROM 절이 없는 쿼리나 FROM DUAL 형태의 쿼리 실행 계획에서 표시  

```
mysql> EXPLAIN SELECT 1;
mysql> EXPLAIN SELECT 1 FROM dual;
+----+-------------+-------+------+------+----------------+
| id | select_type | table | type | key  | Extra          |
+----+-------------+-------+------+------+----------------+
|  1 | SIMPLE      | NULL  | NULL | NULL | No tables used |
+----+-------------+-------+------+------+----------------+
```

<br>

### Not exists
안티 조인(`Anti-JOIN`) 형식인 `NOT IN(subquery)` 또는 `NOT EXISTS` 연산자로 처리하는 경우  
주로 아우터 조인을 이용해 안티 조인을 수행하는 쿼리에서 표시  
조인 조건에 일치하는 레코드가 여러 건 있다고 하더라도 딱 1건만 조회하고 처리를 완료하는 최적화 의미  

```
mysql> EXPLAIN
         SELECT *
         FROM dept_emp de
           LEFT JOIN departments d ON de.dept_no = d.dept_no
         WHERE d.dept_no IS NULL;
+----+-------------+-------+--------+---------+-------------------------+
| id | select_type | table | type   | key     | Extra                   |
+----+-------------+-------+--------+---------+-------------------------+
|  1 | SIMPLE      | de    | ALL    | NULL    | NULL                    |
|  1 | SIMPLE      | d     | eq_ref | PRIMARY | Using where; Not exists |
+----+-------------+-------+--------+---------+-------------------------+
```

<br>

### Plan isn't ready yet
8.0 버전부터 다른 커넥션의 실행 중인 쿼리의 실행 계획 조회 가능  
다른 커넥션에서 아직 쿼리 실행 계획을 수립하지 못한 상태인 경우  
해당 메시지가 출력된 경우 여유 시간을 더 주고, 다시 `EXPLAIN FOR CONNECTION` 명령을 실행하면 해결  

```
mysql> SHOW PROCESSLIST;
+----+------+---------+-------+------------+----------------------------------------+
| Id | User | Command | Time  | State      | Info                                   |
+----+------+---------+-------+------------+----------------------------------------+
|  8 | root | Query   |     7 | User sleep | SELECT * FROM employees WHERE SLEEP(1) |
|  9 | root | Query   |     0 | starting   | SHOW PROCESSLIST                       |
+----+------+---------+-------+------------+----------------------------------------+

mysql> EXPLAIN FOR CONNECTION 8;
+----+-------------+-----------+------+--------+-------------+
| id | select_type | table     | type | rows   | Extra       |
+----+-------------+-----------+------+--------+-------------+
|  1 | SIMPLE      | employees | ALL  | 300473 | Using where |
+----+-------------+-----------+------+--------+-------------+
```

<br>

### Range checked for each record(index map: N)
레코드마다 인덱스 레인지 스캔을 체크  
각 레코드마다 풀 스캔과 인덱스 레인지 스캔 중 하나를 골라야하는 경우  
type 칼럼은 ALL로 표시되지만 `index map`에 표시된 후보 인덱스를 사용할지 여부를 항상 검토  
후보 인덱스값은 16진수로 표시되며, 해당 값을 이진수로 변경해서 `SHOW CREATE TABLE` 명령으로 나오는 인덱스 순번으로 배치  
각 자리가 1인 경우에 후보 인덱스  

<img width="450" alt="rangecheckedforeachrecord" src="https://github.com/user-attachments/assets/ba41d7f6-4ca0-4aff-a0b3-5d73157ddfa4" />

```
mysql> EXPLAIN
         SELECT *
         FROM employees e1, employees e2
         WHERE e2.emp_no >= e1.emp_no;
+----+-------------+-------+------+------------------------------------------------+
| id | select_type | table | type | Extra                                          |
+----+-------------+-------+------+------------------------------------------------+
|  1 | SIMPLE      | e1    | ALL  | NULL                                           |
|  1 | SIMPLE      | e2    | ALL  | Range checked for each record (index map: 0x1) |
+----+-------------+-------+------+------------------------------------------------+
```

<br>

### Recursive
8.0 버전부터 CTE(`Common Table Expression`)를 이용한 재귀 쿼리 작성 가능  
WITH 구문을 이용한 CTE가 사용됐다고 무조건 표시되지 않고 꼭 구문 안에 CTE가 재귀적으로 사용되야 표시  

```
mysql> EXPLAIN
         WITH RECURSIVE cte (n) AS
         (
           SELECT 1
           UNION ALL
           SELECT n + 1 FROM cte WHERE n < 5
         )
         SELECT * FROM cte;
+----+-------------+------------+------+------+------------------------+
| id | select_type | table      | type | key  | Extra                  |
+----+-------------+------------+------+------+------------------------+
|  1 | PRIMARY     | <derived2> | ALL  | NULL | NULL                   |
|  2 | DERIVED     | NULL       | NULL | NULL | No tables used         |
|  3 | UNION       | cte        | ALL  | NULL | Recursive; Using where |
+----+-------------+------------+------+------+------------------------+
```

### Rematerialize
8.0 버전부터 래터럴 조인 기능 추가  
선행 테이블의 레코드 별로 서브쿼리를 실행해서 그 결과를 매번 임시 테이블에 저장  

```
mysql> EXPLAIN
         SELECT * FROM employees e
         LEFT JOIN LATERAL (
           SELECT *
           FROM salaries s
           WHERE s.emp_no = e.emp_no
           ORDER BY s.from_date DESC LIMIT 2) s2 ON s2.emp_no = e.emp_no
         WHERE e.first_name = 'Matt';
+----+-------------------+------------+------+--------------+----------------------------+
| id | select_type       | table      | type | key          | Extra                      |
+----+-------------------+------------+------+--------------+----------------------------+
|  1 | PRIMARY           | e          | ref  | ix_firstname | Rematerialize (<derived2>) |
|  1 | PRIMARY           | <derived2> | ref  | <auto_key0>  | NULL                       |
|  2 | DEPENDENT DERIVED | s          | ref  | PRIMARY      | Using filesort             |
+----+-------------------+------------+------+--------------+----------------------------+
```

<br>

### Select tables optimized away
인덱스를 오름차순 또는 내림차순으로 1건만 읽는 형태 최적화가 적용된 경우  

```
mysql> EXPLAIN
         SELECT MAX(emp_no), MIN(emp_no) FROM employees;

mysql> EXPLAIN
         SELECT MAX(from_date), MIN(from_date) FROM salaries WHERE emp_no = 10002;
+----+-------------+-------+------+------+------------------------------+
| id | select_type | table | type | key  | Extra                        |
+----+-------------+-------+------+------+------------------------------+
|  1 | SIMPLE      | NULL  | NULL | NULL | Select tables optimized away |
+----+-------------+-------+------+------+------------------------------+
```

<br>

### Start temporary, End temporary
세미 조인 최적화 중 Duplicate Weed-out 최적화 전략이 사용된 경우  
중복 건을 제거하기 위해 내부 임시 테이블을 사용할때 첫번째 테이블은 Start temporary, 마지막 테이블은 End temporary 표시  

```
mysql> EXPLAIN
         SELECT * FORM employees e
         WHERE e.emp_no IN (SELECT s.emp_no FROM salaries s WHERE s.salary > 150000);
+----+-------------+-------+--------+-----------+-------------------------------------------+
| id | select_type | table | type   | key       | Extra                                     |
+----+-------------+-------+--------+-----------+-------------------------------------------+
|  1 | SIMPLE      | s     | range  | ix_salary | Using where; Using index; Start temporary |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY   | End temporary                             |
+----+-------------+-------+--------+-----------+-------------------------------------------+
```

<br>

### unique row not found
각각 유니크 칼럼으로 아우터 조인을 수행하는 쿼리에서 아우터 테이블에 일치하는 레코드가 없는 경우  

```
mysql> EXPLAIN
         SELECT t1.fdpk
         FROM tb_test1 t1
         LEFT JOIN tb_test2 t2 ON t2.fdpk = t1.fdpk WHERE t1.fdpk = 2;
+----+-------------+-------+-------+---------+------+----------------------+
| id | select_type | table | type  | key     | rows | Extra                |
+----+-------------+-------+-------+---------+------+----------------------+
|  1 | SIMPLE      | t1    | const | PRIMARY |    1 | Using index          |
|  1 | SIMPLE      | t2    | const | PRIMARY |    0 | unique row not found |
+----+-------------+-------+-------+---------+------+----------------------+
```

<br>

### Using filesort
인덱스를 사용하지 못하고 정렬을 수행하는 경우  

```
mysql> EXPLAIN
         SELECT * FROM employees
         ORDER BY last_name DESC;
+----+-------------+-----------+------+------+--------+----------+----------------+
| id | select_type | table     | type | key  | rows   | filtered | Extra          |
+----+-------------+-----------+------+------+--------+----------+----------------+
|  1 | SIMPLE      | employees | ALL  | NULL | 300363 |   100.00 | Using filesort |
+----+-------------+-----------+------+------+--------+----------+----------------+
```

<br>

### Using index(커버링 인덱스)
인덱스만 읽어서 처리할 수 있는 경우  
type 칼럼의 index 표기와는 반대되는 개념(인덱스 풀 스캔)  

```
mysql> EXPLAIN
         SELECT emp_no, first_name
         FROM employees
         WHERE first_name BETWEEN 'Babette' AND 'Gad';
+----+-------------+-----------+-------+--------------+-------+--------------------------+
| id | select_type | table     | type  | key          | rows  | Extra                    |
+----+-------------+-----------+-------+--------------+-------+--------------------------+
|  1 | SIMPLE      | employees | range | ix_firstname | 93802 | Using where; Using index |
+----+-------------+-----------+-------+--------------+-------+--------------------------+
```
















