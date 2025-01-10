# 쿼리 힌트
버전 업그레이드에 따라 통계 정보나 옵티마이저 최적화 기법이 다양해지면서 쿼리 실행 계획이 성숙  
하지만 여전히 부족한 실행 계획을 수립하는 경우 존재  
MySQL 서버에서 사용 가능한 쿼리 힌트는 인덱스 힌트와 옵티마이저 힌트 두가지로 구분 가능  

<br>

## 인덱스 힌트
`STRAIGHT_JOIN`, `USE INDEX` 등을 포함한 인덱스 힌트들은 모두 옵티마이저 힌트가 도입되기 전에 사용하던 기능  
이들은 모두 SQL 문법에 맞게 사용해야 하기때문에 ANSI-SQL 표준 문법을 준수하지 못함  
5.6 버전부터 추가된 옵티마이저 힌트들은 모두 다른 RDBMS에서 주석으로 해석하기 때문에 ANSI-SQL 표준 준수  
인덱스 힌트는 `SELECT` 또는 `UPDATE` 명령에서만 사용 가능  

<br>

### STRAIGHT_JOIN
옵티마이저 힌트인 동시에 조인 키워드  
여러 개의 테이블이 조인되는 경우 조인 순서를 고정하는 역할  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e, dept_emp de,, departments d
         WHERE e.emp_no = de.emp_no AND d.ept_no = de.dept_no;

+----+-------------+-------+--------+-------------+-------+-------------+
| id | select_type | table | type   | key         | rows  | Extra       |
+----+-------------+-------+--------+-------------+-------+-------------+
|  1 | SIMPLE      | d     | index  | ux_deptname |     9 | Using index |
|  1 | SIMPLE      | de    | ref    | PRIMARY     | 41392 | NULL        |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY     |     1 | NULL        |
+----+-------------+-------+--------+-------------+-------+-------------+
```

해당 실행 계획에선 `departments` 테이블을 드라이빙 테이블로 선택  
일반적으로 조인을 하기 위한 칼럼들의 인덱스 여부로 조인 순서가 결정  
또한 조건절에 만족하는 레코드가 가장 적은 테이블을 드라이빙 테이블로 선택  

<br>

```
mysql> EXPLAIN
         SELECT /*! STRAIGHT_JOIN */
           e.first_name, e.last_name, d.dept_name
         FROM employees e, dept_emp de,, departments d
         WHERE e.emp_no = de.emp_no AND d.ept_no = de.dept_no;

+----+-------------+-------+--------+-------------------+--------+-------------+
| id | select_type | table | type   | key               | rows   | Extra       |
+----+-------------+-------+--------+-------------------+--------+-------------+
|  1 | SIMPLE      | e     | ALL    | NULL              | 300473 | NULL        |
|  1 | SIMPLE      | de    | ref    | ix_empno_fromdate |      1 | Using index |
|  1 | SIMPLE      | d     | eq_ref | PRIMARY           |      1 | NULL        |
+----+-------------+-------+--------+-------------------+--------+-------------+
```

`STRAIGHT_JOIN` 힌트는 옵티마이저가 FROM 절에 명시된 테이블의 순서대로 조인을 수행하도록 유도  
아래와 같은 기준에 맞게 조인 순서가 결정되지 않는 경우 사용  
- 임시 테이블과 일반 테이블의 조인  
  거의 일반적으로 임시 테이블을 드라이빙 테이블로 선정하는 것을 권장  
  일반 테이블의 조인 칼럼에 인덱스가 없는 경우 레코드 건수가 작은 쪽을 드라이빙으로 선택하는 것을 권장  

- 임시 테이블끼리 조인  
  항상 인덱스가 없기 때문에 크기가 작은 테이블을 드라이빙 테이블로 선정하는 것을 권장  

- 일반 테이블끼리 조인  
  양쪽 테이블 모두 조인 칼럼에 인덱스가 있거나 모두 없는 경우에는 레코드 건수가 적은 테이블을 드라이빙 테이블로 선정하는 것을 권장  
  그 이외에는 조인 칼럼에 인덱스가 없는 테이블을 드라이빙 테이블로 선정하는 것을 권장  

<br>

### USE INDEX / FORCE INDEX / IGNORE INDEX
조인 순서를 변경하는 것 다음으로 자주 사용되는 인덱스 힌트  
인덱스 힌트는 사용하려는 인덱스를 가지는 테이블 뒤에 힌트를 명시 필수  

- `USE INDEX`  
  옵티마이저에게 특정 테이블의 인덱스를 사용하도록 권장  
  대부분의 경우 옵티마이저는 사용자 힌트를 채택하지만 항상 그 인덱스를 사용하는 것은 아님  

- `FORCE INDEX`  
  `USE INDEX` 힌트와 다른 것은 없지만, 옵티마이저에게 미치는 영향이 더 강한 힌트  
  `USE INDEX` 힌트 자체도 영향이 강해서 거의 사용할 필요없음  

- `IGNORE INDEX`  
  옵티마이저에게 특정 테이블의 인덱스를 사용하지 못하도록 권장  
  때때로 풀 테이블 스캔을 사용하도록 유도하기 위해 사용  

<br>

해당 인덱스 힌트는 모두 용도를 명시 가능  
특별한 용도가 명시되지 않는 경우 주어진 인덱스를 3가지 용도로 사용 

- `USE INDEX FOR JOIN`  
  테이블 간의 조인뿐만 아니라 레코드 검색을 위한 용도까지 포함  
  하나의 테이블로부터 데이터를 검색하는 작업도 JOIN이라고 표현  

- `USE INDEX FOR ORDER`  
  명시된 인덱스를 정렬 용도로만 사용할 수 있게 제한  

- `USE INDEX FOR GROUP`  
  명시된 인덱스를 그루핑 용도로만 사용할 수 있게 제한  

<br>

```sql
SELECT * FROM employees WHERE emp_no = 10001;
SELECT * FROM employees FORCE INDEX(primary) WHERE emp_no = 10001;
SELECT * FROM employees USE INDEX(primary) WHERE emp_no = 10001;

SELECT * FROM employees IGNORE INDEX(primary) WHERE emp_no = 10001;
SELECT * FROM employees FORCE INDEX(ix_firstname) WHERE emp_no = 10001;
```

해당 쿼리는 원래도 프라이머리 키를 이용한 실행 계획 생성  
하지만 5.5 이전 버전에서는 터무니 없는 인덱스 힌트롤 통해 쿼리 성능이 더욱 감소 가능  

<br>

### SQL_CALC_FOUND_ROWS
`LIMIT` 명령을 사용한 경우 조건 만족 레코드가 아무리 많아도 명시된 레코드를 찾으면 즉시 검색 종료  
하지만 해당 힌트가 포함된 경우 끝까지 검색 수행  
`FOUND_ROWS()` 함수를 이용해서 `LIMIT`을 제외한 조건을 만족하는 레코드가 전체 몇 건인지 조회 가능  

```
mysql> SELECT SQL_CALC_FOUND_ROWS * FROM employees LIMIT 5;
mysql> SELECT FOUND_ROWS() AS total_record_cound;
+--------------------+
| total_record_count |
+--------------------+
|             300014 |
+--------------------+
```

<br>

해당 힌트는 성능 향상을 위한 힌트가 아닌 개발자 편의를 위한 힌트  
일반적인 관점에서 본다면 해당 힌트보단 레코드 카운터용 쿼리와 데이터를 조회하는 쿼리는 분리하는 것 권장  

<br>

## 옵티마이저 힌트
8.0 버전부터 사용 가능한 힌트 종류가 다양하며, 힌트가 미치는 영향 범위도 다양  

<br>

### 옵티아미저 힌트 종류
옵티마이저 힌트는 영향 범위에 따라 4개 그룹으로 분리 가능  
- 인덱스: 특정 인덱스의 이름을 사용할 수 있는 옵티마이저 힌트
- 테이블: 특정 테이블의 이름을 사용할 수 있는 옵티마이저 힌트
- 쿼리 블록: 특정 쿼리 블록에 사용할 수 있는 옵티마이저 힌트
- 글로벌: 전체 쿼리에 대해서 영향을 미치는 힌트  

| 힌트 이름 | 설명 | 영향 범위 |
|--|--|--|
| MAX_EXECUTION_TIME | 쿼리 실행 시간 제한 | 글로벌 |
| RESOURCE_GROUP | 쿼리 실행 리소스 그룹 설정 | 글로벌 |
| SET_VAR | 쿼리 실행을 위한 시스템 변수 제어 | 글로벌 |
| SUBQUERY | 서브 쿼리 세미 조인 최적화 전략 제어 | 쿼리 블록 |
| BKA <br> NO_BKA | BKA(Batched Key Access) 조인 사용 여부 제어 | 쿼리 블록<br> 테이블 |
| BNL <br> NO_BNL | 블록 네스티드 루프 조인 사용 여부 제어 | 쿼리 블록<br> 테이블 |
| DERIVED_CONDITION_PUSHDOWN <br> NO_DERIVED_CONDITION_PUSHDOWN | 외부 쿼리 조건을 서브쿼리로 옮기는 최적화 사용 여부 제어 | 쿼리 블록<br> 테이블 |
| HASH_JOIN <br> NO_HASH_JOIN | 해시 조인 사용 여부 제어 | 쿼리 블록<br> 테이블 |
| JOIN_FIXED_ORDER | FROM 절에 명시된 테이블 순서대로 조인 실행 | 쿼리 블록<br> 테이블 |
| JOIN_ORDER | 힌트에 명시된 테이블 순서대로 조인 실행 | 쿼리 블록 |
| JOIN_PREFIX | 힌트에 명시된 테이블을 조인의 드라이빙 테이블로 조인 실행 | 쿼리 블록 |
| JOIN_SUFFIX | 힌트에 명시된 테이블을 조인의 드리븐 테이블로 조인 실행 | 쿼리 블록 |
| QB_NAME | 쿼리 블록의 이름 설정을 위한 힌트 | 쿼리 블록 |
| SEMIJOIN <br> NO_SEMIJOIN | 서브쿼리 세미 조인 최적화 전략 제어 | 쿼리 블록 |
| MERGE <br> NO_MERGE | 파생 테이블이나 뷰를 외부 쿼리 블록으로 병합하는 최적화 수행 여부 제어 | 테이블 |
| INDEX_MERGE <br> NO_INDEX_MERGE | 인덱스 병합 실행 계획 사용 여부 제어 | 테이블 |
| MRR <br> NO_MRR | MRR(Multi-Range Read) 사용 여부 제어 | 테이블<br> 인덱스 |
| NO_ICP | ICP(인덱스 컨디션 푸시다운) 최적화 전략 사용 여부 제어 | 테이블<br> 인덱스 |
| NO_RANGE_OPTIMIZATION | 인덱스 레인지 엑세스 비활성화 | 테이블<br> 인덱스 |
| SKIP_SCAN <br> NO_SKIP_SCAN | 인덱스 스킵 스캔 사용 여부 제어 | 테이블<br> 인덱스 |
| INDEX <br> NO_INDEX | GROUP BY, ORDER BY, WHERE 절 처리를 위한 인덱스 사용 여부 제어 | 인덱스 |
| GROUP_INDEX <br> NO_GROUP_INDEX | GROUP BY 절의 처리를 위한 인덱스 사용 여부 제어 | 인덱스 |
| JOIN_INDEX <br> NO_JOIN_INDEX | WHERE 절의 처리를 위한 인덱스 사용 여부 제어 | 인덱스 |
| ORDER_INDEX <br> NO_ORDER_INDEX | ORDER BY 절의 처리를 위한 인덱스 사용 여부 제어 | 인덱스 |

<br>

```
mysql> EXPLAIN
         SELECT /*+ NO_INDEX(ix_firstname) */ *
         FROM employees
         WHERE first_name = 'Matt';
1 row in set, 2 warnings (0.00 sec)

mysql> SHOW WARNING;
+---------+------+-----------------------------------------------------------------+
| Level   | Code | Message                                                         |
+---------+------+-----------------------------------------------------------------+
| Warning | 3128 | Unresolved name `ix_firstname`@`select#1` fro NO_INDEX hint     |
| Note    | 1003 | /* select#1 */ select `employees`.`employees`.`emp_no` AS `em.. |
+---------+------+-----------------------------------------------------------------+
```

모든 인덱스 수준의 힌트는 반드시 테이블명 선행 필수  
옵티마이저 힌트가 문법에 맞지 않은 경우 경고 메시지 표시  

<br>

```
mysql> EXPLAIN
         SELECT /*+ JOIN_ORDER(e, s@subq1) */
           COUNT(*)
         FROM employees e
         WHERE e.first_name = 'Matt'
           AND e.emp_no IN (
             SELECT /*+ QB_NAME(subq1) */ s.emp_no
             FROM salaries s
             WHERE s.salary BETWEEN 50000 AND 50500);

+----+-------------+-------+--------------+----------------------------+
| id | select_type | table | key          | Extra                      |
+----+-------------+-------+--------------+----------------------------+
|  1 | SIMPLE      | e     | ix_firstname | Using index                |
|  1 | SIMPLE      | s     | PRIMARY      | Using where; FirstMatch(e) |
+----+-------------+-------+--------------+----------------------------+
```

특정 쿼리 블록에 영향을 미치는 옵티마이저 힌트는 그 쿼리 블록 내에서 사용 가능, 또한 외부 쿼리 블록에서도 사용 가능  
이처럼 특정 쿼리 블록을 외부 쿼리 블록에서 사용하려면 `QB_NAME()` 힌트를 이용해서 해당 쿼리 블록에 이름 부여 필수  

<br>

### MAX_EXECUTION_TIME
옵티마이저 힌트 중에서 유일하게 쿼리 실행 계획에 영향을 미치지 않는 힌트  
단순히 쿼리 최대 실행 시간을 설정하는 힌트  
밀리초 단위의 시간을 설정하고 쿼리가 지정된 시간을 초과하면 실패  

```
mysql> SELECT /*+ MAX_EXECUTION_TIME(100) */ *
         FROM employees
         ORDER BY last_name LIMIT 1;

ERROR 3024 (HY000): Query execution was interrupted, maximum statement execution time exceeded
```

<br>

### SET_VAR
























