# 실행 계획

대부분의 DBMS는 많은 데이터를 안전하게 저장하고 빠르게 조회하는 것이 목적  
옵티마이저가 항상 최적의 실행 계획을 수립하지 못하기 때문에 사용자가 보완 가능하도록 `EXPLAIN` 명령 지원  

<br>

## 통계 정보
5.7 버전까지 테이블과 인덱스에 대한 개괄적인 정보를 가지고 실행 계획 수립  
8.0 버전부터 인덱싱되지 않은 칼럼들에 대해서도 데이터 분포도 수집하는 히스토그램 정보 도입  

<br>

### 테이블 및 인덱스 통계 정보
비용 기반 최적화에서 가장 중요한 것은 통계 정보  
MySQL 서버는 쿼리 실행 계획 수립할때 실제 테이블 데이터 일부를 분석해서 통계 정보 보완  

<br>

### MySQL 서버의 통계 정보
5.6 버전부터 InnoDB 스토리지 엔진을 사용하는 테이블 통계 정보는 영구적으로 관리 가능  
이전까지는 메모리에만 보관했기 때문에 재시작시 통계 정보 상실  

```
mysql> SHOW TABLES LIKE '%_stats';
+---------------------------+
| Tables_in_mysql (%_stats) |
+---------------------------+
| innodb_index_stats        |
| innodb_table_stats        |
+---------------------------+
```

<br>

테이블을 생성할 때 `STATS_PERSISTENT` 옵셜 설정 가능  
설정값에 따라 통계 정보를 영구적으로 관리할지 결정  
테이블 통계 정보를 조회할때 영구적 통계 정보만 조회 가능  

```
mysql> CREATE TABLE tab_persistent (fd1 INT, fd2 VARCHAR(20), PRIMARY KEY(fd1))
         ENGINE=InnoDB STATS_PERSISTENT=1;
mysql> CREATE TABLE tab_transient (fd1 INT, fd2 VARCHAR(20), PRIMARY KEY(fd1))
         ENGINE=InnoDB STATS_PERSISTENT=0;

mysql> SELECT * FROM mysql.innodb_table_stats
         WHERE table_name IN ('tab_persistent', 'tab_transient') \G
*************************** 1. row ***************************
           database_name: test
              table_name: tab_persistent
             last_update: 2013-12-28 17:11:30
                  n_rows: 0
    clustered_index_size: 1
sum_of_other_index_sizes: 0
```

<br>

테이블이 이미 생성된 이후에도 통계정보를 영구적 또는 단기적으로 변경 가능  

```
mysql> ALTER TABLE employees.employees STATS_PERSISTENT=1;
mysql> SELECT *
         FROM innodb_index_stats
         WHERE database_name = 'employees'
           AND TABLE_NAME = 'employees';
+--------------+--------------+------------+-------------+-----------------------------------+
| index_name   | stat_name    | stat_value | sample_size | stat_description                  |
+--------------+--------------+------------+-------------+-----------------------------------+
| PRIMARY      | n_diff_pfx01 |     299202 |          20 | emp_no                            |
| PRIMARY      | n_leaf_pages |        886 |        NULL | Number of leaf pages in the index |
| PRIMARY      | size         |        929 |        NULL | Number of pages in the index      |
| ix_firstname | n_diff_pfx01 |       1313 |          20 | first_name                        |
| ix_firstname | n_diff_pfx02 |     294090 |          20 | first_name, emp_no                |
| ix_firstname | n_leaf_pages |        309 |        NULL | Number of leaf pages in the index |
| ix_firstname | size         |        353 |        NULL | Number of pages in the index      |
| ix_hiredate  | n_diff_pfx01 |       5128 |          20 | hire_date                         |
| ix_hiredate  | n_diff_pfx02 |     300069 |          20 | hire_date, emp_no                 |
| ix_hiredate  | n_leaf_pages |        231 |        NULL | Number of leaf pages in the index |
| ix_hiredate  | size         |        289 |        NULL | Number of pages in the index      |
+--------------+--------------+------------+-------------+-----------------------------------+

mysql> SELECT *
         FROM innodb_table_stats
         WHERE database_name = 'employees'
           AND TABLE_NAME = 'employees';
+--------+----------------------+--------------------------+
| n_rows | clustered_index_size | sum_of_other_index_sizes |
+--------+----------------------+--------------------------+
| 299202 |                  929 |                      642 |
+--------+----------------------+--------------------------+
```

통계 정보의 각 칼럼은 아래와 같은 정보  
- `innodb_index_stats.stat_name = 'n_diff_pfx%'`: 인덱스가 가진 유니크한 값의 개수
- `innodb_index_stats.stat_name = 'n_leaf_pages'`: 인덱스의 리프 노드 페이지 개수
- `innodb_index_stats.stat_name = 'size'`: 인덱스 트리의 전체 페이지 개수
- `innodb_index_stats.n_rows`: 테이블 전체 레코드 건수
- `innodb_index_stats.clustered_index_size`: 프라이머리 키 크기
- `innodb_index_stats.sum_of_other_index_sizes`: 프라이머리 키를 제외한 인덱스 크기

<br>

또한 `innodb_stats_auto_recalc` 시스템 설정 변수 값을 OFF로 설정해서 통계 정보 자동 갱신 방지 가능  
기본값은 ON이므로 영구적인 통계 정보를 원한다면 변경 필수  
- `STATS_AUTO_RECALC=1`: 테이블 통계 정보를 5.5 이전 방식대로 자동 수집  
- `STATS_AUTO_RECALC=0`: 테이블 통계 정보는 `ANALYZE TABLE` 명령을 실행할 때만 수집  

<br>

테이블 통계 정보를 수집할 때 몇 개의 테이블 블록 샘플링할지 결정 가능
- `innodb_stats_transient_sample_pages`  
  기본값은 8  
  자동으로 통계 정보 수집이 실행될 때 8개 페이지만 임의로 샘플링해서 분석  

- `innodb_stats_persistent_sample_pages`  
  기본값은 20  
  `ANALYZE TABLE` 명령이 실행될 때 임의로 20개 페이지만 샘플링해서 분석  
  그 결과를 영구적인 통계 정보 테이블에 저장  

<br>

### 히스토그램
5.7 버전까지 통계 정보는 단순히 인덱스된 칼럼의 유니크한 값의 개수 정도  
이러한 부족함을 메우기 위해 실제 인덱스 일부 페이지를 랜덤으로 참조  
8.0 버전부터 칼럼의 데이터 분포도를 참조 가능한 히스토그램 정보 지원  

<br>

### 히스토그램 정보 수집 및 삭제
히스토그램 정보는 칼럼 단위로 관리  
자동으로 수집되지 않고 `ANALYZE TABLE ... UPDATE HISTOGRAM` 명령으로 수동 수집  
수집된 히스토그램 정보는 시스템 딕셔너리에 함께 저장  
서버 시작시 `information_schema` 데이터베이스의 `column_statistics` 테이블로 로드  

```
mysql> ANALYZE TABLE employees.employees
       UPDATE HISTOGRAM ON gender, hire_date;

mysql> SELECT *
       FROM COLUMN_STATISTICS
       WHERE SCHEMA_NAME = 'employees'
         AND TABLE_NAME = 'employees' \G
***************************** 1. row *****************************
SCHEMA_NAME: employees
 TABLE_NAME: employees
COLUMN_NAME: gender
  HOSTOGRAM: {"buckets": [
                           [1, 0.5998529796789721],
                           [2, 1.0]
                         ],
              "data-type": "enum",
              "null-values": 0.0,
              "collation-id": 45,
              "last-updated": "2020-08-03 03:47:45.739242",
              "sampling-rate": 0.3477368727939573,
              "histogram-type": "singleton",
              "number-of-buckets-specified": 100
             }
***************************** 2. row *****************************
SCHEMA_NAME: employees
 TABLE_NAME: employees
COLUMN_NAME: hire_date
  HOSTOGRAM: {"buckets": [["1985-02-01", "1985-02-28", 0.009838277646869273, 28],
                          ["1985-03-01", "1985-03-28", 0.020159909773830382, 28],
                          ...
                          ["1997-12-16", "1998-08-06", 0.9900006041931001, 233],
                          ["1998-08-07", "2000-01-06", 1.0, 420]
                         ]
              "data-type": "date",
              "null-value": 0.0,
              "collation-id": 8,
              "last-updated": "2020-08-03 03:47:45.742159",
              "sampling-rate": 0.3477368727939573,
              "histogram-type": "equi-height",
              "number-of-buckets-specified": 100
             }
2 rows in set (0.00 sec)
```

<br>

8.0 버전에서는 아래 2종류 히스토그램 타입 지원  
- 싱글톤(`Singleton`): 칼럼값 개별로 레코드 건수를 관리하는 히스토그램  
- 높이 군형(`Equi-Height`): 칼럼값의 범위를 균등한 개수로 구분해서 관리하는 히스토그램  

히스토그램은 버킷(`bucket`) 단위로 구분되어 레코드 건수나 칼럼값 범위 관리  
싱글톤 히스토그램은 각 버킷이 칼럼의 값과 발생 빈도율 등 2개 값으로 구성  
높이 균형 히스토그램은 각 버킷이 시작값과 마지막 값, 발생 빈도율과 유니크한 값의 개수 등 4개 값으로 구성  

<br>

`information_schema.solumn_statistics` 테이블의 `HISTOGRAM` 칼럼은 이외에도 여러 정보 보유  
- `sampling-rate`: 히스토그램 정보 수집을 위해 스캔한 페이지 비율
- `histogram-type`: 히스토그램의 종류
- `number-of-buckets-specified`: 히스토그램 생성시 설정했던 버킷의 개수, 최대 1024개 설정 가능, 보통 100개면 충분

<br>

생성된 히스토그램은 필요시 삭제 가능  
삭제 작업은 테이블 데이터를 참조하지 않고 딕셔너리 내용만 삭제하기 때문에 쿼리 처리 성능에 영향없음  

```sql
ANALYZE TABLE employees.employees
DROP HISTOGRAM ON gender, hire_date;
```

<br>

히스토그램을 삭제하지 않고 사용하지 않도록 설정 가능  
`optimizer_switch` 시스템 변수값으로 설정  
`condition_fanout_filter` 옵션에 의해 영향받는 다른 최적화 기능들이 사용되지 않을 가능성 존재  

```sql
SET GLOBAL optimizer_switch = 'condition_fanout_filter=off';
SET SESSION optimizer_switch = 'condition_fanout_filter=off';
SELECT /*+ SET_VAR(optimizer_switch = 'condition_fanout_filter=off') */ * FROM ...
```

<br>

### 히스토그램의 용도
히스토그램이 도입되기 이전에도 테이블과 인덱스에 대한 통계 정보는 존재  
테이블의 전체 레코드 건수와 인덱싱 칼럼의 유니크 값 개수 정도  
하지만 실제 응용 프로그램의 데이터는 항상 균등한 분포도를 가지지 않아서 히스토그램 도입  

```
-- // 일반 통계 실행 계획
mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE first_name = 'Zita'
           AND birth_date BETWEEN '1950-01-01' AND '1960-01-01';

+----+-------------+-----------+------+--------------+------+----------+
| id | select_type | table     | type | key          | rows | filtered |
+----+-------------+-----------+------+--------------+------+----------+
|  1 | SIMPLE      | employees | ref  | ix_firstname |  224 |    11.11 |
+----+-------------+-----------+------+--------------+------+----------+

-- // 히스토그램 실행 계획
mysql> ANALYZE TABLE employees UPDATE histogram ON first_name, birth_date;
mysql> EXPLAIN
         SELECT *
         FROM employees
         WHERE first_name = 'Zita'
           AND birth_date BETWEEN '1950-01-01' AND '1960-01-01';

+----+-------------+-----------+------+--------------+------+----------+
| id | select_type | table     | type | key          | rows | filtered |
+----+-------------+-----------+------+--------------+------+----------+
|  1 | SIMPLE      | employees | ref  | ix_firstname |  224 |    60.82 |
+----+-------------+-----------+------+--------------+------+----------+

-- // 실제 비율
mysql> SELECT
         SUM(CASE WHEN birth_date between '1950-01-01' and '1960-01-01' THEN 1 ELSE 0 END)
           / COUNT(*) as ratio
       FROM employees WHERE first_name = 'Zita';
+--------+
| ratio  |
+--------+
| 0.6384 |
+--------+
```

<br>

히스토그램 정보가 없으면 옵티마이저는 데이터가 균등하게 분포될 것으로 예상  
하지만 히스토그램이 존재하면 특정 범위의 데이터가 많고 적음을 식별 가능  

```
mysql> SELECT /*+ JOIN_ORDER(e, s) */ *
       FROM salaries s
         INNER JOIN employees e ON e.emp_no = s.emp_no
                    AND e.birth_date BETWEEN '1950-01-01' AND '1950-02-01'
       WHERE s.salary BETWEEN 40000 AND 70000;
Empty set (0.13 sec)

mysql> SELECT /*+ JOIN_ORDER(s, e) */ *
       FROM salaries s
         INNER JOIN employees e ON e.emp_no = s.emp_no
                    AND e.birth_date BETWEEN '1950-01-01' AND '1950-02-01'
       WHERE s.salary BETWEEN 40000 AND 70000;
Empty set (1.29 sec)
```

<br>

### 히스토그램과 인덱스
히스토그램과 인덱스는 완전히 다른 객체이기 때문에 비교 대상은 아니지만 공통점 존재  
인덱스 다이브(`Index Dive`)는 조건절에 일치하는 레코드 건수를 예측하기 위해 실제 인덱스 샘플링하는 동작   
8.0 버전부터 인덱싱된 칼럼을 검색 조건에 사용한 경우 히스토그램을 사용하지 않고 인덱스 다이브 실행  
하지만 인덱스 다이브는 어느 정도 비용 필요, 조만간 인덱스 다이브보다 히스토그램 활용 최적화 기능도 제공할 것으로 예상  

<br>

### 코스트 모델(Cost Model)
서버는 다양한 작업이 얼마나 필요한지 예측하고 전체 작업 비용을 계산  
쿼리 비용을 계산하는데 필요한 단위 작업들의 비용을 코스트 모델이라고 표현  
5.7 이전 버전까지 이러한 비용을 서버 소스 코드에 상수화해서 사용  
8.0 버전부터 코스트 모델을 DBMS 관리자가 조정 가능  
- `server_cost`: 인덱스를 찾고 레코드를 비교하고 임시 테이블 처리에 대한 비용 관리
- `engine_cost`: 레코드를 가진 데이터 페이지를 가져오는데 필요한 비용 관리

<br>

두 테이블은 공통으로 아래 5개의 칼럼을 보유  
- `cost_name`: 코스트 모델의 각 단위 작업
- `default_value`: 각 단위 작업의 비용(기본값이며 이 값은 서버 소스 코드 설정값)
- `cost_value`: DBMS 관리자가 설정한 값
- `last_update`: 단위 작업의 비용이 변경된 시점
- `comment`: 비용에 대한 추가 설명

<br>

`engine_cost` 테이블은 추가로 2개 칼럼 보유
- `engine_name`: 비용이 적용된 스토리지 엔진
- `device_type`: 디스크 타입

<br>

| | cost_name | default_value | 설명 |
|--|--|--|--|
| engine_cost | io_block_read_cost | 1.00 | 디스크 데이터 페이지 읽기 |
| | memory_block_read_cost | 0.25 | 메모리 데이터 페이지 읽기 |
| server_cost | disk_temptable_create_cost | 20.00 | 디스크 임시 테이블 생성 |
| | disk_temptable_row_cost | 0.50 | 디스크 임시 테이블의 레코드 읽기 |
| | key_compate_cost | 0.05 | 인덱스 키 비교 |
| | memory_temptable_create_cost | 1.00 | 메모리 임시 테이블 생성 |
| | memory_emptable_row_cost | 0.10 | 메모리 임시 테이블의 레코드 읽기 |
| | row_evaluate_cost | 0.10 | 레코드 비교 |

<br>

```
mysql> EXPLAIN FORMAT=TREE
         SELECT *
         FROM employees WHERE first_name = 'Matt' \G
*************************** 1. row ***************************
EXPLAIN: -> Index lookup on employees using ix_firstname (first_name='Matt')
              (cost=256.10 rows=233)

mysql> EXPLAIN FORMAT=JSON
         SELECT *
         FROm employees WHERE first_name = 'Matt' \G
*************************** 1. row ***************************
EXPLAIN: {
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "255.08"
    },
    "talbe": {
      ...
      "rows_examined_per_scan": 233,
      "rows_produced_per_join": 233,
      "filtered": "100.00",
      "cost_info": {
        "read_cost": "231.78",
        "eval_cost": "23.30",
        "prefix_cost": "255.08",
        "data_read_per_join": "49K"
      },
...
```

코스트 모델에서 중요한 것은 각 단위 작업에 설정되는 비용값이 커지면 어떤 실행 계획들에 영향을 받는지 파악하는 것  
- `key_compare_cost`: 가능하면 정렬을 수행하지 않는 실행 계획 수립
- `row_evaluate_cost`: 풀 스캠 실행 쿼리 비용 증가, 가능하면 인덱스 레인지 스캔 실행 계획 수립
- `disk_temptable_create_cost`, `distk_temptable_row_cost`: 디스크 임시 테이블을 만들지 않는 실행 계획 수립
- `memory_temptable-create_cost`, `memory_temptable_row_cost`: 메모리 임시 테이블을 만들지 않는 실행 계획 수립
- `io_block_read_cost`: 버퍼 풀에 데이터 페이지가 많이 적재된 인덱스를 사용하는 실행 계획 수립
- `memory_block_read_cost`: 버퍼 풀에 데이터 페이지가 상대적으로 적더라도 그 인덱스를 사용하는 실행 계획 수립

<br>

## 실행 계획 확인
서버 실행 계획은 `DESC` 또는 `EXPLAIN` 명령으로 확인 가능  
8.0 버전부터 `EXPLAIN` 명령에 사용 가능한 새로운 옵션 추가  

<br>

### 실행 계획 출력 포맷
이전 버전에선 `EXPLAIN EXTENDED` 또는 `EXPLAIN PARTITIONS` 명령이 구분  
8.0 버전부터 통합되어 해당 옵션은 문법에서 제거  

<br>

### 실행 계획 출력 포맷
`FORMAT` 옵션을 통해 실행 계획 표시 방법을 설정 가능  

```
-- // 테이블 포맷 표시
mysql> EXPLAIN
         SELECT *
         FROM employees e
           INNER JOIN salaries s ON s.emp_no = e.emp_no
         WHERE first_name = 'ABC';
+----+-------------+-------+------------+------+-----------------------+--------------+---------+--------------------+------+----------+-------+
| id | select_type | table | partitions | type | possible_keys         | key          | key_len | ref                | rows | filtered | Extra |
+----+-------------+-------+------------+------+-----------------------+--------------+---------+--------------------+------+----------+-------+
|  1 | SIMPLE      | e     | NULL       | ref  | PRIMARY, ix_firstname | ix_firstname | 58      | const              |    1 |   100.00 | NULL  |
|  1 | SIMPLE      | s     | NULL       | ref  | PRIMARY               | PRIMARY      | 4       | employees.e.emp_no |   10 |   100.00 | NULL  |
+----+-------------+-------+------------+------+-----------------------+--------------+---------+--------------------+------+----------+-------+

-- // 트리 포맷 표시
mysql> EXPLAIN FORMAT=TREE
         SELECT *
         FROM employees e
           INNER JOIN salaries s ON s.emp_no = e.emp_no
         WHERE first_name = 'ABC' \G
******************************* 1. row *******************************
EXPLAIN: -> Nested loop inner join  (cost=2.40 rows=10)
    -> Index lookup on e using ix_firstname (first_name='ABC')  (cost=0.35 rows=1)
    -> Index lookup on s using PRIMARY (emp_no=e.emp_no)  (cost=2.05 rows=10)

-- // JSON 포맷 표시
mysql> EXPLAIN FORMAT=JSON
         SELECT *
         FROM employees e
           INNER JOIN salaries s ON s.emp_no = e.emp_no
         WHERE first_name = 'ABC' \G
******************************* 1. row *******************************
EXPLAIN: {
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "2.40"
    },
    "neted_loop": [
      {
        "table": {
          "table_name": "e",
          "access_type": "ref",
          "possible_keys": [
            "PRIMARY",
            "ix_firstname"
          ],
          "key": "ix_firstname",
          "used_key_parts": [
            "first_name"
          ],
...
```

<br>

### 쿼리의 실행 시간 확인
8.0.18 버전부터 `EXPLAIN ANALYZE` 명령으로 쿼리 실행 계획과 단계별 소요 시간 정보 확인 가능  
`SHOW PROFILE` 명령으로 시간 소요가 많은 부분을 확인 가능하지만, 실행 계획 단계별 소요 시간 정보는 확인 불가  
`EXPLAIN ANALYZE` 명령은 항상 트리 포맷으로 결과 반환  

```
mysql> EXPLAIN ANALYZE
         SELECT e.emp_no, avg(s.salary)
         FROM employees e
           INNER JOIN salaries s ON s.emp_no = e.emp_no
                      AND s.salary > 50000
                      AND s.from_date <= '1990-01-01'
                      AND s.to_date > '1990-01-01'
         WHERE e.first_name = 'Matt'
         GROUP BY e.hire_date \G

A) -> Table scan on <temporary>  (actual time=0.001..0.004 rows=48 loops=1)
B)     -> Aggregate using temporary table  (actual time=3.799..3.808 rows=48 loops=1)
C)        -> Nested loop inner join  (cost=685.24 rows=135)
                        (actual time=0.367..3.602 rows=48 loops=1)
D)            -> Index lookup on e using ix_firstname (first_name='Matt') (cost=215.08 rows=233)
                        (actual time=0.348..1.046 rows=233 loops=1)
E)            -> Filter: ((s.salary > 50000) and (s.from_data <= DATE'1990-01-01')
                                     and (s.to_date > DATE'1990-01-01')) (cost=0.98 rows=1)
                        (actual time=0.009..0.011 rows=0 loops=233)
F)               -> Index lookup on s using PRIMARY (emp_no=e.emp_no) (cost=0.98 rows=10)
                        (actual time=0.007..0.009 rows=10 loops=233)
```

- 들여쓰기가 같은 레벨에서는 상단에 위치한 라인이 먼저 실행  
- 들여쓰기가 다른 레벨에서는 가장 안쪽에 위치한 라인이 먼저 실행  
- `actual time`: 실제 테이블에서 읽은 칼럼 값을 기준으로 레코드 검색하는데 걸린 첫번째/마지막 평균 시간  
- `rows`: 테이블에서 읽은 평균 레코드 건수  
- `loops`: 테이블에서 레코드 탐색 작업이 반복된 횟수  

<br>

`EXPLAIN ANALYZE` 명령은 `EXPLAIN` 명령과 달리 실행 계획만 추출하지 않고 실제 쿼리를 실행  
실행 계획이 아주 나쁜 경우 `EXPLAIN` 명령으로 먼저 튜닝후 사용하는 것 권장  

<br>

## 실행 계획 분석
실행 계획 표의 각 라인은 쿼리 문장에서 사용된 테이블의 개수만큼 출력  
실행 순서는 위에서 아래로 순서대로 표시(유니온이나 상관 서브쿼리는 예외)  
위쪽에 출력된 결과일수록 쿼리의 바깥 부분이거나 먼저 접근한 테이블  

<br>

### id 칼럼
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

### selecct_type 칼럼
각 단위 SELECT 쿼리가 어떤 타입의 쿼리인지 표시  

























