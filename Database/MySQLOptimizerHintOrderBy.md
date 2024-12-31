# 옵티마이저와 힌트
MySQL 서버로 요청된 쿼리 결과가 동일해도 내부적으로 처리 과정은 매우 다양  
쿼리를 최적으로 실행하기 위해 각 테이블의 데이터가 어떤 분포로 저장돼 있는지 통계 정보를 참조  
이런 기본 데이터를 비교해 최적 실행 계획을 수립하는 작업 필수  

<br>

## ORDER BY 처리(Using filesort)
레코드 1 ~ 2건을 가져오는 쿼리를 제외하면 대부분의 조회 쿼리에서 정렬을 필수로 사용  
대부분의 조회 쿼리에 레코드 정렬 요건이 포함  

|  | 장점 | 단점 |
|--|--|--|
| 인덱스 | 변경 쿼리가 실행될 때 이미 인덱스 정렬 | 변경 작업 시 부가적인 인덱스 추가/삭제 작업 필요 <br> 인덱스로 인한 디스크 공간 필요 |
| Filesort | 인덱스를 생성하지 않아서 인덱스의 단점이 장점으로 적용 <br> 정렬해야 할 레코드가 적은 경우 충분히 빠름 | 정렬 작업이 쿼리 실행시 처리 <br> 레코드 대상 건수가 많아질수록 쿼리 성능 낮음 |

<br>

인덱스를 사용하지 않고 별도의 정렬 처리 수행 여부는 실행 계획의 `Extra` 칼럼에 `Using  filesort` 메시지로 판단 가능  
아래 조건의 경우에 `Filesort` 정렬 작업 수행  
- 정렬 기준이 너무 많아서 요건별로 모두 인덱스 생성이 불가한 경우  
- `GROUP BY` 결과 또는 `DISTINCT` 처리 결과를 정렬해야하는 경우  
- `UNION` 결과와 같이 임시 테이블의 결과를 다시 정렬하는 경우  
- 랜덤하게 결과 레코드를 가져오는 경우  

<br>

### 소트 버퍼
정렬을 수행하기 위해 별도의 메모리 공간을 할당받아서 사용  
해당 메모리 공간을 소트 버퍼(`Sort Buffer`)라고 표현  
소트 버퍼는 정렬이 필요한 경우에만 할당되며 최대 사용 가능한 공간은 `sort_buffer_size` 시스템 변수값으로 설정  
소트 버퍼를 위한 메모리 공간은 쿼리 실행 완료 시점에 바로 반납  
소트 버퍼 크기는 `56KB ~ 1MB` 적정  
이 값을 너무 높게 설정할 경우 운영체제 `OOM-Kilter`의 강제 종료 1순위로 MySQL 서버 확정  

<br>

만약 정렬해야할 레코드가 소트 버퍼 최대 크기보다 큰 경우 해당 레코드를 여러 조각으로 나눠서 처리  
이 과정에서 임시 저장을 위해 디스크를 사용  
메모리의 소트 버퍼에서 정렬을 수행하고, 그 결과를 임시로 디스크에 기록하며 해당 과정 반복  
이 병합 작업을 멀티 머지(`Multi-merge`)라고 표현, 수행된 멀티 머지 횟수는 `Sort_merge_passes` 상태 변수에 누적 집계  

<br>

### 정렬 알고리즘
레코드를 정렬할 때 소트 버퍼에 레코드 전체를 담는 방법과 정렬 기준 칼럼만 담는 두가지 방법 존재  
싱글 패스(`Single-pass`)와 투 패스(`Two-pass`) 2가지 정렬 모드  

```
-- // 옵티마이저 트레이스 활성화
mysql> SET OPTIMIZER_TRACE = "enabled=on", END_MARKERS_IN_JSON = on;
mysql> SET OPTIMIZER_TRACE_MAX_MEM_SIZE = 1000000;

-- // 쿼리 실행
mysql> SELECT * FROM employees ORDER BY last_name LIMIT 100000, 1;

mysql> SELECT * FROM INFORMATION_SCHEMA.OPTIMITZER_TRACE \G
...
           "filesort_priority_queue_optimization": {
             "limit": 100001
           }
           "filesort_execution": [
           ]
           "filesort_summary": {
             "memory_available": 262144,
             "key_size": 32,
             "row_size": 169,
             "max_orws_per_buffer": 1551,
             "num_rows_estimate": 936530,
             "num_rows_found": 300024,
             "num_initial_chunks_spilled_to_disk": 82,
             "peak_memory_used": 262144,
             "sort_algorithm": "std::stable_sort",
             "sort_mode": "<fixed_sort_key, packed_additional_fields>"
           }
...
```

`filesort-summary` 섹션의 `sort_algorithm` 필드에 정렬 알고리즘 표시  
`sort_mode` 필드에 정렬 방식 표시  

- `<sort_key, rowid>`: 정렬 키와 레코드의 로우 아이디만 가져와서 정렬(투 패스)  
- `<sort_key, additional_fields>`: 정렬 키와 레코드 전체를 가져와서 정렬, 레코드 칼럼들은 고정 사이즈로 메모리 저장(싱글 패스)  
- `<sort_key, packed_additional_fields>`: 정렬 키와 레코드 전체를 가져와서 정렬, 레코드 칼럼들은 가변 사이즈로 메모리 저장(싱글 패스)  

<br>

### 싱글 패스 정렬 방식
소트 버퍼에 정렬 기준 칼럼을 포함해 대상 칼럼 전부를 담아서 정렬을 수행하는 방식  

```sql
SELECT emp_no, first_name, last_name FROM employees ORDER BY first_name;
```

<br>

<img width="600" alt="singlepass" src="https://github.com/user-attachments/assets/42ac2d16-8275-4b94-a8f2-91065683af7b" />

정렬에 필요하지 않은 칼럼까지 전부 읽어서 소트 버퍼에 담고 정렬 수행  

<br>

### 투 패스 정렬 방식
정렬 대상 칼럼과 프라이머리 키 값만 소트 버퍼에 담아서 정렬을 수행하는 방식  
정렬된 순서대로 다시 프라이머리 키로 테이블을 조회  
싱글 패스 도입 이전부터 사용하던 방식, 8.0 버전에서도 특정 조건에서는 사용  
- 레코드 크기가 `max_length_for_sort_data` 시스템 변수값보다 큰 경우
- BLOB이나 TEXT 타입의 칼럼이 조회 대상에 포함된 경우

<br>

<img width="600" alt="twopass" src="https://github.com/user-attachments/assets/09299bda-2494-4989-aad8-be8dd3cc2d2a" />

투 패스 방식은 테이블을 두번 읽어야 하기 때문에 비효율  
하지만 싱글 패스 방식은 더 많은 소트 버퍼 공간 필수  

<br>

### 정렬 처리 방법
쿼리에 `ORDER BY` 사용시 반드시 아래 방식 중 하나로 처리

| 정렬 처리 방법 | 실행 계획의 Extra 칼럼 내용 |
|--|--|
| 인덱스를 사용한 정렬 | 별도 표기 없음 |
| 조인에서 드라이빙 테이블만 정렬 | "Using filesort" 메시지 표시 |
| 조인에서 조인 결과를 임시 테이블로 저장 후 정렬 | "Using temporary; Using filesort" 메시지 표시 |

<br>

우선 옵티마이저는 인덱스 가능 여부를 검토  
가능하다면 별도의 Filesort 과정 없이 인덱스를 순서대로 읽어서 결과 반환  
가능하지 않다면 조건절에 일치하는 레코드를 검색해 소트 버퍼에 저장하면서 Filesort 수행  
일반적으로 조인이 수행된 후 레코드 건수와 크기가 거의 배수로 늘어나기 때문에 드라이빙 테이블만 정렬한 다음 조인을 수행하는 것이 효율적  

<br>

### 인덱스를 이용한 정렬
인덱스를 이용한 정렬은 반드시 `ORDER BY`에 명시된 칼럼이 제일 먼저 읽는 테이블(조인이 사용된 경우 드라이블 테이블)  
만약 조건절에 첫번째로 읽는 테이블의 칼럼에 대한 조건이 있다면 그 조건도 같은 인덱스를 사용 가능해야함  
해시 인덱스나 전문 검색 인덱스 같이 B-Tree 계열 인덱스가 아닌 경우 사용 불가  
예외적으로 R-Tree 인덱스는 B-Tree 계열 인덱스지만 사용 불가  
여러 테이블이 조인되는 경우 네스티드-루프(`Nested-loop`) 방식의 조인에서만 사용 가능  

<br>

인덱스를 이용해 정렬하는 경우 `ORDER BY`가 없어도 정렬이 가능  
하지만 일부러 제거하는 것은 권장하지 않음  

```sql
SELECT *
FROM employees e, salaries s
WHERE s.emp_no = e.emp_no
  AND e.emp_no BETWEEN 100002 AND 100020
ORDER BY e.emp_no;

SELECT *
FROM employees e, salaries s
WHERE s.emp_no = e.emp_no
  AND e.emp_no BETWEEN 100002 AND 100020;
```

<br>

<img width="550" alt="sortbyindex" src="https://github.com/user-attachments/assets/cc38bf83-3bdf-44d4-9529-a28e02275c8f" />

인덱스를 사용한 정렬이 가능한 이유는 B-Tree 인덱스가 이미 정렬된 상태  
또한 조인이 네스티드-루프 방식으로 실행되기 때문에 드라이빙 테이블의 인덱스 읽기 순서가 흐트러지지 않음  

<br>

### 조인의 드라이빙 테이블만 정렬
조인이 수행되면 결과 레코드의 건수가 배수로 늘어나고 각각의 레코드 크기도 증가  
조인을 실행하기 전에 첫 번째 테이블의 레코드를 먼저 정렬한 다음 조인을 실행하는 것이 차선책  

<br>

```sql
SELECT *
FROM employees e, salaries s
WHERE s.emp_no = e.emp_no
  AND e.emp_no BETWEEN 100002 AND 100020
ORDER BY e.last_name;
```

아래 조건에 의해 옵티마이저는 employees 테이블을 드라이빙 테이블로 선택  
- 조건절의 검색 조건은 employees 프라이머리 키를 이용해 검색하면 작업량 감소  
- 드리븐 테이블인 salaries 테이블의 조인 칼럼인 emp_no 칼럼에 인덱스 존재  

<br>

<img width="500" alt="sortbydrivingtable" src="https://github.com/user-attachments/assets/66a26be2-8509-4311-b9e6-4816f90f4269" />

검색은 인덱스 레인지 스캔으로 처리 가능하지만 `ORDER BY` 절에 명시된 칼럼이 프라이머리 키와 연관이 없어서 인덱스 정렬 불가  
하지만 정렬 기준 칼럼이 드라이빙 테이블에 포함된 칼럼  
옵티마이저는 드라이빙 테이블만 검색해서 정렬을 먼저 수행한 후 그 결과와 salaries 테이블을 조인  

<br>

### 임시 테이블을 이용한 정렬
하나의 테이블이라면 필요하지 않지만 2개 이상의 테이블을 조인해서 정렬하는 경우 임시 테이블이 필요할 가능성 존재  
정렬 방법 중에 가장 느리고 정렬해야 할 레코드 건수가 가장 많음  

```
mysql> EXPLAIN
       SELECT *
       FROM employees e, salaries s
       WHERE s.emp_no = e.emp_no
         AND e.emp_no BETWEEN 100002 AND 100020
       ORDER BY s.salary;

+----+-------+-------+---------+----------------------------------------------+
| id | table | type  | key     | Extra                                        |
+----+-------+-------+---------+----------------------------------------------+
|  1 | e     | range | PRIMARY | Using where; Using temporary; Using filesort |
|  1 | s     | ref   | PRIMARY | NULL                                         |
+----+-------+-------+---------+----------------------------------------------+
```

<br>

<img width="450" alt="sortbytemporarytable" src="https://github.com/user-attachments/assets/79316137-608d-432a-9b8c-6f317247ab20" />

해당 쿼리는 정렬 기준 칼럼이 드라이빙 테이블이 아닌 드리븐 테이블의 칼럼이기 때문에 임시 테이블 필수  
조인의 결과를 임시 테이블에 저장하고 그 결과를 다시 정렬 처리  

<br>

### 스트리밍 방식
서버 쪽에서 처리할 데이터가 얼마인지에 관계없이 조건에 일치하는 레코드가 검색될 때마다 바로 클라이언트에 전송하는 방식  
쿼리가 스트리밍(`Streaming`) 방식으로 처리된다면 얼마나 많은 레코드를 조회하는지에 관계없이 빠른 응답 시간 보장  
`LIMIT` 절처럼 결과 건수를 제한하는 조건들은 쿼리 전체 실행 시간 감소  
인덱스를 사용한 정렬 방식만 스트리밍 형태로 처리  

<br>

### 버퍼링 방식
`ORDER BY` 또는 `GROUP BY` 절과 같은 처리는 쿼리 결과가 스트리밍되는 것이 불가능  
조건에 일치하는 모든 레코드를 조회한 후 정렬하거나 그루핑해서 차례대로 보내야 하기 때문  
서버에서 모든 레코드를 검색하고 정렬 작업하는 동안 클라이언트는 작업이 버퍼링(`Buffering`)  

<br>

### 정렬 처리 방법의 성능 비교
조인과 함께 `ORDER BY` 절과 `LIMIT` 절이 사용될 경우 성능 차이 발생  
- `tb_test1` 테이블 레코드 100건
- `tb_test2` 테이블 레코드 1000건
- `tb_test1` 테이블 레코드 1건 당 `tb_test2` 테이블 레코드 10건 존재

```sql
SELECT *
FROM tb_test1 t1, tb_test2 t2
WHERE t1.col1 = t2.col1
ORDER BY t1.col2
LIMIT 10;
```

<Br>

1. `tb_test1` 테이블 드라이빙  

| 정렬 방법 | 읽어야 할 건수 | 조인 횟수 | 정렬해야 할 대상 건수 |
|--|--|--|--|
| 인덱스 사용 | tb_test1: 1건 <br> tb_test2: 10건 | 1번 | 0건 |
| 조인의 드라이빙 테이블만 정렬 | tb_test1: 100건 <br> tb_test2: 10건 | 1번 | 100건(tb_test1 레코드 건수만큼 정렬) |
| 임시 테이블 사용 후 정렬 | tb_test1: 100건 <br> tb_test2: 1000건 | 100건(tb_test1 레코드 건수만큼 정렬) | 1000건(조인된 결과 레코드 건수 전부 정렬) |

<br>

2. `tb_test2` 테이블 드라이빙  

| 정렬 방법 | 읽어야 할 건수 | 조인 횟수 | 정렬해야 할 대상 건수 |
|--|--|--|--|
| 인덱스 사용 | tb_test2: 10건 <br> tb_test1: 10건 | 10번 | 0건 |
| 조인의 드라이빙 테이블만 정렬 | tb_test2: 1000건 <br> tb_test1: 10건 | 10번 | 1000건(tb_test2 레코드 건수만큼 정렬) |
| 임시 테이블 사용 후 정렬 | tb_test2: 1000건 <br> tb_test1: 100건 | 1000건(tb_test2 레코드 건수만큼 정렬) | 1000건(조인된 결과 레코드 건수 전부 정렬) |

<br>

조인시 테이블 드라이빙도 중요하지만 어떤 정렬 방식으로 처리되는지가 더 큰 성능 차이 발생  
가능하다면 인덱스 정렬을 유도하고, 불가하다면 최소한 드라이빙 테이블만 정렬해도 되는 수준으로 유도  

<br>

### 정렬 관련 상태 변수
MySQL 서버는 처리하는 주요 작업에 대해서 해당 작업의 실행 횟수를 상태 변수로 저장  
- `Sort_merge_passes`: 멀티 머지 처리 횟수
- `Sort_range`: 인덱스 레인지 스캔을 통해 검색된 결과에 대한 정렬 작업 횟수
- `Sort_rows`: 지금까지 정렬한 전체 레코드 건수
- `Sort_scan`: 풀 테이블 스캔을 통해 검색된 결과에 대한 정렬 작업 횟수

```
mysql> FLUSH STATUS;
mysql> SHOW STATUS LIKE 'Sort%';

+-------------------+--------+
| Variable_name     | Value  |
+-------------------+--------+
| Sort_merge_passes | 13     |
| Sort_range        | 0      |
| Sort_rows         | 300024 |
| Sort_scan         | 1      |
+-------------------+--------+
```

<br>
