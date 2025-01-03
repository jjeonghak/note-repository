# 고급 최적화
실행 계획을 수립할 때 통계 정보와 옵티마이저 옵션을 결합해서 최적의 실행 계획 수립  
조인 관련 옵티마이저 옵션과 옵티마이저 스위치로 구분 가능  

<br>

## 옵티마이저 스위치 옵션
`optimizer_switch` 시스템 변수값으로 설정  
여러 개의 옵션을 세트로 묶어서 설정하는 방식  

<br>

| 옵티마이저 스위치 이름 | 기본값 | 설명 |
|--|--|--|
| batched_key_access | off | BKA 조인 알고리즘을 사용할지 여부 설정 |
| block_nested_loop | on | Block Nested Loop 조인 알고리즘을 사용할지 여부 설정 |
| engine_condition_pushdown | on | Engine Condition Pushdown 기능을 사용할지 여부 설정 |
| index_condition_pushdown | on | Index Condition Pushdown 기능을 사용할지 여부 설정 |
| use_index_extensions | on | Index Extension 최적화를 사용할지 여부 설정 |
| index_merge | on | Index Merge 최적화를 사용할지 여부 설정 |
| index_merge_intersection | on | Index Merge Intersection 최적화를 사용할지 여부 설정 |
| index_merge_sort_union | on | Index Merge Sort Union 최적화를 사용할지 여부 설정 |
| index_merge_union | on | Index Merge Union 최적화를 사용할지 여부 설정 |
| mrr | on | MRR 최적화를 사용할지 여부 설정 |
| mrr_cost_based | on | 비용 기반의 MRR 최적화를 사용할지 여부 설정 |
| semijoin | on | 세미 조인 최적화를 사용할지 여부 설정 |
| firstmatch | on | FirstMatch 세미 조인 최적화를 사용할지 여부 설정 |
| loosescan | on | LooseScan 세미 조인 최적화를 사용할지 여부 설정 |
| materialization | on | Materialization 최적화를 사용할지 여부 설정 |
| subquery_materialization_cost_based | on | 비용 기반의 Materializaion 최적화를 사용할지 여부 설정 |

<br>

각각의 옵티마이저 스위치 옵션은 `default`, `on`, `off` 설정 가능  
옵티마이저 스위치 옵션은 글로벌과 세션별 모두 설정 가능  

```sql
## 전체적 옵티마이저 스위치 설정
SET GLOBAL optimizer_switch = 'index_merge=on, index_merge_union=on, ...';

## 현재 커넥션 옵티마이저 스위치만 설정
SET SESSION optimizer_switch = 'index_merge=on, index_merge_union=on, ...';

## 현재 쿼리 옵티마이저 스위치만 설정
SELECT /*+ SET_VAR(optimizer_switch='condition_fanout_filter=off') */ ...
```

<br>

### MRR과 배치 키 액세스(mrr & batched_key_access)
MRR(`Multi-Range Read`)는 DS-MMR(`Disk Sweep Multi-Range Read`)라고도 표현  
기본적인 조인 방식인 네스티드 루프 조인은 드라이빙 테이블의 레코드를 읽어서 드리븐 테이블의 일치 레코드를 찾아서 조인 수행  
조인 처리는 MySQL 엔진이 처리하고 실제 레코드 읽기는 스토리지 엔진이 처리하기 때문에 스토리지 엔진에서는 아무런 최적화 수행 불가  

이런 단점을 보완하기 위해 조인 대상 테이블 중 하나로부터 레코드를 읽어서 조인 버퍼에 버퍼링  
드라이빙 테이블 레코드를 읽어서 드리븐 테이블과 조인을 즉시 실행하지 않고 조인 시기 지연  
스토리지 엔진은 읽어야 할 레코드들을 데이터 페이지에 정렬된 순서로 접근해서 읽기를 최소화  
하지만 쿼리 특성에 따라 BKA 조인으로 인해 부가적인 정렬 작업이 발생해서 성능 감소  

<br>

### 블록 네스티드 루프 조인(block_nested_loop)
조인의 연결 조건이 되는 칼럼에 모두 인덱스가 있는 경우 사용되는 조인 방식  
마치 중첩 반복문을 사용하는 것처럼 동작해서 네스티드 루프 조인이라고 표현  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
           INNER JOIN salaries s ON s.emp_no = e.emp_no
             AND s.from_date <= NOW()
             AND s.to_date >= NOW()
         WHERE e.first_name = 'Amor';

+----+-------------+-------+------+--------------+------+-------------+
| id | select_type | table | type | key          | rows | Extra       |
+----+-------------+-------+------+--------------+------+-------------+
|  1 | SIMPLE      | e     | ref  | ix_firstname |    1 | NULL        |
|  1 | SIMPLE      | s     | ref  | PRIMARY      |   10 | Using where |
+----+-------------+-------+------+--------------+------+-------------+
```

<br>

네스티드 루프 조인과의 차이는 조인 버퍼가 사용되는지 여부와 드라이빙 테이블 및 드리븐 테이블 조인 순서  
`Block` 단어가 사용되면 조인용 별도 버퍼가 사용됐다는 것을 의미, `Using Join buffer` 메시지 표시  
드라이빙 테이블은 한번에 모두 읽지만, 드리븐 테이블은 여러번 읽음  
옵티마이저는 최대한 드리븐 테이블의 검색이 인덱스를 사용할 수 있도록 실행 계획을 수립  

어떠한 방식으로도 드리븐 테이블의 풀 테이블 스캔이나 인덱스 풀 스캔을 피할 수 없는 경우 드라이빙 테이블 레코드를 메모리에 캐시  
이후 드리븐 테이블과 메모리 캐시를 조인하는 형태로 처리, 이때 사용되는 메모리 캐시가 조인 버퍼  
`join_buffer_size` 시스템 변수값으로 크기 제한 가능  

<br>

```
mysql> EXPLAIN
         SELECT *
         FROM dept_emp de, employees e
         WHERE de.from_date > '1995-01-01' AND e.emp_no < 109004;

+----+-------------+-------+-------+-------------+---------------------------------------+
| id | select_type | table | type  | key         | Extra                                 |
+----+-------------+-------+-------+-------------+---------------------------------------+
|  1 | SIMPLE      | de    | range | ix_fromdate | Using index condition                 |
|  1 | SIMPLE      | e     | range | PRIMARY     | Using join buffer (block nested loop) |
+----+-------------+-------+-------+-------------+---------------------------------------+
```

<img width="600" alt="blocknestedjoin" src="https://github.com/user-attachments/assets/02285752-7ddd-4bb3-be74-c4135bb5e5ab" />

해당 쿼리는 조인 조건이 없고 조건절만 존재하기 때문에 카테시안 조인을 수행  
조인 버퍼를 이용해서 블록 네스티드 루프 조인을 수행  
네스티드 루프 조인은 정렬 순서가 드라이빙 테이블 순서에 의해 결정되지만, 조인 버퍼가 사용되는 경우 순서가 흐트러짐  

<br>

### 인덱스 컨디션 푸시다운(index_condition_pushdown)
5.6 버전부터 지원했지만 너무 비효율적이어서 개선  

<br>

```
-- // 인덱스 컨디션 푸시다운이 작동하지 않는 상황 설정
mysql> ALTER TABLE employees ADD INDEX ix_lastname_firstname (last_name, first_name);
mysql> SET optimizer_switch = 'index_condition_pushdown=off';

mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE last_name = 'Acton' AND first_name LIKE '%sal';

+----+-------------+-----------+------+-----------------------+---------+-------------+
| id | select_type | table     | type | key                   | key_len | Extra       |
+----+-------------+-----------+------+-----------------------+---------+-------------+
|  1 | SIMPLE      | employees | ref  | ix_lastname_firstname | 66      | Using where |
+----+-------------+-----------+------+-----------------------+---------+-------------+
```

<img width="550" alt="withoutindexconditionpushdown" src="https://github.com/user-attachments/assets/f560358d-5ef5-4ea8-be38-af78da528c53" />

해당 쿼리에서 이미 한번 읽은 `lastname_firstname` 인덱스의 `first_name` 칼럼을 읽는 것이 아닌 새롭게 테이블 조회  
인덱스를 비교하는 작업은 InnoDB 스토리지 엔진이 수행하지만 테이블 레코드 조건절은 MySQL 엔진이 수행  
인덱스를 범위 제한 조건으로 사용하지 못하는 경우 스토리지 엔진으로 인덱스 칼럼 조건이 전달되지 않음  

<br>

```
-- // 인덱스 컨디션 푸시다운이 작동하는 상황 설정
mysql> ALTER TABLE employees ADD INDEX ix_lastname_firstname (last_name, first_name);
mysql> SET optimizer_switch = 'index_condition_pushdown=on';

mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE last_name = 'Acton' AND first_name LIKE '%sal';

+----+-------------+-----------+------+-----------------------+---------+-----------------------+
| id | select_type | table     | type | key                   | key_len | Extra                 |
+----+-------------+-----------+------+-----------------------+---------+-----------------------+
|  1 | SIMPLE      | employees | ref  | ix_lastname_firstname | 66      | Using index condition |
+----+-------------+-----------+------+-----------------------+---------+-----------------------+
```

<img width="550" alt="withindexconditionpushdown" src="https://github.com/user-attachments/assets/bc98c353-7816-4eed-ba30-50f8cbb377bf" />

인덱스를 범위 제한 조건으로 사용하지 못해도 인덱스에 포함된 칼럼의 조건이 있다면 모두 스토리지 엔진으로 전달 가능  

<br>

### 인덱스 확장(use_index_extensions)
세컨더리 인덱스에 자동으로 추가된 프라이머리 키를 활용 가능 여부를 결정하는 옵션  

```sql
CREATE TABLE ept_emp (
  emp_no INT NOT NULL,
  dept_no CHAR(4) NOT NULL,
  from_date DATE NOT NULL,
  to_date DATE NOT NULL,
  PRIMARY KEY (dept_no, emp_no),
  KEY ix_fromdate (from_date)
) ENGINE=InnoDB;
```

해당 테이블의 프라이머리 키는 멀티 칼럼 인덱스이며 세컨더리 인덱스는 하나의 칼럼만 포함  
최종적으로 `ix_fromdate` 인덱스는 (`from_date`, `dept_no`, `emp_no`) 조합으로 인덱스를 생성한 것과 흡사  
옵티마이저가 세컨더리 인덱스의 마지막에 자동 추가되는 프라이머리 키를 제대로 인지  

<br>

```
mysql> EXPLAIN SELECT COUNT(*) FROM dept_emp WHERE from_date = '1987-07-25' AND dept_no = 'd001';
+----+-------------+----------+------+-------------+---------+--------------+
| id | select_type | table    | type | key         | key_len | ref          |
+----+-------------+----------+------+-------------+---------+--------------+
|  1 | SIMPLE      | dept_emp | ref  | ix_fromdate | 19      | const, const |
+----+-------------+----------+------+-------------+---------+--------------+

mysql> EXPLAIN SELECT COUNT(*) FROM dept_emp WHERE from_date = '1987-07-25'
+----+-------------+----------+------+-------------+---------+-------+
| id | select_type | table    | type | key         | key_len | ref   |
+----+-------------+----------+------+-------------+---------+-------+
|  1 | SIMPLE      | dept_emp | ref  | ix_fromdate | 3       | const |
+----+-------------+----------+------+-------------+---------+-------+

mysql> EXPLAIN SELECT * FROM dept_emp WHERE from_date = '1987-07-25' ORDER BY dept_no;
+----+-------------+----------+------+-------------+---------+-------+
| id | select_type | table    | type | key         | key_len | Extra |
+----+-------------+----------+------+-------------+---------+-------+
|  1 | SIMPLE      | dept_emp | ref  | ix_fromdate | 3       | NULL  |
+----+-------------+----------+------+-------------+---------+-------+
```

해당 실행 계획에서 `key_len` 칼럼의 값이 19byte 사용(`from_date` 칼럼(3byte)과 `dept_no` 칼럼(16byte))  
정렬 작업도 인덱스를 활용해서 처리되는 장점 존재  

<br>


### 인덱스 머지(index_merge)
인덱스를 이용해 쿼리를 실행하는 경우 옵티마이저는 테이블별로 하나의 인덱스만 사용하도록 실행 계획 수립  
인덱스 머지 실행 계획은 하나의 테이블에 2개 이상의 인덱스를 이용해 쿼리를 처리  
보통 한 테이블에 대한 조건이 여러개 있더라도 하나의 인덱스에 포함된 칼럼에 대한 조건만 인덱스를 검색해서 작업 범위를 줄이는 것이 효율적  
하지만 쿼리에 사용된 각 조건이 서로 다른 인덱스 사용 가능하고 그 조건을 만족하는 레코드 건수가 많을 것으로 예상되는 경우 선택  
- `index_merge_intersection`
- `index_merge_sort_union`
- `index_merge_union`

<br>

### 인덱스 머지 - 교집합(index_merge_intersection)

여러 개의 인덱스를 각각 검색해서 그 결과의 교집합만 반환하는 것  
칼럼의 조건 중 하나라도 효율적으로 처리 가능하지 않다고 판단해서 사용  
아래 쿼리는 세컨더리 인덱스가 이미 프라이머리 키를 보유하고 있기 때문에 해당 옵션 비활성화 추천  

```
mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE first_name = 'Georgi' AND emp_no BETWEEN 10000 AND 20000;

+-------------+-----------------------+---------+-----------------------------------------------------+
| type        | key                   | key_len | Extra                                               |
+-------------+-----------------------+---------+-----------------------------------------------------+
| index_merge | ix_firstname, PRIMARY | 62, 4   | Using intersect(ix_firstname, PRIMARY); Using where |
+-------------+-----------------------+---------+-----------------------------------------------------+

mysql> SELECT COUNT(*) FROM employees WHERE first_name = 'Georgi';
+----------+
| COUNT(*) |
+----------+
|      253 |
+----------+

mysql> SELECT COUNT(*) FROM employees WHERE emp_no BETWEEN 10000 AND 20000;
+----------+
| COUNT(*) |
+----------+
|    10000 |
+----------+

mysql> SELECT COUNT(*) FROM employees WHERE first_name = 'Georgi' AND emp_no BETWEEN 10000 AND 20000;
+----------+
| COUNT(*) |
+----------+
|       14 |
+----------+
```

<br>

### 인덱스 머지 - 합집합(index_merge_union)
조건절에 사용된 조건들이 각각 인덱스를 사용하고 `OR` 연산자로 연결된 경우 사용  

```
mysql> EXPLAIN
        SELECT * FROM employees
        WHERE first_name = 'Matt' OR hire_datae = '1987-03-31';

+-------------+---------------------------+---------+-----------------------------------------+
| type        | key                       | key_len | Extra                                   |
+-------------+---------------------------+---------+-----------------------------------------+
| index_merge | ix_firstname, ix_hiredate | 58, 3   | Using union(ix_firstname, ix_hiredate); |
+-------------+---------------------------+---------+-----------------------------------------+
```

<img width="500" alt="indexmergeunion" src="https://github.com/user-attachments/assets/7921175b-255a-4285-915b-de4c7e9a6040" />

각 인덱스 결과 레코드들은 이미 프라이머리 키로 정렬된 상태  
우선순위 큐를 이용해서 프라이머리 키 중복 필터링  
별도의 정렬 과정이 필요 없음  

<br>

### 인덱스 머지 - 정렬 후 합집합(index_merge_sort_union)
만약 인덱스 머지 작업을 하는 도중에 결과의 정렬이 필요한 경우 사용  
범위 조건인 경우 인덱스 결과 레코드가 프라이머리 키로 정렬되지 않은 상태  
중복 제거를 위해 강제로 정렬을 수행해야 하는 경우  

```
mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE first_name = 'Matt'
            OR hire_date BETWEEN '1987-03-01' AND '1987-03-31'

+-------------+---------------------------+---------+----------------------------------------------+
| type        | key                       | key_len | Extra                                        |
+-------------+---------------------------+---------+----------------------------------------------+
| index_merge | ix_firstname, ix_hiredate | 58, 3   | Using sort_union(ix_firstname, ix_hiredate); |
+-------------+---------------------------+---------+----------------------------------------------+
```

<br>

### 세미 조인(semijoin)
다른 테이블과 실제 조인을 수행하지 않고 단지 다른 테이블에서 조건 일치 레코드가 존재하는지 체크  
세미 조인 최적화가 도입되기 전에 실행 계획은 불필요한 데이터 읽기가 필요  

```
mysql> SET SESSION optimizer_switch = 'semijoin=off';
mysql> EXPLAIN
         SELECT *
         FROM employees e
         WHERE e.emp_no IN (SELECT de.emp_no FROM dept_emp de WHERE de.from_date = '1995-01-01');

+----+-------------+-------+------+-------------+--------+
| id | select_type | table | type | key         | rows   |
+----+-------------+-------+------+-------------+--------+
|  1 | PRIMARY     | e     | ALL  | NULL        | 300363 |
|  2 | SUBQUERY    | de    | ref  | ix_formdate |     57 |
+----+-------------+-------+------+-------------+--------+
```

<br>

`= (subquery)` 형태와 `IN (subquery)` 형태 최적화  
- 세미 조인 최적화
- IN-to_EXISTS 최적화
- MATERIALIZATION 최적화

`<> (subquery)` 형태와 `NOT IN (subquery)` 형태 최적화  
- IN-to-EXISTS 최적화
- MATERIALIZATION 최적화

<br>

서브쿼리 최적화 중에 가장 최근 도입된 세미 조인 최적화 종류
- Table Pull-out
- Duplicate Weed-out
- First Match
- Loose Scan
- Materialization

<br>

Table pull-out 전략은 사용 가능하다면 항상 좋은 성능을 내기 때문에 별도로 제어 불가  
First Match 전략과 Loose Scan 전략은 각각 `firstmatch`, `loosescan` 옵티마이저 옵션으로 제어  
Duplicate Weed-out 전략과 Materialization 전략은 `materialization` 옵티마이저 옵션으로 제어  

<br>

### 테이블 풀-아웃(Table Pull-out)
세미 조인의 서브쿼리에 사용된 테이블을 아우터 쿼리로 꺼낸 후에 쿼리를 조인 쿼리로 재작성  
이는 서브쿼리 최적화가 도입되기 전에 수동으로 쿼리를 튜닝하던 대표적인 방법  
별도로 실행 계획에 메시지가 표시되지 않고, 실행 계획에서 해당 테이블들의 `id 칼럼값`이 같은지 다른지 비교  
더 정확하게는 실행 계획 명령을 실행한 수 옵티마이저가 재작성(`Re-Write`) 쿼리를 보는 것  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
         WHERE e.emp_no IN (SELECT de.emp_no FROM dept_emp de WHERE de.dept_no = 'd009');

+----+-------------+-------+--------+---------+-------+-------------+
| id | select_type | table | type   | key     | rows  | Extra       | 
+----+-------------+-------+--------+---------+-------+-------------+
|  1 | SIMPLE      | de    | ref    | PRIMARY | 46012 | Using index |
|  1 | SIMPLE      | e     | eq_ref | PRIMARY |     1 | NULL        |
+----+-------------+-------+--------+---------+-------+-------------+

mysql> SHOW WARNINGS \G
*************************** 1. row ***************************
  Level: Note
   Code: 1003
Message: /* select#1 */ SELECT employees.e.emp_no AS emp_no,
                employees.e.birth_date AS birth_date,
                employees.e.first_name AS first_name,
                employees.e.last_name AS last_name,
                employees.e.gender AS gender,
                employees.e.hire_date AS hire_date
         FROM employees.dept_emp de
           JOIN employees.employees e
         WHERE ((employees.e.emp_no = employees.de.emp_no) AND (employees.de.dept_no = 'd009'));
```

<br>

- 세미 조인 서브쿼리에서만 사용 가능
- 서브쿼리 부분이 UNIQUE 인덱스나 프라이머리 키 룩업으로 결과가 1건인 경우에만 사용
- 해당 전략이 적용되더라도 기존 쿼리에서 가능했던 최적화 방법이 사용 불가능한 것은 아님
- 만약 서브쿼리 모든 테이블이 아우터 쿼리로 꺼낼수 있다면 서브쿼리 자체 제거

<br>

### 퍼스트 매치(firstmatch)
`IN(subquery)` 형태의 세미 조인을 `EXISTS(subquery)` 형태로 튜닝한 것과 비슷  
실행 계획에서 해당 테이블들의 `id 칼럼값`이 모두 동일, `FirstMatch` 메시지 표시  
드라이빙 테이블 레코드에 대해 드리븐 테이블에 일치하는 레코드 1건만 찾으면 더 이상 드리븐 테이블 검색하지 않음  

```
mysql> EXPLAIN
         SELECT *
         FROM employees e
         WHERE e.first_name = 'Matt'
           AND e.emp_no IN(SELECT t.emp_no FROM titles t WHERE t.from_date BETWEEN '1995-01-01' AND '1995-01-30');

+----+-------+------+--------------+------+-----------------------------------------+
| id | table | type | key          | rows | Extra                                   |
+----+-------+------+--------------+------+-----------------------------------------+
|  1 | e     | ref  | ix_firstname |  233 | NULL                                    |
|  1 | t     | ref  | PRIMARY      |    1 | Using where; Using Index; FirstMatch(e) |
+----+-------+------+--------------+------+-----------------------------------------+
```

<br>

<img width="650" alt="firstmatch" src="https://github.com/user-attachments/assets/838a2fb4-977c-4f14-ad83-94bab4167c33" />

5.5 버전에서 수행했던 IN-to-EXISTS 변환과 거의 비슷한 로직으로 수행  
- 가끔 여러 테이블 조인시 원래 쿼리에 없던 동등 조건을 추가하는 형태로 최적화 실행  
  기존 IN-to_EXISTS 최적화에서 이러한 동등 조건 전파(`Equality propagation`)가 서브쿼리 내에서만 가능  
  하지만 FirstMatch 최적화에서는 조인 형태로 처리되기 때문에 아우터 쿼리까지 전파 가능  

- FirstMatch 최적화는 서브쿼리의 모든 테이블에 대해 테이블 별로 수행 여부를 선택 가능  

- 서브쿼리에서 하나의 레코드만 검색하면 더이상 검색을 하지 않는 단축 실행 경로(`Short-cut path`) 사용  
  때문에 서브쿼리는 그 서브쿼리가 참조하는 모든 아우터 테이블이 먼저 조회된 후 실행  

- 실행 계획의 Extra 칼럼에 `FirstMAtch(table-n)` 메시지 표시

- 상관 서브쿼리(`Correlated subquery`)에서도 사용 가능  

- `GROUP BY` 절이나 집합 함수가 사용된 서브쿼리에 사용 불가능


<br>

### 루스 스캔(loosescan)
















